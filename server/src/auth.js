// Autenticación con JWT. El token va en el encabezado: Authorization: Bearer <token>
const jwt = require('jsonwebtoken');
const { one } = require('./db');

const SECRET = process.env.JWT_SECRET || 'cambia-esta-clave-en-railway';
if (!process.env.JWT_SECRET) console.warn('⚠️  Define JWT_SECRET en Railway (cualquier texto largo y secreto).');

function sign(user) {
  return jwt.sign({ uid: user.id }, SECRET, { expiresIn: '90d' });
}

async function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Inicia sesión' });
  try {
    const { uid } = jwt.verify(token, SECRET);
    const user = await one('SELECT * FROM users WHERE id = $1', [uid]);
    if (!user) return res.status(401).json({ error: 'Usuario no existe' });
    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: 'Sesión vencida, vuelve a entrar' });
  }
}

module.exports = { sign, requireAuth };
