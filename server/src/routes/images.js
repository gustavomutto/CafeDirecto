// Fotos: se guardan dentro de PostgreSQL. La dirección lleva una firma para que no se puedan adivinar.
const express = require('express');
const multer = require('multer');

const { one } = require('../db');
const { requireAuth } = require('../auth');
const { limit } = require('../ratelimit');
const { validSignature, sniffImage } = require('../lib/media');
const S = require('../serialize');
const { h, bad, notFound, num, HOUR } = require('../lib/http');

const MAX_BYTES = 6 * 1024 * 1024;
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: MAX_BYTES, files: 1 } });
const r = express.Router();

// 60 fotos por hora por usuario (frena el abuso del almacenamiento).
r.post('/images', requireAuth, limit('upload', 60, HOUR, (req) => req.user.id), upload.single('file'), h(async (req, res) => {
  const f = req.file;
  if (!f) throw bad('Falta el archivo (campo "file")');
  const mime = sniffImage(f.buffer);
  if (!mime) throw bad('Solo se aceptan imágenes JPG, PNG, WEBP, GIF o HEIC');
  const row = await one('INSERT INTO images (owner_id, mime, data) VALUES ($1,$2,$3) RETURNING id', [req.user.id, mime, f.buffer]);
  res.status(201).json({ id: row.id, url: S.img(row.id) });
}));

r.get('/images/:id', h(async (req, res) => {
  const id = num(req.params.id, -1);
  if (!validSignature(id, req.query.s)) throw notFound('Imagen no encontrada');
  const row = await one('SELECT mime, data FROM images WHERE id = $1', [id]);
  if (!row) throw notFound('Imagen no encontrada');
  res.set('Content-Type', row.mime);
  res.set('Cache-Control', 'public, max-age=31536000, immutable');
  res.set('X-Content-Type-Options', 'nosniff');
  res.send(row.data);
}));

module.exports = r;
