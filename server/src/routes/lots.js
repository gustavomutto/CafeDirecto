// Lotes de café: buscar, ver, publicar, editar y retirar.
// Cuando un comprador abre un lote, el caficultor recibe un aviso de que hay interés.
const express = require('express');

const { q, one, many } = require('../db');
const { requireAuth } = require('../auth');
const S = require('../serialize');
const { notify } = require('../services/notifications');
const { h, bad, notFound, forbidden, num, str, strArr } = require('../lib/http');

const r = express.Router();
const INTEREST_EVERY_HOURS = 24; // como máximo un aviso por comprador y lote cada 24 h

r.get('/lots', requireAuth, h(async (req, res) => {
  const where = ['l.active'];
  const params = [];
  const p = (v) => { params.push(v); return `$${params.length}`; };
  const qs = req.query;
  if (qs.farmerId) where.push(`l.farmer_id = ${p(num(qs.farmerId, -1))}`);
  else where.push('l.sacks > 0');
  const list = (v) => String(v || '').split(',').map((s) => s.trim()).filter(Boolean);
  if (list(qs.region).length) where.push(`f.region = ANY(${p(list(qs.region))})`);
  if (list(qs.process).length) where.push(`l.process = ANY(${p(list(qs.process))})`);
  if (list(qs.variety).length) where.push(`l.variety = ANY(${p(list(qs.variety))})`);
  if (qs.minSca) where.push(`l.sca >= ${p(num(qs.minSca))}`);
  if (qs.minAlt) where.push(`COALESCE(f.altitude,0) >= ${p(num(qs.minAlt))}`);
  if (qs.auction === '1') where.push(`EXISTS (SELECT 1 FROM auctions au WHERE au.lot_id = l.id AND au.status = 'open' AND au.ends_at > now())`);
  if (qs.q) {
    const t = `%${str(qs.q, 80)}%`;
    where.push(`(l.name ILIKE ${p(t)} OR l.variety ILIKE $${params.length} OR f.name ILIKE $${params.length}
                 OR u.name ILIKE $${params.length} OR f.region ILIKE $${params.length} OR f.municipality ILIKE $${params.length}
                 OR array_to_string(l.notes, ' ') ILIKE $${params.length})`);
  }
  const rows = await many(`${S.LOT_SELECT} WHERE ${where.join(' AND ')} ORDER BY l.created_at DESC LIMIT 200`, params);
  res.json(rows.map(S.lot));
}));

/** Registra que un comprador vio el lote y, si corresponde, avisa al caficultor. */
async function recordInterest(lotRow, buyer) {
  const v = await one(
    `INSERT INTO lot_views (lot_id, buyer_id) VALUES ($1, $2)
     ON CONFLICT (lot_id, buyer_id) DO UPDATE SET views = lot_views.views + 1, last_at = now()
     RETURNING *, (notified_at IS NULL OR notified_at < now() - make_interval(hours => $3)) AS should_notify`,
    [lotRow.id, buyer.id, INTEREST_EVERY_HOURS],
  );
  if (!v.should_notify) return;
  await q('UPDATE lot_views SET notified_at = now() WHERE lot_id = $1 AND buyer_id = $2', [lotRow.id, buyer.id]);
  const b = await one('SELECT company, country FROM buyers WHERE user_id = $1', [buyer.id]);
  const who = [b?.company, b?.country].filter(Boolean).join(' · ');
  const again = v.views > 1;
  await notify(lotRow.farmer_id, 'lot_interest', {
    es: [
      `👀 ${buyer.name} está interesado en tu café`,
      `${who ? `${who} · ` : ''}${again ? 'volvió a ver' : 'vio'} tu lote «${lotRow.name}». ¡Escríbele!`,
    ],
    en: [
      `👀 ${buyer.name} is interested in your coffee`,
      `${who ? `${who} · ` : ''}${again ? 'looked again at' : 'viewed'} your lot “${lotRow.name}”. Send a message!`,
    ],
  }, { lotId: lotRow.id, userId: buyer.id });
}

r.get('/lots/:id', requireAuth, h(async (req, res) => {
  const row = await one(`${S.LOT_SELECT} WHERE l.id = $1`, [num(req.params.id, -1)]);
  if (!row) throw notFound('Lote no encontrado');
  const farm = await one('SELECT certifications FROM farms WHERE user_id = $1', [row.farmer_id]);
  const out = { ...S.lot(row), certifications: (farm?.certifications || '').split('\n').map((s) => s.trim()).filter(Boolean) };
  if (req.user.role === 'buyer' && row.active) {
    // el aviso nunca debe impedir que el comprador vea el lote
    await recordInterest(row, req.user).catch((e) => console.error('No se pudo registrar el interés:', e.message));
  }
  if (req.user.id === row.farmer_id) {
    out.interest = (await one('SELECT COUNT(*)::int AS n FROM lot_views WHERE lot_id = $1', [row.id])).n;
  }
  res.json(out);
}));

// Compradores que vieron el lote (solo lo ve su dueño).
r.get('/lots/:id/interest', requireAuth, h(async (req, res) => {
  const lot = await one('SELECT * FROM lots WHERE id = $1', [num(req.params.id, -1)]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden();
  const rows = await many(
    `SELECT v.*, u.name, u.photo_id, u.lang, b.company, b.city, b.country
       FROM lot_views v JOIN users u ON u.id = v.buyer_id LEFT JOIN buyers b ON b.user_id = v.buyer_id
      WHERE v.lot_id = $1 AND u.deleted_at IS NULL ORDER BY v.last_at DESC LIMIT 100`,
    [lot.id],
  );
  res.json(rows.map((v) => ({
    user: { id: v.buyer_id, name: v.name, photo: S.img(v.photo_id), lang: v.lang, role: 'buyer' },
    company: v.company || '',
    city: v.city || '',
    country: v.country || '',
    views: v.views,
    firstAt: S.ms(v.first_at),
    lastAt: S.ms(v.last_at),
  })));
}));

function lotFields(b) {
  const sca = num(b.sca);
  if (!str(b.variety)) throw bad('Elige la variedad');
  if (!['lavado', 'honey', 'natural'].includes(b.process)) throw bad('Proceso inválido');
  if (sca < 80) throw bad('CaféDirecto recibe cafés de 80 puntos o más');
  if (num(b.priceLb) <= 0) throw bad('El precio debe ser mayor que 0');
  return [
    str(b.name, 120) || `Lote ${str(b.variety, 60)}`, str(b.variety, 60), b.process, Math.max(0, Math.round(num(b.sacks))),
    sca, num(b.priceLb), b.priceCarga ? Math.round(num(b.priceCarga)) : null, strArr(b.notes).slice(0, 6),
    str(b.harvest, 80), b.photoId ? num(b.photoId) : null,
  ];
}

r.post('/lots', requireAuth, h(async (req, res) => {
  if (req.user.role !== 'farmer') throw forbidden('Solo los caficultores publican lotes');
  const row = await one(
    `INSERT INTO lots (farmer_id, name, variety, process, sacks, sca, price_lb, price_carga, notes, harvest, photo_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
    [req.user.id, ...lotFields(req.body)],
  );
  res.status(201).json(S.lot(await one(`${S.LOT_SELECT} WHERE l.id = $1`, [row.id])));
}));

r.put('/lots/:id', requireAuth, h(async (req, res) => {
  const id = num(req.params.id, -1);
  const lot = await one('SELECT * FROM lots WHERE id = $1', [id]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden();
  await q(
    `UPDATE lots SET name=$2, variety=$3, process=$4, sacks=$5, sca=$6, price_lb=$7, price_carga=$8, notes=$9, harvest=$10, photo_id=$11
      WHERE id=$1`,
    [id, ...lotFields(req.body)],
  );
  res.json(S.lot(await one(`${S.LOT_SELECT} WHERE l.id = $1`, [id])));
}));

r.delete('/lots/:id', requireAuth, h(async (req, res) => {
  const lot = await one('SELECT * FROM lots WHERE id = $1', [num(req.params.id, -1)]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden();
  if (await one(`SELECT 1 FROM auctions WHERE lot_id = $1 AND status = 'open'`, [lot.id])) {
    throw bad('Este lote tiene una subasta abierta. Cancélala o adjudícala primero.');
  }
  await q('UPDATE lots SET active = false WHERE id = $1', [lot.id]);
  res.json({ ok: true });
}));

module.exports = r;
