// Chat entre caficultor y comprador (con traducción automática) y cotizaciones 1 a 1.
const express = require('express');

const { pool, one, many } = require('../db');
const { requireAuth } = require('../auth');
const { translate } = require('../translate');
const S = require('../serialize');
const C = require('../services/conversations');
const { createAgreement } = require('../services/agreements');
const { notify, usd } = require('../services/notifications');
const { h, bad, notFound, num, str, otherLang, tx } = require('../lib/http');

const r = express.Router();

r.get('/conversations', requireAuth, h(async (req, res) => {
  const rows = await many(
    'SELECT * FROM conversations WHERE farmer_id = $1 OR buyer_id = $1 ORDER BY updated_at DESC LIMIT 100', [req.user.id],
  );
  res.json(await Promise.all(rows.map((c) => C.convSummary(c, req.user))));
}));

r.get('/unread', requireAuth, h(async (req, res) => {
  const row = await one(
    `SELECT COUNT(*)::int AS n FROM messages m JOIN conversations c ON c.id = m.conversation_id
      WHERE (c.farmer_id = $1 AND m.id > c.farmer_last_read OR c.buyer_id = $1 AND m.id > c.buyer_last_read)
        AND (m.sender_id IS NULL OR m.sender_id <> $1)`,
    [req.user.id],
  );
  const n = await one('SELECT COUNT(*)::int AS n FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  res.json({ unread: row.n, notifications: n.n });
}));

r.post('/conversations', requireAuth, h(async (req, res) => {
  const other = await one('SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL', [num(req.body.userId, -1)]);
  if (!other) throw notFound('Usuario no encontrado');
  if (other.role === req.user.role) throw bad('Solo se puede chatear entre caficultor y comprador');
  const farmerId = req.user.role === 'farmer' ? req.user.id : other.id;
  const buyerId = req.user.role === 'buyer' ? req.user.id : other.id;
  const lotId = req.body.lotId ? num(req.body.lotId) : null;
  const c = await C.ensureConversation(pool, farmerId, buyerId, lotId);
  res.status(201).json(await C.convSummary(c, req.user));
}));

r.get('/conversations/:id', requireAuth, h(async (req, res) => {
  res.json(await C.convSummary(await C.myConv(req, req.params.id), req.user));
}));

r.get('/conversations/:id/messages', requireAuth, h(async (req, res) => {
  const c = await C.myConv(req, req.params.id);
  const after = num(req.query.after, 0);
  const rows = await many(
    'SELECT * FROM messages WHERE conversation_id = $1 AND id > $2 ORDER BY id ASC LIMIT 300', [c.id, after],
  );
  res.json(rows.map((m) => S.message(m, c)));
}));

r.post('/conversations/:id/messages', requireAuth, h(async (req, res) => {
  const c = await C.myConv(req, req.params.id);
  const b = req.body;
  const type = b.type === 'photo' ? 'photo' : 'text';
  const text = str(b.text, 4000);
  if (type === 'text' && !text) throw bad('Mensaje vacío');
  if (type === 'photo' && !b.photoId) throw bad('Falta la foto');
  const lang = ['es', 'en'].includes(b.lang) ? b.lang : req.user.lang;
  const otherId = c.farmer_id === req.user.id ? c.buyer_id : c.farmer_id;
  const other = await one('SELECT lang FROM users WHERE id = $1', [otherId]);
  // Siempre se traduce al otro idioma de la app (ES ⇄ EN), así ambos ven las dos versiones.
  const target = other && other.lang !== lang ? other.lang : otherLang(lang);
  const translation = text ? await translate(text, lang, target) : null;
  const m = await C.insertMessage(pool, c, {
    sender_id: req.user.id,
    type,
    text: text || null,
    lang,
    translation,
    translated_to: translation ? target : null,
    via_voice: !!b.viaVoice,
    photo_id: type === 'photo' ? num(b.photoId) : null,
  });
  // quien envía ya leyó hasta aquí
  await C.markRead(c, req.user.id, m.id);
  res.status(201).json(S.message(m, c));
}));

r.post('/conversations/:id/read', requireAuth, h(async (req, res) => {
  const c = await C.myConv(req, req.params.id);
  const last = await one('SELECT COALESCE(MAX(id),0)::int AS id FROM messages WHERE conversation_id = $1', [c.id]);
  await C.markRead(c, req.user.id, num(req.body.lastId, last.id) || last.id);
  res.json({ ok: true });
}));

// ── Cotizaciones (negociación 1 a 1 dentro del chat) ──────────────
const otherIdOf = (c, me) => (c.farmer_id === me.id ? c.buyer_id : c.farmer_id);

r.post('/conversations/:id/quotes', requireAuth, h(async (req, res) => {
  const c = await C.myConv(req, req.params.id);
  const b = req.body;
  const lot = await one('SELECT * FROM lots WHERE id = $1 AND farmer_id = $2', [num(b.lotId, -1), c.farmer_id]);
  if (!lot) throw bad('El lote no pertenece a esta finca');
  const sacks = Math.round(num(b.sacks));
  const priceLb = num(b.priceLb);
  if (sacks < 1 || sacks > lot.sacks) throw bad(`Cantidad inválida (disponible: ${lot.sacks} sacos)`);
  if (priceLb <= 0) throw bad('Precio inválido');
  const role = req.user.role;
  const m = await tx(pool, async (client) => {
    // una cotización nueva reemplaza a las que sigan abiertas
    await client.query(
      `UPDATE messages SET quote = jsonb_set(quote, '{status}', '"superseded"')
        WHERE conversation_id = $1 AND type = 'quote' AND quote->>'status' IN ('open','accepted')`,
      [c.id],
    );
    const quote = {
      lotId: lot.id, lotName: lot.name, variety: lot.variety, process: lot.process,
      priceLb, sacks, incoterm: str(b.incoterm, 60) || 'FOB Buenaventura',
      history: [{ by: role, priceLb, sacks, at: Date.now() }],
      lastBy: role, status: 'open', acceptedBy: null, agreementId: null,
    };
    const msg = await C.insertMessage(client, c, { sender_id: req.user.id, type: 'quote', quote });
    await client.query('UPDATE conversations SET lot_id = $2 WHERE id = $1', [c.id, lot.id]);
    return msg;
  });
  await C.markRead(c, req.user.id, m.id);
  await notify(otherIdOf(c, req.user), 'quote_new', {
    es: [`🧾 Cotización de ${req.user.name}`, `${usd(priceLb)}/lb · ${sacks} sacos de «${lot.name}»`],
    en: [`🧾 Quote from ${req.user.name}`, `${usd(priceLb)}/lb · ${sacks} bags of “${lot.name}”`],
  }, { conversationId: c.id });
  res.status(201).json(S.message(m, c));
}));

/**
 * Responde una cotización.
 * action: 'counter' (contraoferta) | 'accept' (acepta la última oferta) | 'confirm' (segunda confirmación → acuerdo)
 */
r.post('/messages/:id/quote', requireAuth, h(async (req, res) => {
  const action = req.body.action;
  if (!['counter', 'accept', 'confirm'].includes(action)) throw bad('Acción inválida');
  let conv;
  let agreement = null;
  const out = await tx(pool, async (client) => {
    const qm = (await client.query('SELECT * FROM messages WHERE id = $1 FOR UPDATE', [num(req.params.id, -1)])).rows[0];
    if (!qm || qm.type !== 'quote') throw notFound('Cotización no encontrada');
    const c = await C.myConv(req, qm.conversation_id);
    conv = c;
    const role = req.user.role;
    const qt = qm.quote;
    const msgs = [];

    if (action === 'counter') {
      if (qt.status !== 'open' || qt.lastBy === role) throw bad('No puedes contraofertar esta cotización');
      const priceLb = num(req.body.priceLb);
      const sacks = Math.round(num(req.body.sacks, qt.sacks));
      if (priceLb <= 0 || sacks < 1) throw bad('Precio o cantidad inválidos');
      await client.query(`UPDATE messages SET quote = jsonb_set(quote, '{status}', '"superseded"') WHERE id = $1`, [qm.id]);
      const quote = {
        ...qt, priceLb, sacks,
        history: [...qt.history, { by: role, priceLb, sacks, at: Date.now() }],
        lastBy: role, status: 'open', acceptedBy: null,
      };
      msgs.push(await C.insertMessage(client, c, { sender_id: req.user.id, type: 'quote', quote }));
    } else if (action === 'accept') {
      if (qt.status !== 'open' || qt.lastBy === role) throw bad('No puedes aceptar esta cotización');
      await client.query(
        `UPDATE messages SET quote = quote || jsonb_build_object('status','accepted','acceptedBy',$2::text) WHERE id = $1`,
        [qm.id, role],
      );
      const f = role === 'farmer';
      msgs.push(await C.insertMessage(client, c, {
        type: 'system',
        sys_es: `${f ? 'El caficultor' : 'El comprador'} aceptó ${usd(qt.priceLb)}/lb · falta la confirmación ${f ? 'del comprador' : 'del caficultor'}`,
        sys_en: `${f ? 'The farmer' : 'The buyer'} accepted ${usd(qt.priceLb)}/lb · waiting for ${f ? 'the buyer' : 'the farmer'} to confirm`,
      }));
    } else {
      if (qt.status !== 'accepted' || qt.acceptedBy === role) throw bad('Esta cotización no está lista para confirmar');
      const made = await createAgreement(client, {
        conv: c, lotId: qt.lotId, lotName: qt.lotName, variety: qt.variety, process: qt.process,
        priceLb: qt.priceLb, sacks: qt.sacks, incoterm: qt.incoterm, firstAt: qt.history[0]?.at,
      });
      agreement = made.agreement;
      await client.query(
        `UPDATE messages SET quote = quote || jsonb_build_object('status','agreed','agreementId',$2::int) WHERE id = $1`,
        [qm.id, agreement.id],
      );
      msgs.push(made.message);
    }
    return { msgs, qt };
  });
  for (const m of out.msgs) await C.markRead(conv, req.user.id, m.id);

  const to = otherIdOf(conv, req.user);
  const qt = out.qt;
  if (action === 'counter') {
    const p = num(req.body.priceLb);
    await notify(to, 'quote_counter', {
      es: [`↔️ Contraoferta de ${req.user.name}`, `${usd(p)}/lb por «${qt.lotName}»`],
      en: [`↔️ Counteroffer from ${req.user.name}`, `${usd(p)}/lb for “${qt.lotName}”`],
    }, { conversationId: conv.id });
  } else if (action === 'accept') {
    await notify(to, 'quote_accepted', {
      es: [`✅ ${req.user.name} aceptó ${usd(qt.priceLb)}/lb`, 'Confirma en el chat para registrar el acuerdo.'],
      en: [`✅ ${req.user.name} accepted ${usd(qt.priceLb)}/lb`, 'Confirm in the chat to record the agreement.'],
    }, { conversationId: conv.id });
  } else if (agreement) {
    await notify(to, 'agreement_new', {
      es: [`🤝 Acuerdo ${agreement.code} registrado`, `${qt.sacks} sacos de «${qt.lotName}» a ${usd(qt.priceLb)}/lb`],
      en: [`🤝 Agreement ${agreement.code} recorded`, `${qt.sacks} bags of “${qt.lotName}” at ${usd(qt.priceLb)}/lb`],
    }, { agreementId: agreement.id });
  }
  res.json({ ok: true, messages: out.msgs.map((m) => S.message(m, conv)) });
}));

module.exports = r;
