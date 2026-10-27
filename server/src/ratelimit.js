// Límite de intentos en memoria (sin dependencias). Suficiente para una sola instancia;
// si se escala a varias instancias conviene moverlo a la base de datos o a Redis.
const buckets = new Map();

// Limpia ventanas vencidas cada 10 minutos para no acumular memoria.
setInterval(() => {
  const now = Date.now();
  for (const [k, b] of buckets) if (b.reset <= now) buckets.delete(k);
}, 10 * 60 * 1000).unref();

/** Cuenta un intento para `key`. Devuelve los segundos de espera si se superó el límite, o 0. */
function hit(key, max, windowMs) {
  const now = Date.now();
  let b = buckets.get(key);
  if (!b || b.reset <= now) {
    b = { count: 0, reset: now + windowMs };
    buckets.set(key, b);
  }
  b.count += 1;
  return b.count > max ? Math.ceil((b.reset - now) / 1000) : 0;
}

/**
 * Middleware de Express. `keyOf(req)` arma la clave (por defecto la IP).
 * Ejemplo: limit('login', 10, 15 * 60 * 1000)
 */
function limit(name, max, windowMs, keyOf = (req) => req.ip) {
  return (req, res, next) => {
    const wait = hit(`${name}:${keyOf(req)}`, max, windowMs);
    if (!wait) return next();
    res.set('Retry-After', String(wait));
    const min = Math.max(1, Math.ceil(wait / 60));
    res.status(429).json({ error: `Demasiados intentos. Espera ${min} min e inténtalo de nuevo.` });
  };
}

module.exports = { limit, hit };
