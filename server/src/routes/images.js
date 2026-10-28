// Fotos: se guardan dentro de PostgreSQL (suficiente para el proyecto).
const express = require('express');
const multer = require('multer');

const { one } = require('../db');
const { requireAuth } = require('../auth');
const S = require('../serialize');
const { h, bad, notFound, num } = require('../lib/http');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 6 * 1024 * 1024 } });
const r = express.Router();

r.post('/images', requireAuth, upload.single('file'), h(async (req, res) => {
  const f = req.file;
  if (!f) throw bad('Falta el archivo (campo "file")');
  if (!/^image\/(jpeg|png|webp|gif|heic|heif)$/.test(f.mimetype)) throw bad('Solo se aceptan imágenes');
  const row = await one('INSERT INTO images (owner_id, mime, data) VALUES ($1,$2,$3) RETURNING id', [req.user.id, f.mimetype, f.buffer]);
  res.status(201).json({ id: row.id, url: S.img(row.id) });
}));

r.get('/images/:id', h(async (req, res) => {
  const row = await one('SELECT mime, data FROM images WHERE id = $1', [num(req.params.id, -1)]);
  if (!row) throw notFound('Imagen no encontrada');
  res.set('Content-Type', row.mime);
  res.set('Cache-Control', 'public, max-age=31536000, immutable');
  res.send(row.data);
}));

module.exports = r;
