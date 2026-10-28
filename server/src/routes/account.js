// Mi cuenta, mi perfil (finca o empresa) y perfiles públicos.
const express = require('express');
const bcrypt = require('bcryptjs');

const { pool, q, one, many } = require('../db');
const { requireAuth } = require('../auth');
const { both } = require('../translate');
const { limit } = require('../ratelimit');
const S = require('../serialize');
const { h, forbidden, notFound, num, str, strArr, MIN, tx } = require('../lib/http');

const r = express.Router();

async function fullProfile(user) {
  if (user.role === 'farmer') return S.farmProfile(user, await one('SELECT * FROM farms WHERE user_id = $1', [user.id]));
  return S.buyerProfile(user, await one('SELECT * FROM buyers WHERE user_id = $1', [user.id]));
}

r.get('/me', requireAuth, h(async (req, res) => {
  res.json({ user: S.meUser(req.user), profile: await fullProfile(req.user) });
}));

r.put('/me', requireAuth, h(async (req, res) => {
  const b = req.body;
  const u = await one(
    `UPDATE users SET name = COALESCE($2, name), phone = COALESCE($3, phone), lang = COALESCE($4, lang),
            photo_id = CASE WHEN $5::boolean THEN $6::int ELSE photo_id END
      WHERE id = $1 RETURNING *`,
    [
      req.user.id,
      b.name !== undefined ? str(b.name, 120) || null : null,
      b.phone !== undefined ? str(b.phone, 40) : null,
      ['es', 'en'].includes(b.lang) ? b.lang : null,
      b.photoId !== undefined,
      b.photoId ? num(b.photoId) : null,
    ],
  );
  res.json({ user: S.meUser(u), profile: await fullProfile(u) });
}));

// Eliminar la cuenta (lo exige Google Play). Pide la contraseña para confirmar.
// Se borran perfil, lotes, conversaciones, fotos, ofertas abiertas y avisos. Si la persona tiene acuerdos
// registrados, esos acuerdos se conservan para la otra parte y la cuenta queda anónima ("Cuenta eliminada").
r.delete('/me', limit('delete-me', 5, 15 * MIN), requireAuth, h(async (req, res) => {
  if (!(await bcrypt.compare(String(req.body?.password || ''), req.user.password_hash))) {
    throw forbidden('La contraseña no es correcta');
  }
  const uid = req.user.id;
  const keepRecord = !!(await one('SELECT 1 FROM agreements WHERE farmer_id = $1 OR buyer_id = $1 LIMIT 1', [uid]));
  await tx(pool, async (client) => {
    await client.query('DELETE FROM conversations WHERE farmer_id = $1 OR buyer_id = $1', [uid]);
    await client.query(
      `DELETE FROM bids WHERE buyer_id = $1 AND status = 'active'
          AND auction_id IN (SELECT id FROM auctions WHERE status = 'open')`, [uid],
    );
    // borrar los lotes también borra sus subastas y ofertas (ON DELETE CASCADE)
    await client.query('DELETE FROM lots WHERE farmer_id = $1', [uid]);
    await client.query('DELETE FROM lot_views WHERE buyer_id = $1', [uid]);
    await client.query('DELETE FROM notifications WHERE user_id = $1', [uid]);
    await client.query('DELETE FROM password_resets WHERE user_id = $1', [uid]);
    if (keepRecord) {
      await client.query('DELETE FROM farms WHERE user_id = $1', [uid]);
      await client.query('DELETE FROM buyers WHERE user_id = $1', [uid]);
      await client.query(
        `UPDATE users SET email = 'deleted-' || id || '@cuenta-eliminada.invalid', password_hash = '!',
                name = 'Cuenta eliminada', phone = NULL, photo_id = NULL,
                deleted_at = now(), token_version = token_version + 1
          WHERE id = $1`,
        [uid],
      );
    } else {
      await client.query('DELETE FROM users WHERE id = $1', [uid]);
    }
    await client.query('DELETE FROM images WHERE owner_id = $1', [uid]);
  });
  res.json({ ok: true });
}));

r.put('/me/profile', requireAuth, h(async (req, res) => {
  const b = req.body;
  const u = req.user;
  const lang = ['es', 'en'].includes(b.lang) ? b.lang : u.lang;
  if (u.role === 'farmer') {
    const story = await both(b.story, lang);
    const quote = await both(b.quote, lang);
    await q(
      `UPDATE farms SET name=$2, region=$3, municipality=$4, altitude=$5, hectares=$6, varieties=$7, processes=$8,
              sca=$9, notes=$10, since=$11, story_es=$12, story_en=$13, quote_es=$14, quote_en=$15,
              certifications=$16, cover_id=$17, gallery=$18
        WHERE user_id=$1`,
      [
        u.id, str(b.name, 120), str(b.region, 80), str(b.municipality, 80), Math.round(num(b.altitude)), num(b.hectares),
        strArr(b.varieties), strArr(b.processes), num(b.sca), strArr(b.notes), b.since ? Math.round(num(b.since)) : null,
        story.es, story.en, quote.es, quote.en, str(b.certifications, 2000),
        b.coverId ? num(b.coverId) : null, (Array.isArray(b.gallery) ? b.gallery : []).map((x) => num(x)).filter((x) => x > 0).slice(0, 12),
      ],
    );
  } else {
    const about = await both(b.about, lang);
    const looking = await both(b.looking, lang);
    await q(
      `UPDATE buyers SET company=$2, city=$3, country=$4, type=$5, volume=$6, since=$7,
              about_es=$8, about_en=$9, looking_es=$10, looking_en=$11, cover_id=$12
        WHERE user_id=$1`,
      [
        u.id, str(b.company, 120), str(b.city, 80), str(b.country, 80), str(b.type, 80), str(b.volume, 80),
        b.since ? Math.round(num(b.since)) : null, about.es, about.en, looking.es, looking.en, b.coverId ? num(b.coverId) : null,
      ],
    );
  }
  res.json({ user: S.meUser(u), profile: await fullProfile(u) });
}));

// Perfil público de cualquier usuario (finca o comprador)
r.get('/users/:id', requireAuth, h(async (req, res) => {
  const u = await one('SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL', [num(req.params.id, -1)]);
  if (!u) throw notFound('Usuario no encontrado');
  const out = { user: S.publicUser(u), profile: await fullProfile(u) };
  if (u.role === 'farmer') {
    out.lots = (await many(`${S.LOT_SELECT} WHERE l.farmer_id = $1 AND l.active ORDER BY l.created_at DESC`, [u.id])).map(S.lot);
  }
  res.json(out);
}));

module.exports = r;
