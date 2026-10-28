// Campanita de avisos: listar, contar y marcar como leídos.
const express = require('express');

const { q, one, many } = require('../db');
const { requireAuth } = require('../auth');
const S = require('../serialize');
const { h, num } = require('../lib/http');

const r = express.Router();

// ?after=ID → solo las nuevas (para el aviso del teléfono) · ?before=ID → paginar hacia atrás
r.get('/notifications', requireAuth, h(async (req, res) => {
  const after = num(req.query.after, 0);
  const before = num(req.query.before, 0);
  const lim = Math.min(100, Math.max(1, num(req.query.limit, 50)));
  const rows = after
    ? await many('SELECT * FROM notifications WHERE user_id = $1 AND id > $2 ORDER BY id ASC LIMIT $3', [req.user.id, after, lim])
    : await many(
      `SELECT * FROM notifications WHERE user_id = $1 AND ($2::int = 0 OR id < $2) ORDER BY id DESC LIMIT $3`,
      [req.user.id, before, lim],
    );
  const unread = (await one('SELECT COUNT(*)::int AS n FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id])).n;
  res.json({ items: rows.map(S.notification), unread });
}));

r.get('/notifications/unread', requireAuth, h(async (req, res) => {
  const row = await one(
    'SELECT COUNT(*) FILTER (WHERE read_at IS NULL)::int AS n, COALESCE(MAX(id),0)::int AS latest FROM notifications WHERE user_id = $1',
    [req.user.id],
  );
  res.json({ unread: row.n, latestId: row.latest });
}));

// { ids: [1,2] } marca esas; { all: true } marca todas
r.post('/notifications/read', requireAuth, h(async (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids.map((x) => num(x, -1)).filter((x) => x > 0) : [];
  if (req.body.all) {
    await q('UPDATE notifications SET read_at = now() WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  } else if (ids.length) {
    await q('UPDATE notifications SET read_at = now() WHERE user_id = $1 AND id = ANY($2) AND read_at IS NULL', [req.user.id, ids]);
  }
  const unread = (await one('SELECT COUNT(*)::int AS n FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id])).n;
  res.json({ ok: true, unread });
}));

module.exports = r;
