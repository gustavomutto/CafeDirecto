// Lógica de conversaciones y mensajes que comparten varias rutas (chat, cotizaciones, subastas, acuerdos).
const { pool, one } = require('../db');
const S = require('../serialize');
const { notFound, forbidden, num } = require('../lib/http');

/** Busca una conversación y verifica que el usuario participe en ella. */
async function myConv(req, id) {
  const c = await one('SELECT * FROM conversations WHERE id = $1', [num(id, -1)]);
  if (!c) throw notFound('Conversación no encontrada');
  if (c.farmer_id !== req.user.id && c.buyer_id !== req.user.id) throw forbidden();
  return c;
}

async function otherOf(c, me) {
  const otherId = c.farmer_id === me.id ? c.buyer_id : c.farmer_id;
  const u = await one(
    `SELECT u.*, f.name AS farm_name, f.region, b.company, b.city, b.country
       FROM users u LEFT JOIN farms f ON f.user_id=u.id LEFT JOIN buyers b ON b.user_id=u.id WHERE u.id=$1`,
    [otherId],
  );
  return {
    ...S.publicUser(u),
    sub: u.role === 'farmer' ? [u.farm_name, u.region].filter(Boolean).join(' · ') : [u.company, u.city, u.country].filter(Boolean).join(' · '),
  };
}

async function convSummary(c, me) {
  const lastRead = c.farmer_id === me.id ? c.farmer_last_read : c.buyer_last_read;
  const last = await one(
    `SELECT * FROM messages WHERE conversation_id = $1 AND type <> 'system' ORDER BY id DESC LIMIT 1`, [c.id],
  ) || await one('SELECT * FROM messages WHERE conversation_id = $1 ORDER BY id DESC LIMIT 1', [c.id]);
  const unread = await one(
    'SELECT COUNT(*)::int AS n FROM messages WHERE conversation_id = $1 AND id > $2 AND (sender_id IS NULL OR sender_id <> $3)',
    [c.id, lastRead, me.id],
  );
  const lot = c.lot_id ? await one(`${S.LOT_SELECT} WHERE l.id = $1`, [c.lot_id]) : null;
  return {
    id: c.id,
    farmerId: c.farmer_id,
    buyerId: c.buyer_id,
    lot: lot ? S.lot(lot) : null,
    other: await otherOf(c, me),
    last: last ? S.message(last, c) : null,
    unread: unread.n,
    updatedAt: S.ms(c.updated_at),
  };
}

/** Inserta un mensaje y actualiza la fecha de la conversación. `client` puede ser el pool o una transacción. */
async function insertMessage(client, c, fields) {
  const cols = Object.keys(fields);
  const vals = Object.values(fields);
  const m = (await client.query(
    `INSERT INTO messages (conversation_id, ${cols.join(',')}) VALUES ($1, ${cols.map((_, i) => `$${i + 2}`).join(',')}) RETURNING *`,
    [c.id, ...vals],
  )).rows[0];
  await client.query('UPDATE conversations SET updated_at = now() WHERE id = $1', [c.id]);
  return m;
}

async function markRead(c, userId, lastId) {
  const col = c.farmer_id === userId ? 'farmer_last_read' : 'buyer_last_read';
  await pool.query(`UPDATE conversations SET ${col} = GREATEST(${col}, $2) WHERE id = $1`, [c.id, lastId]);
}

/** Devuelve la conversación entre un caficultor y un comprador; la crea si no existe. */
async function ensureConversation(client, farmerId, buyerId, lotId = null) {
  let c = (await client.query('SELECT * FROM conversations WHERE farmer_id = $1 AND buyer_id = $2', [farmerId, buyerId])).rows[0];
  if (!c) {
    c = (await client.query(
      'INSERT INTO conversations (farmer_id, buyer_id, lot_id) VALUES ($1,$2,$3) RETURNING *', [farmerId, buyerId, lotId],
    )).rows[0];
    await insertMessage(client, c, {
      type: 'system',
      sys_es: 'Conversación iniciada · traducción automática activa',
      sys_en: 'Conversation started · auto-translation on',
    });
  } else if (lotId) {
    c = (await client.query('UPDATE conversations SET lot_id = $2 WHERE id = $1 RETURNING *', [c.id, lotId])).rows[0];
  }
  return c;
}

/** Deja un aviso del sistema en el chat de un acuerdo (si tiene conversación). */
async function notifyChat(a, es, en) {
  if (!a.conversation_id) return;
  const c = await one('SELECT * FROM conversations WHERE id = $1', [a.conversation_id]);
  if (c) await insertMessage(pool, c, { type: 'system', sys_es: es, sys_en: en });
}

module.exports = { myConv, otherOf, convSummary, insertMessage, markRead, ensureConversation, notifyChat };
