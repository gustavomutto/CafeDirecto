// Utilidades HTTP compartidas por todas las rutas: errores con código y lectura segura del cuerpo.

/** Envuelve rutas async para que los errores lleguen al manejador de errores de Express. */
const h = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const bad = (msg) => new HttpError(400, msg);
const notFound = (msg = 'No encontrado') => new HttpError(404, msg);
const forbidden = (msg = 'No tienes permiso') => new HttpError(403, msg);
const conflict = (msg) => new HttpError(409, msg);

const otherLang = (l) => (l === 'es' ? 'en' : 'es');
const num = (v, def = 0) => (v === undefined || v === null || v === '' || Number.isNaN(Number(v)) ? def : Number(v));
const strArr = (v) => (Array.isArray(v) ? v.map((x) => String(x).trim()).filter(Boolean).slice(0, 20) : []);
const str = (v, max = 500) => String(v ?? '').trim().slice(0, max);

const MIN = 60 * 1000;
const HOUR = 60 * MIN;

/** Ejecuta `fn(client)` dentro de una transacción. */
async function tx(pool, fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query('COMMIT');
    return out;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { h, HttpError, bad, notFound, forbidden, conflict, otherLang, num, strArr, str, MIN, HOUR, tx };
