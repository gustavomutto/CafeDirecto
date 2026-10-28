// Autenticación con JWT. El token va en el encabezado: Authorization: Bearer <token>
const jwt = require('jsonwebtoken');
const { one } = require('./db');
const { isProduction, JWT_SECRET } = require('./lib/secrets');

const ALGORITHM = 'HS256';

// `v` es la versión del token: sube al cambiar la contraseña y así se cierran las sesiones anteriores.
function sign(user) {
  return jwt.sign({ uid: user.id, v: user.token_version || 0 }, JWT_SECRET, { expiresIn: '90d', algorithm: ALGORITHM });
}

const expired = (res) => res.status(401).json({ error: 'Sesión vencida, vuelve a entrar' });

async function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Inicia sesión' });

  // 1) El token: si es falso o venció → 401.
  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET, { algorithms: [ALGORITHM] });
  } catch {
    return expired(res);
  }
  // 2) El usuario: un fallo de la base es un error del servidor (500), NO una sesión vencida;
  //    si respondiéramos 401 la app cerraría la sesión de todos por una caída momentánea.
  try {
    const user = await one('SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL', [payload.uid]);
    if (!user || (payload.v || 0) !== (user.token_version || 0)) return expired(res);
    req.user = user;
    next();
  } catch (e) {
    next(e);
  }
}

module.exports = { sign, requireAuth, isProduction };
