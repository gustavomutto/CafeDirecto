// Middlewares transversales: cabeceras de seguridad, identificador de petición y registro.
const crypto = require('crypto');

/** Cabeceras recomendadas para una API (sin dependencias externas). */
function securityHeaders(req, res, next) {
  res.set({
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Cross-Origin-Resource-Policy': 'cross-origin', // las fotos se muestran desde la app web
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  });
  next();
}

/**
 * Registra cada petición en una línea: método, ruta, estado, tiempo y usuario.
 * No registra cuerpos, tokens ni la firma de las fotos (datos sensibles).
 */
function requestLog(req, res, next) {
  if (req.path === '/health') return next();
  const start = process.hrtime.bigint();
  req.id = req.get('X-Request-Id') || crypto.randomUUID().slice(0, 8);
  res.set('X-Request-Id', req.id);
  res.on('finish', () => {
    if (req.path.startsWith('/images/') && res.statusCode < 400) return; // demasiadas, sin valor
    const ms = Number(process.hrtime.bigint() - start) / 1e6;
    const who = req.user ? ` u=${req.user.id}` : '';
    console.log(`${req.method} ${req.path} ${res.statusCode} ${ms.toFixed(0)}ms${who} id=${req.id}`);
  });
  next();
}

/** Orígenes permitidos (CORS). Sin CORS_ORIGINS se permite cualquiera (la app móvil no envía Origin). */
function corsOptions() {
  const list = (process.env.CORS_ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);
  if (!list.length) return { origin: true };
  return { origin: (origin, cb) => cb(null, !origin || list.includes(origin)) };
}

module.exports = { securityHeaders, requestLog, corsOptions };
