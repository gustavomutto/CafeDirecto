// Notificaciones dentro de la app (campanita). La app las consulta cada pocos segundos
// y muestra un aviso en el teléfono cuando llega una nueva.
const { pool } = require('../db');

const usd = (v) => `US$ ${Number(v).toFixed(2)}`;

/**
 * Crea una notificación para `userId`.
 * `text` = { es: [título, cuerpo], en: [título, cuerpo] }, `data` = a dónde lleva al tocarla.
 */
async function notify(userId, type, text, data = {}, client = pool) {
  if (!userId) return null;
  const r = await client.query(
    `INSERT INTO notifications (user_id, type, title_es, body_es, title_en, body_en, data)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [userId, type, text.es[0], text.es[1] || '', text.en[0], text.en[1] || '', JSON.stringify(data)],
  );
  return r.rows[0];
}

/** Lo mismo para varios usuarios a la vez (por ejemplo, todos los que pujaron). */
async function notifyMany(userIds, type, text, data = {}, client = pool) {
  const unique = [...new Set(userIds.filter(Boolean))];
  for (const id of unique) await notify(id, type, text, data, client);
}

module.exports = { notify, notifyMany, usd };
