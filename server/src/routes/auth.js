// Registro, inicio de sesión y recuperación de contraseña.
const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const { pool, q, one } = require('../db');
const { sign } = require('../auth');
const { limit, hit } = require('../ratelimit');
const { sendMail } = require('../mail');
const S = require('../serialize');
const { h, HttpError, bad, conflict, str, MIN, HOUR, MIN_PASSWORD, tx } = require('../lib/http');

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// Hash de relleno: si el correo no existe igual se compara, para que el tiempo de respuesta
// no revele qué correos están registrados.
const DUMMY_HASH = bcrypt.hashSync('cafedirecto-relleno', 10);
const weak = (p) => p.length < MIN_PASSWORD || !/[A-Za-zÁÉÍÓÚáéíóúÑñ]/.test(p) || !/\d/.test(p);
const WEAK_MSG = `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres, con letras y números`;
const r = express.Router();

r.post('/auth/register', limit('register', 10, HOUR), h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  const password = String(req.body.password || '');
  const role = req.body.role;
  const name = str(req.body.name, 120);
  const lang = req.body.lang === 'en' ? 'en' : req.body.lang === 'es' ? 'es' : role === 'buyer' ? 'en' : 'es';
  if (!EMAIL_RE.test(email)) throw bad('Correo inválido');
  if (weak(password)) throw bad(WEAK_MSG);
  if (!['farmer', 'buyer'].includes(role)) throw bad('Rol inválido');
  if (!name) throw bad('Escribe tu nombre');
  if (await one('SELECT 1 FROM users WHERE email = $1', [email])) throw conflict('Ese correo ya está registrado');

  const hash = await bcrypt.hash(password, 10);
  const u = await tx(pool, async (client) => {
    const user = (await client.query(
      'INSERT INTO users (email, password_hash, role, name, phone, lang) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [email, hash, role, name, str(req.body.phone, 40), lang],
    )).rows[0];
    if (role === 'farmer') {
      await client.query('INSERT INTO farms (user_id, name, region, municipality) VALUES ($1,$2,$3,$4)', [
        user.id, str(req.body.farmName, 120), str(req.body.region, 80), str(req.body.municipality, 80),
      ]);
    } else {
      await client.query('INSERT INTO buyers (user_id, company, city, country, type) VALUES ($1,$2,$3,$4,$5)', [
        user.id, str(req.body.company, 120), str(req.body.city, 80), str(req.body.country, 80), str(req.body.type, 80),
      ]);
    }
    return user;
  });
  res.status(201).json({ token: sign(u), user: S.meUser(u) });
}));

// Login: 10 intentos por correo y 50 por IP cada 15 minutos (frena a quien intenta adivinar contraseñas).
const loginEmail = (req) => `${req.ip}:${str(req.body.email, 200).toLowerCase()}`;
r.post('/auth/login', limit('login-ip', 50, 15 * MIN), limit('login', 10, 15 * MIN, loginEmail), h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  const u = await one('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [email]);
  const ok = await bcrypt.compare(String(req.body.password || ''), u ? u.password_hash : DUMMY_HASH);
  if (!u || !ok) throw new HttpError(401, 'Correo o contraseña incorrectos');
  res.json({ token: sign(u), user: S.meUser(u) });
}));

// Recuperar contraseña: se envía un código de 6 dígitos por correo (vence en 15 min).
r.post('/auth/forgot', limit('forgot-ip', 10, HOUR), h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  if (!EMAIL_RE.test(email)) throw bad('Correo inválido');
  // La respuesta es la misma exista o no la cuenta, para no revelar qué correos están registrados.
  const generic = { ok: true };
  if (hit(`forgot-email:${email}`, 3, HOUR)) return res.json(generic);
  const u = await one('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [email]);
  if (!u) return res.json(generic);

  const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  await q(
    `INSERT INTO password_resets (user_id, code_hash, expires_at) VALUES ($1, $2, now() + interval '15 minutes')
     ON CONFLICT (user_id) DO UPDATE SET code_hash = EXCLUDED.code_hash, expires_at = EXCLUDED.expires_at, attempts = 0, created_at = now()`,
    [u.id, await bcrypt.hash(code, 10)],
  );
  const es = u.lang === 'es';
  try {
    await sendMail({
      to: u.email,
      subject: es ? `Tu código de CaféDirecto: ${code}` : `Your CaféDirecto code: ${code}`,
      text: es
        ? `Hola, ${u.name}:\n\nTu código para crear una contraseña nueva es: ${code}\n\nVence en 15 minutos. Si no lo pediste, ignora este correo; tu contraseña no cambia.\n\nCaféDirecto`
        : `Hi ${u.name},\n\nYour code to set a new password is: ${code}\n\nIt expires in 15 minutes. If you didn't ask for it, ignore this email; your password stays the same.\n\nCaféDirecto`,
    });
  } catch (e) {
    console.error('No se pudo enviar el correo de recuperación:', e.message);
    throw new HttpError(503, 'No pudimos enviar el correo. Inténtalo más tarde.');
  }
  res.json(generic);
}));

r.post('/auth/reset', limit('reset-ip', 20, 15 * MIN), h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  const code = str(req.body.code, 12).replace(/\s/g, '');
  const password = String(req.body.password || '');
  if (weak(password)) throw bad(WEAK_MSG);
  const invalid = bad('El código no es válido o ya venció. Pide uno nuevo.');
  const u = await one('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [email]);
  const pr = u && (await one('SELECT * FROM password_resets WHERE user_id = $1', [u.id]));
  if (!pr || new Date(pr.expires_at) < new Date() || pr.attempts >= 5) throw invalid;
  if (!(await bcrypt.compare(code, pr.code_hash))) {
    await q('UPDATE password_resets SET attempts = attempts + 1 WHERE user_id = $1', [u.id]);
    throw invalid;
  }
  // Cambia la contraseña y cierra las sesiones abiertas en otros teléfonos.
  const nu = await one(
    'UPDATE users SET password_hash = $2, token_version = token_version + 1 WHERE id = $1 RETURNING *',
    [u.id, await bcrypt.hash(password, 10)],
  );
  await q('DELETE FROM password_resets WHERE user_id = $1', [u.id]);
  res.json({ token: sign(nu), user: S.meUser(nu) });
}));

module.exports = r;
