// Autenticación con JWT. El token va en el encabezado: Authorization: Bearer <token>
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { one, q } = require('./db');
const { isProduction, JWT_SECRET } = require('./lib/secrets');

const ALGORITHM = 'HS256';
// Vigencia de una sesión. Antes eran 90 días sin forma de cerrarla en el servidor (hallazgo H-02).
const SESSION_DAYS = 30;

// Crea una sesión en la base y devuelve su token.
// · `sid` identifica la sesión: "Cerrar sesión" la revoca y ese token deja de servir.
// · `v` es la versión de la cuenta: sube al cambiar la contraseña y cierra todas las sesiones.
async function issueToken(user) {
  const sid = crypto.randomBytes(24).toString('base64url');
  await q(`INSERT INTO sessions (id, user_id, expires_at) VALUES ($1, $2, now() + make_interval(days => $3))`, [sid, user.id, SESSION_DAYS]);
  return jwt.sign({ uid: user.id, v: user.token_version || 0, sid }, JWT_SECRET, { expiresIn: `${SESSION_DAYS}d`, algorithm: ALGORITHM });
}

const expired = (res) => res.status(401).json({ error: 'Sesión vencida, vuelve a entrar' });

async function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Inicia sesión' });

  // 1) El token: si es falso, venció o no trae sesión (tokens viejos sin `sid`) → 401.
  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET, { algorithms: [ALGORITHM] });
  } catch {
    return expired(res);
  }
  if (typeof payload.sid !== 'string') return expired(res);
  // 2) La sesión y el usuario: un fallo de la base es un error del servidor (500), NO una sesión vencida;
  //    si respondiéramos 401 la app cerraría la sesión de todos por una caída momentánea.
  try {
    const user = await one(
      `SELECT u.* FROM users u JOIN sessions s ON s.user_id = u.id
        WHERE u.id = $1 AND s.id = $2 AND s.revoked_at IS NULL AND s.expires_at > now() AND u.deleted_at IS NULL`,
      [payload.uid, payload.sid],
    );
    if (!user || (payload.v || 0) !== (user.token_version || 0)) return expired(res);
    req.user = user;
    req.sessionId = payload.sid;
    next();
  } catch (e) {
    next(e);
  }
}

module.exports = { issueToken, requireAuth, isProduction };
