// Autenticación con JWT. El token va en el encabezado: Authorization: Bearer <token>
const jwt = require('jsonwebtoken');
const { one } = require('./db');

// En producción (Railway) la clave es obligatoria: con una clave conocida cualquiera podría falsificar sesiones.
const isProduction = process.env.NODE_ENV === 'production' || !!process.env.RAILWAY_ENVIRONMENT || !!process.env.RAILWAY_ENVIRONMENT_NAME;
if (!process.env.JWT_SECRET && isProduction) {
  console.error('Falta la variable JWT_SECRET. En Railway agrégala con un texto largo y aleatorio (48 caracteres o más).');
  process.exit(1);
}
if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
  console.warn('⚠️  JWT_SECRET es corta; usa al menos 32 caracteres aleatorios.');
}
const SECRET = process.env.JWT_SECRET || 'clave-local-solo-para-desarrollo';
if (!process.env.JWT_SECRET) console.warn('⚠️  Usando una clave JWT de desarrollo. No la uses en producción.');

// `v` es la versión del token: sube al cambiar la contraseña y así se cierran las sesiones anteriores.
function sign(user) {
  return jwt.sign({ uid: user.id, v: user.token_version || 0 }, SECRET, { expiresIn: '90d' });
}

async function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Inicia sesión' });
  try {
    const { uid, v } = jwt.verify(token, SECRET);
    const user = await one('SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL', [uid]);
    if (!user || (v || 0) !== (user.token_version || 0)) {
      return res.status(401).json({ error: 'Sesión vencida, vuelve a entrar' });
    }
    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: 'Sesión vencida, vuelve a entrar' });
  }
}

module.exports = { sign, requireAuth, isProduction };
