// Reproduce los hallazgos del servidor contra una API local y dice si siguen abiertos.
// Uso: node security-check.mjs <carpeta server> [http://localhost:3999]
// Solo para la API local de pruebas: crea cuentas de prueba con datos inventados.
import { createRequire } from 'module';
import { randomBytes } from 'crypto';

const serverDir = process.argv[2];
const API = process.argv[3] || 'http://localhost:3999';
const require = createRequire(`${serverDir.replace(/\\/g, '/')}/package.json`);
const jwt = require('jsonwebtoken');

const call = async (method, path, body, token) => {
  const r = await fetch(API + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  let j = null;
  try { j = await r.json(); } catch { /* sin cuerpo */ }
  return { s: r.status, j };
};
const result = (id, open, detail) => console.log(`${id} ${open ? 'VULNERABLE ' : 'CORREGIDO  '} ${detail}`);

const tag = `${Date.now()}${randomBytes(2).toString('hex')}`;
const password = `Prueba${randomBytes(4).toString('hex')}1`;
const reg = await call('POST', '/auth/register', { email: `sec.${tag}@example.test`, password, role: 'farmer', name: 'Prueba Seguridad' });
if (!reg.j?.token) { console.log('No se pudo registrar la cuenta de prueba:', reg.s, reg.j); process.exit(2); }
const me = await call('GET', '/me', null, reg.j.token);
const uid = me.j.user.id;

// H-01: ¿acepta un token firmado con la clave de desarrollo que está publicada en el repositorio?
const forged = jwt.sign({ uid, v: 0 }, 'clave-local-solo-para-desarrollo', { algorithm: 'HS256', expiresIn: '1h' });
const f = await call('GET', '/me', null, forged);
result('H-01', f.s === 200, `token falsificado con la clave pública del repo → HTTP ${f.s}${f.s === 200 ? ` (entra como ${f.j.user.email})` : ''}`);

// H-02: después de cerrar sesión, ¿el token sigue sirviendo?
const login = await call('POST', '/auth/login', { email: `sec.${tag}@example.test`, password });
const token = login.j.token;
const out = await call('POST', '/auth/logout', null, token);
const reuse = await call('GET', '/me', null, token);
const exp = jwt.decode(token)?.exp;
const days = exp ? Math.round((exp * 1000 - Date.now()) / 86400000) : '?';
result('H-02', reuse.s === 200, `cerrar sesión → HTTP ${out.s}; el mismo token después → HTTP ${reuse.s}; vigencia del token: ${days} días`);

console.log(`(cuenta de prueba sec.${tag}@example.test)`);
