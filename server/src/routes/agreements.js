// Acuerdos: estado del pedido, calificaciones, reporte de calidad (RF-22) y disputas (RF-19).
const express = require('express');

const { q, one, many } = require('../db');
const { requireAuth } = require('../auth');
const { both } = require('../translate');
const S = require('../serialize');
const { notifyChat } = require('../services/conversations');
const { myAgreement } = require('../services/agreements');
const { notify } = require('../services/notifications');
const { assertOwnImages } = require('../services/images');
const { h, bad, notFound, forbidden, conflict, num, str, strArr, optId } = require('../lib/http');

const r = express.Router();
const otherParty = (a, me) => (a.farmer_id === me.id ? a.buyer_id : a.farmer_id);

r.get('/agreements', requireAuth, h(async (req, res) => {
  const rows = await many(
    'SELECT * FROM agreements WHERE farmer_id = $1 OR buyer_id = $1 ORDER BY created_at DESC', [req.user.id],
  );
  res.json(await Promise.all(rows.map(S.agreement)));
}));

r.get('/agreements/:id', requireAuth, h(async (req, res) => {
  res.json(await S.agreement(await myAgreement(req, req.params.id)));
}));

// Avanza el estado: confirmado → enviado (lo marca el caficultor, que despacha)
//                             → entregado (lo marca el comprador, que recibe; así nadie habilita
//                               solo las calificaciones ni da por recibido algo que no llegó).
const STATUS_TEXT = {
  2: ['Café despachado 🚢 · en camino', 'Coffee shipped 🚢 · on its way'],
  3: ['Café entregado ✅ · ya pueden calificarse', 'Coffee delivered ✅ · you can now rate each other'],
};

r.post('/agreements/:id/advance', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  if (a.status >= 3) throw bad('El acuerdo ya fue entregado');
  const next = a.status + 1;
  if (next === 2 && req.user.id !== a.farmer_id) throw forbidden('El despacho lo marca el caficultor');
  if (next === 3 && req.user.id !== a.buyer_id) throw forbidden('La entrega la confirma el comprador');
  const history = [...(a.history || [])];
  while (history.length <= next) history.push(0);
  history[next] = Date.now();
  const updated = await one('UPDATE agreements SET status = $2, history = $3 WHERE id = $1 RETURNING *', [a.id, next, JSON.stringify(history)]);
  const [es, en] = STATUS_TEXT[next];
  await notifyChat(a, es, en);
  await notify(otherParty(a, req.user), 'agreement_status', { es: [`📦 ${a.code}`, es], en: [`📦 ${a.code}`, en] }, { agreementId: a.id });
  res.json(await S.agreement(updated));
}));

r.post('/agreements/:id/rate', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  if (a.status < 3) throw bad('Solo se califica después de la entrega');
  const stars = Math.round(num(req.body.stars));
  if (stars < 1 || stars > 5) throw bad('Elige de 1 a 5 estrellas');
  if (await one('SELECT 1 FROM ratings WHERE agreement_id = $1 AND by_user_id = $2', [a.id, req.user.id])) {
    throw conflict('Ya calificaste este acuerdo');
  }
  const comment = await both(req.body.comment, req.user.lang);
  await q(
    'INSERT INTO ratings (agreement_id, by_user_id, stars, tags, comment_es, comment_en) VALUES ($1,$2,$3,$4,$5,$6)',
    [a.id, req.user.id, stars, strArr(req.body.tags), comment.es || null, comment.en || null],
  );
  await notify(otherParty(a, req.user), 'rating_new', {
    es: [`⭐ ${req.user.name} te calificó con ${stars} estrellas`, `Acuerdo ${a.code}`],
    en: [`⭐ ${req.user.name} rated you ${stars} stars`, `Agreement ${a.code}`],
  }, { agreementId: a.id });
  res.status(201).json(await S.agreement(a));
}));

r.post('/agreements/:id/quality', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  if (a.buyer_id !== req.user.id) throw forbidden('Solo el comprador emite el reporte de calidad');
  if (a.status < 3) throw bad('El reporte de calidad se emite después de la entrega');
  if (await one('SELECT 1 FROM quality_reports WHERE agreement_id = $1', [a.id])) {
    throw conflict('Ya enviaste el reporte de calidad de este acuerdo');
  }
  const b = req.body;
  const sca = num(b.sca, -1);
  if (sca < 0 || sca > 100) throw bad('El puntaje SCA debe estar entre 0 y 100');
  const moisture = b.moisture === undefined || b.moisture === null || b.moisture === '' ? null : num(b.moisture, -1);
  if (moisture !== null && (moisture < 0 || moisture > 100)) throw bad('La humedad debe estar entre 0 y 100 %');
  const defects = b.defects === undefined || b.defects === null || b.defects === '' ? null : Math.round(num(b.defects, -1));
  if (defects !== null && defects < 0) throw bad('Los defectos no pueden ser negativos');
  await assertOwnImages(req.user.id, [optId(b.photoId)]);
  const comment = await both(b.comment, req.user.lang);
  await q(
    `INSERT INTO quality_reports (agreement_id, by_user_id, sca, moisture, defects, matches_sample, notes, comment_es, comment_en, photo_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
    [a.id, req.user.id, sca, moisture, defects, b.matchesSample !== false, strArr(b.notes).slice(0, 8),
      comment.es || null, comment.en || null, b.photoId ? num(b.photoId) : null],
  );
  await notifyChat(a,
    `📋 El comprador envió el reporte de calidad: ${sca} puntos SCA`,
    `📋 The buyer submitted the quality report: ${sca} SCA points`);
  res.status(201).json(await S.agreement(a));
}));

const DISPUTE_REASONS = {
  quality: ['calidad', 'quality'],
  quantity: ['cantidad', 'quantity'],
  delay: ['retraso', 'delay'],
  payment: ['pago', 'payment'],
  other: ['otro motivo', 'other'],
};

async function myDispute(req, id) {
  const d = await one('SELECT * FROM disputes WHERE id = $1', [num(id, -1)]);
  if (!d) throw notFound('Disputa no encontrada');
  return { d, a: await myAgreement(req, d.agreement_id) };
}

async function disputeEvent(req, kind) {
  await assertOwnImages(req.user.id, [optId(req.body.photoId)]);
  const text = await both(str(req.body.text, 2000), req.user.lang);
  return { by: req.user.id, kind, es: text.es, en: text.en, photo: req.body.photoId ? num(req.body.photoId) : null, at: Date.now() };
}

r.post('/agreements/:id/disputes', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  const reason = req.body.reason;
  if (!DISPUTE_REASONS[reason]) throw bad('Elige el motivo de la disputa');
  if (!str(req.body.text)) throw bad('Describe el problema');
  if (await one(`SELECT 1 FROM disputes WHERE agreement_id = $1 AND status = 'open'`, [a.id])) {
    throw conflict('Este acuerdo ya tiene una disputa abierta');
  }
  const ev = await disputeEvent(req, 'open');
  await q('INSERT INTO disputes (agreement_id, opened_by, reason, events) VALUES ($1,$2,$3,$4)', [a.id, req.user.id, reason, JSON.stringify([ev])]);
  const [es, en] = DISPUTE_REASONS[reason];
  const f = req.user.role === 'farmer';
  await notifyChat(a,
    `⚠️ ${f ? 'El caficultor' : 'El comprador'} abrió una disputa por ${es} en ${a.code}`,
    `⚠️ ${f ? 'The farmer' : 'The buyer'} opened a ${en} dispute on ${a.code}`);
  res.status(201).json(await S.agreement(a));
}));

r.post('/disputes/:id/comments', requireAuth, h(async (req, res) => {
  const { d, a } = await myDispute(req, req.params.id);
  if (d.status !== 'open') throw bad('La disputa ya está resuelta');
  if (!str(req.body.text) && !req.body.photoId) throw bad('Escribe una respuesta');
  const ev = await disputeEvent(req, 'comment');
  await q(`UPDATE disputes SET events = events || $2::jsonb WHERE id = $1`, [d.id, JSON.stringify([ev])]);
  res.status(201).json(await S.agreement(a));
}));

// La disputa la da por resuelta quien la abrió (es quien sabe si el problema se solucionó).
r.post('/disputes/:id/resolve', requireAuth, h(async (req, res) => {
  const { d, a } = await myDispute(req, req.params.id);
  if (d.status !== 'open') throw bad('La disputa ya está resuelta');
  if (d.opened_by !== req.user.id) throw forbidden('Solo quien abrió la disputa puede darla por resuelta');
  const ev = await disputeEvent(req, 'resolve');
  await q(
    `UPDATE disputes SET status = 'resolved', resolved_at = now(), events = events || $2::jsonb WHERE id = $1`,
    [d.id, JSON.stringify([ev])],
  );
  await notifyChat(a, `✅ La disputa de ${a.code} quedó resuelta`, `✅ The dispute on ${a.code} was resolved`);
  res.json(await S.agreement(a));
}));

module.exports = r;
