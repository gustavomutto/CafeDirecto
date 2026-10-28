// Subastas: carga de datos y el proceso automático que avisa cuando una subasta termina o vence.
const { pool, one, many } = require('../db');
const S = require('../serialize');
const { notify, notifyMany, usd } = require('./notifications');

const AWARD_WINDOW_DAYS = 7; // días que tiene el caficultor para elegir ganador después del cierre
const ANTI_SNIPING_MS = 2 * 60 * 1000; // una oferta en los últimos 2 minutos alarga la subasta 2 minutos

const BIDS_SELECT = `
  SELECT b.*, u.name AS buyer_name, u.photo_id AS buyer_photo, bu.company, bu.country
    FROM bids b JOIN users u ON u.id = b.buyer_id LEFT JOIN buyers bu ON bu.user_id = b.buyer_id
   WHERE b.auction_id = $1`;

async function auctionJson(a, viewer) {
  const lotRow = await one(`${S.LOT_SELECT} WHERE l.id = $1`, [a.lot_id]);
  const bids = await many(BIDS_SELECT, [a.id]);
  return S.auction(a, lotRow, bids, viewer);
}

const biddersOf = async (auctionId) =>
  (await many('SELECT DISTINCT buyer_id FROM bids WHERE auction_id = $1', [auctionId])).map((r) => r.buyer_id);

/** Avisa a los interesados que terminó el tiempo (una sola vez) y vence las que nadie adjudicó. */
async function sweep() {
  const ended = await many(
    `UPDATE auctions a SET ended_notified = true
       FROM lots l
      WHERE l.id = a.lot_id AND a.status = 'open' AND a.ends_at <= now() AND NOT a.ended_notified
      RETURNING a.*, l.name AS lot_name`,
  );
  for (const a of ended) {
    const best = await one('SELECT MAX(price_lb) AS p, COUNT(DISTINCT buyer_id)::int AS n FROM bids WHERE auction_id = $1', [a.id]);
    const data = { auctionId: a.id, lotId: a.lot_id };
    if (best.n > 0) {
      await notify(a.farmer_id, 'auction_ended', {
        es: [`⏰ Terminó tu subasta «${a.lot_name}»`, `Mejor oferta ${usd(best.p)}/lb de ${best.n} comprador(es). Elige al ganador.`],
        en: [`⏰ Your auction “${a.lot_name}” ended`, `Best offer ${usd(best.p)}/lb from ${best.n} buyer(s). Choose the winner.`],
      }, data);
      await notifyMany(await biddersOf(a.id), 'auction_ended', {
        es: [`⏰ Terminó la subasta «${a.lot_name}»`, 'El caficultor elegirá la oferta ganadora.'],
        en: [`⏰ The auction “${a.lot_name}” ended`, 'The farmer will choose the winning offer.'],
      }, data);
    } else {
      await notify(a.farmer_id, 'auction_ended', {
        es: [`⏰ Terminó tu subasta «${a.lot_name}»`, 'No recibió ofertas. Puedes abrir una nueva con otro precio base.'],
        en: [`⏰ Your auction “${a.lot_name}” ended`, 'It received no offers. You can open a new one with another base price.'],
      }, data);
    }
  }

  const expired = await many(
    `UPDATE auctions a SET status = 'expired', closed_at = now()
       FROM lots l
      WHERE l.id = a.lot_id AND a.status = 'open' AND a.ends_at < now() - make_interval(days => $1)
      RETURNING a.*, l.name AS lot_name`,
    [AWARD_WINDOW_DAYS],
  );
  for (const a of expired) {
    await pool.query(`UPDATE bids SET status = 'lost' WHERE auction_id = $1`, [a.id]);
    await notifyMany(await biddersOf(a.id), 'auction_expired', {
      es: [`La subasta «${a.lot_name}» venció`, 'El caficultor no eligió ganador. Puedes escribirle para negociar.'],
      en: [`The auction “${a.lot_name}” expired`, 'The farmer did not choose a winner. You can message them to negotiate.'],
    }, { auctionId: a.id, lotId: a.lot_id });
  }
}

let timer = null;
function startAuctionJob() {
  if (timer) return;
  const run = () => sweep().catch((e) => console.error('Revisión de subastas falló:', e.message));
  timer = setInterval(run, 60 * 1000);
  timer.unref();
  setTimeout(run, 5000).unref();
}

function stopAuctionJob() {
  if (timer) clearInterval(timer);
  timer = null;
}

module.exports = { auctionJson, biddersOf, sweep, startAuctionJob, stopAuctionJob, AWARD_WINDOW_DAYS, ANTI_SNIPING_MS };
