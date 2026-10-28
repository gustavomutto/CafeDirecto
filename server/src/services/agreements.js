// Creación y consulta de acuerdos. Los usan las cotizaciones del chat y las subastas.
const { one } = require('../db');
const { bad, notFound, forbidden, num } = require('../lib/http');
const { insertMessage } = require('./conversations');

async function myAgreement(req, id) {
  const a = await one('SELECT * FROM agreements WHERE id = $1', [num(id, -1)]);
  if (!a) throw notFound('Acuerdo no encontrado');
  if (a.farmer_id !== req.user.id && a.buyer_id !== req.user.id) throw forbidden();
  return a;
}

/**
 * Registra un acuerdo dentro de una transacción (`client`):
 * bloquea el lote, verifica los sacos, crea el código CD-AAAA-#### y descuenta los sacos.
 * También deja la tarjeta del acuerdo en el chat.
 */
async function createAgreement(client, { conv, lotId, lotName, variety, process, priceLb, sacks, incoterm, firstAt }) {
  const lot = lotId ? (await client.query('SELECT * FROM lots WHERE id = $1 FOR UPDATE', [lotId])).rows[0] : null;
  if (lot && lot.sacks < sacks) throw bad(`El lote ya solo tiene ${lot.sacks} sacos disponibles`);
  const now = Date.now();
  const ag = (await client.query(
    `INSERT INTO agreements (code, conversation_id, farmer_id, buyer_id, lot_id, lot_name, variety, process, sca, price_lb, sacks, incoterm, status, history)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,1,$13) RETURNING *`,
    [
      `tmp-${now}-${Math.random()}`, conv.id, conv.farmer_id, conv.buyer_id, lotId, lot?.name || lotName || '',
      lot?.variety || variety || '', lot?.process || process || 'lavado', lot?.sca || 0,
      priceLb, sacks, incoterm, JSON.stringify([firstAt || now, now]),
    ],
  )).rows[0];
  const code = `CD-${new Date().getFullYear()}-${String(ag.id).padStart(4, '0')}`;
  await client.query('UPDATE agreements SET code = $2 WHERE id = $1', [ag.id, code]);
  if (lot) await client.query('UPDATE lots SET sacks = GREATEST(0, sacks - $2) WHERE id = $1', [lot.id, sacks]);
  const message = await insertMessage(client, conv, { type: 'agreement', agreement_id: ag.id });
  return { agreement: { ...ag, code }, message };
}

module.exports = { myAgreement, createAgreement };
