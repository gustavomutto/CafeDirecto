// Subastas con fecha límite: el caficultor fija precio base y cierre; los compradores pujan por libra;
// el caficultor elige la oferta que quiera (antes o después del cierre) y se registra el acuerdo.
const express = require('express');

const { pool, one, many } = require('../db');
const { requireAuth } = require('../auth');
const { limit } = require('../ratelimit');
const C = require('../services/conversations');
const { createAgreement } = require('../services/agreements');
const { notify, notifyMany, usd } = require('../services/notifications');
const A = require('../services/auctions');
const { h, bad, notFound, forbidden, conflict, num, str, MIN, tx } = require('../lib/http');

const r = express.Router();

async function findAuction(id) {
  const a = await one('SELECT * FROM auctions WHERE id = $1', [num(id, -1)]);
  if (!a) throw notFound('Subasta no encontrada');
  return a;
}

// Lista: por defecto las subastas activas; ?mine=1 → las mías (caficultor) o en las que pujé (comprador).
r.get('/auctions', requireAuth, h(async (req, res) => {
  let rows;
  if (req.query.mine === '1') {
    rows = req.user.role === 'farmer'
      ? await many('SELECT * FROM auctions WHERE farmer_id = $1 ORDER BY id DESC LIMIT 50', [req.user.id])
      : await many(
        `SELECT a.* FROM auctions a WHERE a.id IN (SELECT DISTINCT auction_id FROM bids WHERE buyer_id = $1)
          ORDER BY a.id DESC LIMIT 50`, [req.user.id],
      );
  } else {
    rows = await many(
      `SELECT a.* FROM auctions a JOIN lots l ON l.id = a.lot_id
        WHERE a.status = 'open' AND a.ends_at > now() AND l.active ORDER BY a.ends_at ASC LIMIT 50`,
    );
  }
  res.json(await Promise.all(rows.map((a) => A.auctionJson(a, req.user))));
}));

r.get('/auctions/:id', requireAuth, h(async (req, res) => {
  res.json(await A.auctionJson(await findAuction(req.params.id), req.user));
}));

// Abrir una subasta para un lote
r.post('/lots/:id/auction', requireAuth, h(async (req, res) => {
  const lot = await one('SELECT * FROM lots WHERE id = $1 AND active', [num(req.params.id, -1)]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden('Solo el dueño del lote puede subastarlo');
  const b = req.body;
  const base = num(b.basePriceLb, lot.price_lb);
  const inc = num(b.minIncrementLb, 0.05);
  const sacks = Math.round(num(b.sacks, lot.sacks));
  const hours = num(b.durationHours, 48);
  if (base <= 0 || base > 100) throw bad('El precio base debe estar entre US$ 0,01 y US$ 100 por libra');
  if (inc < 0.01 || inc > 5) throw bad('El incremento mínimo debe estar entre US$ 0,01 y US$ 5');
  if (sacks < 1 || sacks > lot.sacks) throw bad(`Cantidad inválida (disponible: ${lot.sacks} sacos)`);
  if (hours < 1 || hours > 24 * 30) throw bad('La subasta debe durar entre 1 hora y 30 días');
  if (await one(`SELECT 1 FROM auctions WHERE lot_id = $1 AND status = 'open'`, [lot.id])) {
    throw conflict('Este lote ya tiene una subasta abierta');
  }
  const a = await one(
    `INSERT INTO auctions (lot_id, farmer_id, base_price_lb, min_increment_lb, sacks, incoterm, ends_at)
     VALUES ($1,$2,$3,$4,$5,$6, now() + make_interval(mins => $7)) RETURNING *`,
    [lot.id, req.user.id, base, inc, sacks, str(b.incoterm, 60) || 'FOB Buenaventura', Math.round(hours * 60)],
  );
  // avisa a los compradores que ya habían mostrado interés en este lote
  const interested = (await many('SELECT buyer_id FROM lot_views WHERE lot_id = $1', [lot.id])).map((x) => x.buyer_id);
  const h2 = Math.round(hours);
  await notifyMany(interested, 'auction_opened', {
    es: [`🔨 Subasta abierta: «${lot.name}»`, `Precio base ${usd(base)}/lb · ${sacks} sacos · cierra en ${h2} h`],
    en: [`🔨 Auction open: “${lot.name}”`, `Base price ${usd(base)}/lb · ${sacks} bags · closes in ${h2} h`],
  }, { auctionId: a.id, lotId: lot.id });
  res.status(201).json(await A.auctionJson(a, req.user));
}));

// Pujar
r.post('/auctions/:id/bids', requireAuth, limit('bid', 30, MIN, (req) => req.user.id), h(async (req, res) => {
  if (req.user.role !== 'buyer') throw forbidden('Solo los compradores pueden ofertar');
  const price = Number(num(req.body.priceLb).toFixed(2));
  const result = await tx(pool, async (client) => {
    const a = (await client.query('SELECT * FROM auctions WHERE id = $1 FOR UPDATE', [num(req.params.id, -1)])).rows[0];
    if (!a) throw notFound('Subasta no encontrada');
    if (a.status !== 'open' || new Date(a.ends_at) <= new Date()) throw bad('La subasta ya no recibe ofertas');
    const top = (await client.query(
      'SELECT * FROM bids WHERE auction_id = $1 ORDER BY price_lb DESC, id ASC LIMIT 1', [a.id],
    )).rows[0];
    const min = top ? Number(top.price_lb) + Number(a.min_increment_lb) : Number(a.base_price_lb);
    if (price + 1e-9 < Number(min.toFixed(2))) throw bad(`La oferta mínima es ${usd(min)}/lb`);
    if (price > Number(a.base_price_lb) * 5) throw bad('La oferta es demasiado alta; revisa el valor');
    const bid = (await client.query(
      'INSERT INTO bids (auction_id, buyer_id, price_lb) VALUES ($1,$2,$3) RETURNING *', [a.id, req.user.id, price],
    )).rows[0];
    // Anti-francotirador: si falta poco para el cierre, se alarga para que los demás puedan responder.
    let extended = false;
    if (new Date(a.ends_at).getTime() - Date.now() < A.ANTI_SNIPING_MS) {
      await client.query('UPDATE auctions SET ends_at = $2 WHERE id = $1', [a.id, new Date(Date.now() + A.ANTI_SNIPING_MS)]);
      extended = true;
    }
    return { a, bid, top, extended };
  });
  const { a, top } = result;
  const lot = await one('SELECT name FROM lots WHERE id = $1', [a.lot_id]);
  const data = { auctionId: a.id, lotId: a.lot_id };
  const count = (await one('SELECT COUNT(*)::int AS n FROM bids WHERE auction_id = $1', [a.id])).n;
  await notify(a.farmer_id, 'bid_new', {
    es: [`💰 Nueva oferta: ${usd(price)}/lb`, `${req.user.name} ofertó por «${lot.name}» · ${count} oferta(s)`],
    en: [`💰 New offer: ${usd(price)}/lb`, `${req.user.name} bid on “${lot.name}” · ${count} offer(s)`],
  }, data);
  if (top && top.buyer_id !== req.user.id) {
    await notify(top.buyer_id, 'bid_outbid', {
      es: [`⚠️ Te superaron en «${lot.name}»`, `La oferta más alta ahora es ${usd(price)}/lb. ¡Puedes subirla!`],
      en: [`⚠️ You were outbid on “${lot.name}”`, `The highest offer is now ${usd(price)}/lb. You can raise it!`],
    }, data);
  }
  res.status(201).json(await A.auctionJson(await findAuction(a.id), req.user));
}));

// Adjudicar: el caficultor elige una oferta → acuerdo registrado y chat con el ganador.
r.post('/auctions/:id/award', requireAuth, h(async (req, res) => {
  const out = await tx(pool, async (client) => {
    const a = (await client.query('SELECT * FROM auctions WHERE id = $1 FOR UPDATE', [num(req.params.id, -1)])).rows[0];
    if (!a) throw notFound('Subasta no encontrada');
    if (a.farmer_id !== req.user.id) throw forbidden('Solo el caficultor puede adjudicar la subasta');
    if (a.status !== 'open') throw bad('La subasta ya está cerrada');
    const bid = (await client.query('SELECT * FROM bids WHERE id = $1 AND auction_id = $2', [num(req.body.bidId, -1), a.id])).rows[0];
    if (!bid) throw notFound('Oferta no encontrada');
    const lot = (await client.query('SELECT * FROM lots WHERE id = $1', [a.lot_id])).rows[0];
    const conv = await C.ensureConversation(client, a.farmer_id, bid.buyer_id, a.lot_id);
    const price = Number(bid.price_lb);
    await C.insertMessage(client, conv, {
      type: 'system',
      sys_es: `🔨 Subasta adjudicada: ${usd(price)}/lb · ${a.sacks} sacos de «${lot.name}»`,
      sys_en: `🔨 Auction awarded: ${usd(price)}/lb · ${a.sacks} bags of “${lot.name}”`,
    });
    const { agreement } = await createAgreement(client, {
      conv, lotId: a.lot_id, lotName: lot.name, variety: lot.variety, process: lot.process,
      priceLb: price, sacks: a.sacks, incoterm: a.incoterm, firstAt: new Date(a.created_at).getTime(),
    });
    await client.query(
      `UPDATE auctions SET status = 'awarded', winning_bid_id = $2, agreement_id = $3, closed_at = now(), ended_notified = true WHERE id = $1`,
      [a.id, bid.id, agreement.id],
    );
    await client.query(`UPDATE bids SET status = CASE WHEN id = $2 THEN 'won' ELSE 'lost' END WHERE auction_id = $1`, [a.id, bid.id]);
    return { a, bid, lot, agreement, price };
  });
  const { a, bid, lot, agreement, price } = out;
  const data = { auctionId: a.id, lotId: a.lot_id };
  await notify(bid.buyer_id, 'auction_won', {
    es: [`🎉 ¡Ganaste la subasta de «${lot.name}»!`, `Acuerdo ${agreement.code}: ${a.sacks} sacos a ${usd(price)}/lb`],
    en: [`🎉 You won the auction for “${lot.name}”!`, `Agreement ${agreement.code}: ${a.sacks} bags at ${usd(price)}/lb`],
  }, { ...data, agreementId: agreement.id });
  const losers = (await A.biddersOf(a.id)).filter((id) => id !== bid.buyer_id);
  await notifyMany(losers, 'auction_lost', {
    es: [`La subasta de «${lot.name}» se adjudicó`, `Se cerró en ${usd(price)}/lb con otro comprador. ¡Gracias por participar!`],
    en: [`The auction for “${lot.name}” was awarded`, `It closed at ${usd(price)}/lb with another buyer. Thanks for taking part!`],
  }, data);
  res.json({ auction: await A.auctionJson(await findAuction(a.id), req.user), agreementId: agreement.id });
}));

r.post('/auctions/:id/cancel', requireAuth, h(async (req, res) => {
  const a = await findAuction(req.params.id);
  if (a.farmer_id !== req.user.id) throw forbidden();
  if (a.status !== 'open') throw bad('La subasta ya está cerrada');
  const updated = await one(
    `UPDATE auctions SET status = 'cancelled', closed_at = now(), ended_notified = true WHERE id = $1 AND status = 'open' RETURNING *`,
    [a.id],
  );
  if (!updated) throw bad('La subasta ya está cerrada');
  await pool.query(`UPDATE bids SET status = 'lost' WHERE auction_id = $1`, [a.id]);
  const lot = await one('SELECT name FROM lots WHERE id = $1', [a.lot_id]);
  await notifyMany(await A.biddersOf(a.id), 'auction_cancelled', {
    es: [`La subasta de «${lot.name}» fue cancelada`, 'El caficultor la cerró sin elegir ganador.'],
    en: [`The auction for “${lot.name}” was cancelled`, 'The farmer closed it without choosing a winner.'],
  }, { auctionId: a.id, lotId: a.lot_id });
  res.json(await A.auctionJson(updated, req.user));
}));

module.exports = r;
