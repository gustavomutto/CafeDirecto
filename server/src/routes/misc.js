// Salud del servicio y traducción suelta.
const express = require('express');

const { q } = require('../db');
const { requireAuth } = require('../auth');
const { translate, providerName } = require('../translate');
const { limit } = require('../ratelimit');
const { h, str, otherLang, MIN } = require('../lib/http');
const { privacyHtml } = require('../lib/privacy');
const { regions } = require('../lib/catalog');

const r = express.Router();

r.get('/', (req, res) => res.json({ ok: true, app: 'CaféDirecto API', version: 3, translator: providerName() }));

// Política de privacidad y cómo eliminar la cuenta (URL para Google Play).
r.get(['/privacy', '/privacidad'], (req, res) => {
  res.set('Cache-Control', 'public, max-age=3600');
  res.type('html').send(privacyHtml());
});
// Catálogos para la app (regiones cafeteras). Público y con caché corta: un cambio se ve en minutos.
r.get('/catalog', (req, res) => {
  res.set('Cache-Control', 'public, max-age=300');
  res.json({ regions: regions() });
});

r.get('/health', h(async (req, res) => {
  await q('SELECT 1');
  res.json({ ok: true });
}));

// Traducir un texto suelto (útil para vista previa)
r.post('/translate', requireAuth, limit('translate', 60, MIN, (req) => req.user.id), h(async (req, res) => {
  const from = req.body.from === 'en' ? 'en' : 'es';
  const to = otherLang(from);
  res.json({ text: await translate(str(req.body.text, 4000), from, to), from, to });
}));

module.exports = r;
