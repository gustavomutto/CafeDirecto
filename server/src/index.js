// API de CaféDirecto (Express + PostgreSQL). Pensada para desplegarse en Railway.
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const bcrypt = require('bcryptjs');

const { pool, q, one, many, migrate } = require('./db');
const { sign, requireAuth } = require('./auth');
const { translate, both, providerName } = require('./translate');
const S = require('./serialize');

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 6 * 1024 * 1024 } });

// Envuelve rutas async para que los errores lleguen al manejador de errores.
const h = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
const bad = (msg) => new HttpError(400, msg);
const notFound = (msg = 'No encontrado') => new HttpError(404, msg);
const forbidden = (msg = 'No tienes permiso') => new HttpError(403, msg);

const otherLang = (l) => (l === 'es' ? 'en' : 'es');
const num = (v, def = 0) => (v === undefined || v === null || v === '' || Number.isNaN(Number(v)) ? def : Number(v));
const strArr = (v) => (Array.isArray(v) ? v.map((x) => String(x).trim()).filter(Boolean).slice(0, 20) : []);
const str = (v, max = 500) => String(v ?? '').trim().slice(0, max);

// ── Salud ─────────────────────────────────────────────────────────
app.get('/', (req, res) => res.json({ ok: true, app: 'CaféDirecto API', translator: providerName() }));
app.get('/health', h(async (req, res) => {
  await q('SELECT 1');
  res.json({ ok: true });
}));

// ── Imágenes ──────────────────────────────────────────────────────
app.post('/images', requireAuth, upload.single('file'), h(async (req, res) => {
  const f = req.file;
  if (!f) throw bad('Falta el archivo (campo "file")');
  if (!/^image\/(jpeg|png|webp|gif|heic|heif)$/.test(f.mimetype)) throw bad('Solo se aceptan imágenes');
  const r = await one('INSERT INTO images (owner_id, mime, data) VALUES ($1,$2,$3) RETURNING id', [req.user.id, f.mimetype, f.buffer]);
  res.status(201).json({ id: r.id, url: S.img(r.id) });
}));

app.get('/images/:id', h(async (req, res) => {
  const r = await one('SELECT mime, data FROM images WHERE id = $1', [num(req.params.id, -1)]);
  if (!r) throw notFound('Imagen no encontrada');
  res.set('Content-Type', r.mime);
  res.set('Cache-Control', 'public, max-age=31536000, immutable');
  res.send(r.data);
}));

// ── Autenticación ─────────────────────────────────────────────────
app.post('/auth/register', h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  const password = String(req.body.password || '');
  const role = req.body.role;
  const name = str(req.body.name, 120);
  const lang = req.body.lang === 'en' ? 'en' : req.body.lang === 'es' ? 'es' : role === 'buyer' ? 'en' : 'es';
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw bad('Correo inválido');
  if (password.length < 6) throw bad('La contraseña debe tener al menos 6 caracteres');
  if (!['farmer', 'buyer'].includes(role)) throw bad('Rol inválido');
  if (!name) throw bad('Escribe tu nombre');
  if (await one('SELECT 1 FROM users WHERE email = $1', [email])) throw new HttpError(409, 'Ese correo ya está registrado');

  const hash = await bcrypt.hash(password, 10);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const u = (await client.query(
      'INSERT INTO users (email, password_hash, role, name, phone, lang) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [email, hash, role, name, str(req.body.phone, 40), lang],
    )).rows[0];
    if (role === 'farmer') {
      await client.query('INSERT INTO farms (user_id, name, region, municipality) VALUES ($1,$2,$3,$4)', [
        u.id, str(req.body.farmName, 120), str(req.body.region, 80), str(req.body.municipality, 80),
      ]);
    } else {
      await client.query('INSERT INTO buyers (user_id, company, city, country, type) VALUES ($1,$2,$3,$4,$5)', [
        u.id, str(req.body.company, 120), str(req.body.city, 80), str(req.body.country, 80), str(req.body.type, 80),
      ]);
    }
    await client.query('COMMIT');
    res.status(201).json({ token: sign(u), user: S.meUser(u) });
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}));

app.post('/auth/login', h(async (req, res) => {
  const email = str(req.body.email, 200).toLowerCase();
  const u = await one('SELECT * FROM users WHERE email = $1', [email]);
  if (!u || !(await bcrypt.compare(String(req.body.password || ''), u.password_hash))) {
    throw new HttpError(401, 'Correo o contraseña incorrectos');
  }
  res.json({ token: sign(u), user: S.meUser(u) });
}));

// ── Mi cuenta y perfil ────────────────────────────────────────────
async function fullProfile(user) {
  if (user.role === 'farmer') return S.farmProfile(user, await one('SELECT * FROM farms WHERE user_id = $1', [user.id]));
  return S.buyerProfile(user, await one('SELECT * FROM buyers WHERE user_id = $1', [user.id]));
}

app.get('/me', requireAuth, h(async (req, res) => {
  res.json({ user: S.meUser(req.user), profile: await fullProfile(req.user) });
}));

app.put('/me', requireAuth, h(async (req, res) => {
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

app.put('/me/profile', requireAuth, h(async (req, res) => {
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
app.get('/users/:id', requireAuth, h(async (req, res) => {
  const u = await one('SELECT * FROM users WHERE id = $1', [num(req.params.id, -1)]);
  if (!u) throw notFound('Usuario no encontrado');
  const out = { user: S.publicUser(u), profile: await fullProfile(u) };
  if (u.role === 'farmer') {
    out.lots = (await many(`${S.LOT_SELECT} WHERE l.farmer_id = $1 AND l.active ORDER BY l.created_at DESC`, [u.id])).map(S.lot);
  }
  res.json(out);
}));

// ── Lotes ─────────────────────────────────────────────────────────
app.get('/lots', requireAuth, h(async (req, res) => {
  const where = ['l.active'];
  const params = [];
  const p = (v) => { params.push(v); return `$${params.length}`; };
  const qs = req.query;
  if (qs.farmerId) where.push(`l.farmer_id = ${p(num(qs.farmerId, -1))}`);
  else where.push('l.sacks > 0');
  const list = (v) => String(v || '').split(',').map((s) => s.trim()).filter(Boolean);
  if (list(qs.region).length) where.push(`f.region = ANY(${p(list(qs.region))})`);
  if (list(qs.process).length) where.push(`l.process = ANY(${p(list(qs.process))})`);
  if (list(qs.variety).length) where.push(`l.variety = ANY(${p(list(qs.variety))})`);
  if (qs.minSca) where.push(`l.sca >= ${p(num(qs.minSca))}`);
  if (qs.minAlt) where.push(`COALESCE(f.altitude,0) >= ${p(num(qs.minAlt))}`);
  if (qs.q) {
    const t = `%${str(qs.q, 80)}%`;
    where.push(`(l.name ILIKE ${p(t)} OR l.variety ILIKE $${params.length} OR f.name ILIKE $${params.length}
                 OR u.name ILIKE $${params.length} OR f.region ILIKE $${params.length} OR f.municipality ILIKE $${params.length}
                 OR array_to_string(l.notes, ' ') ILIKE $${params.length})`);
  }
  const rows = await many(`${S.LOT_SELECT} WHERE ${where.join(' AND ')} ORDER BY l.created_at DESC LIMIT 200`, params);
  res.json(rows.map(S.lot));
}));

app.get('/lots/:id', requireAuth, h(async (req, res) => {
  const r = await one(`${S.LOT_SELECT} WHERE l.id = $1`, [num(req.params.id, -1)]);
  if (!r) throw notFound('Lote no encontrado');
  const farm = await one('SELECT certifications FROM farms WHERE user_id = $1', [r.farmer_id]);
  res.json({ ...S.lot(r), certifications: (farm?.certifications || '').split('\n').map((s) => s.trim()).filter(Boolean) });
}));

function lotFields(b) {
  const sca = num(b.sca);
  if (!str(b.variety)) throw bad('Elige la variedad');
  if (!['lavado', 'honey', 'natural'].includes(b.process)) throw bad('Proceso inválido');
  if (sca < 80) throw bad('CaféDirecto recibe cafés de 80 puntos o más');
  if (num(b.priceLb) <= 0) throw bad('El precio debe ser mayor que 0');
  return [
    str(b.name, 120) || `Lote ${str(b.variety, 60)}`, str(b.variety, 60), b.process, Math.max(0, Math.round(num(b.sacks))),
    sca, num(b.priceLb), b.priceCarga ? Math.round(num(b.priceCarga)) : null, strArr(b.notes).slice(0, 6),
    str(b.harvest, 80), b.photoId ? num(b.photoId) : null,
  ];
}

app.post('/lots', requireAuth, h(async (req, res) => {
  if (req.user.role !== 'farmer') throw forbidden('Solo los caficultores publican lotes');
  const r = await one(
    `INSERT INTO lots (farmer_id, name, variety, process, sacks, sca, price_lb, price_carga, notes, harvest, photo_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
    [req.user.id, ...lotFields(req.body)],
  );
  res.status(201).json(S.lot(await one(`${S.LOT_SELECT} WHERE l.id = $1`, [r.id])));
}));

app.put('/lots/:id', requireAuth, h(async (req, res) => {
  const id = num(req.params.id, -1);
  const lot = await one('SELECT * FROM lots WHERE id = $1', [id]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden();
  await q(
    `UPDATE lots SET name=$2, variety=$3, process=$4, sacks=$5, sca=$6, price_lb=$7, price_carga=$8, notes=$9, harvest=$10, photo_id=$11
      WHERE id=$1`,
    [id, ...lotFields(req.body)],
  );
  res.json(S.lot(await one(`${S.LOT_SELECT} WHERE l.id = $1`, [id])));
}));

app.delete('/lots/:id', requireAuth, h(async (req, res) => {
  const lot = await one('SELECT * FROM lots WHERE id = $1', [num(req.params.id, -1)]);
  if (!lot) throw notFound('Lote no encontrado');
  if (lot.farmer_id !== req.user.id) throw forbidden();
  await q('UPDATE lots SET active = false WHERE id = $1', [lot.id]);
  res.json({ ok: true });
}));

// ── Conversaciones ────────────────────────────────────────────────
async function myConv(req, id) {
  const c = await one('SELECT * FROM conversations WHERE id = $1', [num(id, -1)]);
  if (!c) throw notFound('Conversación no encontrada');
  if (c.farmer_id !== req.user.id && c.buyer_id !== req.user.id) throw forbidden();
  return c;
}

async function otherOf(c, me) {
  const otherId = c.farmer_id === me.id ? c.buyer_id : c.farmer_id;
  const u = await one(
    `SELECT u.*, f.name AS farm_name, f.region, b.company, b.city, b.country
       FROM users u LEFT JOIN farms f ON f.user_id=u.id LEFT JOIN buyers b ON b.user_id=u.id WHERE u.id=$1`,
    [otherId],
  );
  return {
    ...S.publicUser(u),
    sub: u.role === 'farmer' ? [u.farm_name, u.region].filter(Boolean).join(' · ') : [u.company, u.city, u.country].filter(Boolean).join(' · '),
  };
}

async function convSummary(c, me) {
  const lastRead = c.farmer_id === me.id ? c.farmer_last_read : c.buyer_last_read;
  const last = await one(
    `SELECT * FROM messages WHERE conversation_id = $1 AND type <> 'system' ORDER BY id DESC LIMIT 1`, [c.id],
  ) || await one('SELECT * FROM messages WHERE conversation_id = $1 ORDER BY id DESC LIMIT 1', [c.id]);
  const unread = await one(
    'SELECT COUNT(*)::int AS n FROM messages WHERE conversation_id = $1 AND id > $2 AND (sender_id IS NULL OR sender_id <> $3)',
    [c.id, lastRead, me.id],
  );
  const lot = c.lot_id ? await one(`${S.LOT_SELECT} WHERE l.id = $1`, [c.lot_id]) : null;
  return {
    id: c.id,
    farmerId: c.farmer_id,
    buyerId: c.buyer_id,
    lot: lot ? S.lot(lot) : null,
    other: await otherOf(c, me),
    last: last ? S.message(last, c) : null,
    unread: unread.n,
    updatedAt: S.ms(c.updated_at),
  };
}

app.get('/conversations', requireAuth, h(async (req, res) => {
  const rows = await many(
    'SELECT * FROM conversations WHERE farmer_id = $1 OR buyer_id = $1 ORDER BY updated_at DESC LIMIT 100', [req.user.id],
  );
  res.json(await Promise.all(rows.map((c) => convSummary(c, req.user))));
}));

app.get('/unread', requireAuth, h(async (req, res) => {
  const r = await one(
    `SELECT COUNT(*)::int AS n FROM messages m JOIN conversations c ON c.id = m.conversation_id
      WHERE (c.farmer_id = $1 AND m.id > c.farmer_last_read OR c.buyer_id = $1 AND m.id > c.buyer_last_read)
        AND (m.sender_id IS NULL OR m.sender_id <> $1)`,
    [req.user.id],
  );
  res.json({ unread: r.n });
}));

app.post('/conversations', requireAuth, h(async (req, res) => {
  const other = await one('SELECT * FROM users WHERE id = $1', [num(req.body.userId, -1)]);
  if (!other) throw notFound('Usuario no encontrado');
  if (other.role === req.user.role) throw bad('Solo se puede chatear entre caficultor y comprador');
  const farmerId = req.user.role === 'farmer' ? req.user.id : other.id;
  const buyerId = req.user.role === 'buyer' ? req.user.id : other.id;
  const lotId = req.body.lotId ? num(req.body.lotId) : null;
  let c = await one('SELECT * FROM conversations WHERE farmer_id = $1 AND buyer_id = $2', [farmerId, buyerId]);
  if (!c) {
    c = await one('INSERT INTO conversations (farmer_id, buyer_id, lot_id) VALUES ($1,$2,$3) RETURNING *', [farmerId, buyerId, lotId]);
    await q(
      `INSERT INTO messages (conversation_id, type, sys_es, sys_en) VALUES ($1,'system',$2,$3)`,
      [c.id, 'Conversación iniciada · traducción automática activa', 'Conversation started · auto-translation on'],
    );
  } else if (lotId) {
    c = await one('UPDATE conversations SET lot_id = $2 WHERE id = $1 RETURNING *', [c.id, lotId]);
  }
  res.status(201).json(await convSummary(c, req.user));
}));

app.get('/conversations/:id', requireAuth, h(async (req, res) => {
  res.json(await convSummary(await myConv(req, req.params.id), req.user));
}));

app.get('/conversations/:id/messages', requireAuth, h(async (req, res) => {
  const c = await myConv(req, req.params.id);
  const after = num(req.query.after, 0);
  const rows = await many(
    'SELECT * FROM messages WHERE conversation_id = $1 AND id > $2 ORDER BY id ASC LIMIT 300', [c.id, after],
  );
  res.json(rows.map((m) => S.message(m, c)));
}));

/** Inserta un mensaje y actualiza la conversación. */
async function insertMessage(client, c, fields) {
  const cols = Object.keys(fields);
  const vals = Object.values(fields);
  const m = (await client.query(
    `INSERT INTO messages (conversation_id, ${cols.join(',')}) VALUES ($1, ${cols.map((_, i) => `$${i + 2}`).join(',')}) RETURNING *`,
    [c.id, ...vals],
  )).rows[0];
  await client.query('UPDATE conversations SET updated_at = now() WHERE id = $1', [c.id]);
  return m;
}

app.post('/conversations/:id/messages', requireAuth, h(async (req, res) => {
  const c = await myConv(req, req.params.id);
  const b = req.body;
  const type = b.type === 'photo' ? 'photo' : 'text';
  const text = str(b.text, 4000);
  if (type === 'text' && !text) throw bad('Mensaje vacío');
  if (type === 'photo' && !b.photoId) throw bad('Falta la foto');
  const lang = ['es', 'en'].includes(b.lang) ? b.lang : req.user.lang;
  const otherId = c.farmer_id === req.user.id ? c.buyer_id : c.farmer_id;
  const other = await one('SELECT lang FROM users WHERE id = $1', [otherId]);
  // Siempre se traduce al otro idioma de la app (ES ⇄ EN), así ambos ven las dos versiones.
  const target = other && other.lang !== lang ? other.lang : otherLang(lang);
  const translation = text ? await translate(text, lang, target) : null;
  const m = await insertMessage(pool, c, {
    sender_id: req.user.id,
    type,
    text: text || null,
    lang,
    translation,
    translated_to: translation ? target : null,
    via_voice: !!b.viaVoice,
    photo_id: type === 'photo' ? num(b.photoId) : null,
  });
  // quien envía ya leyó hasta aquí
  await markRead(c, req.user.id, m.id);
  res.status(201).json(S.message(m, c));
}));

async function markRead(c, userId, lastId) {
  const col = c.farmer_id === userId ? 'farmer_last_read' : 'buyer_last_read';
  await q(`UPDATE conversations SET ${col} = GREATEST(${col}, $2) WHERE id = $1`, [c.id, lastId]);
}

app.post('/conversations/:id/read', requireAuth, h(async (req, res) => {
  const c = await myConv(req, req.params.id);
  const last = await one('SELECT COALESCE(MAX(id),0)::int AS id FROM messages WHERE conversation_id = $1', [c.id]);
  await markRead(c, req.user.id, num(req.body.lastId, last.id) || last.id);
  res.json({ ok: true });
}));

// ── Cotizaciones ──────────────────────────────────────────────────
const fmtPrice = (p) => Number(p).toFixed(2);

app.post('/conversations/:id/quotes', requireAuth, h(async (req, res) => {
  const c = await myConv(req, req.params.id);
  const b = req.body;
  const lot = await one('SELECT * FROM lots WHERE id = $1 AND farmer_id = $2', [num(b.lotId, -1), c.farmer_id]);
  if (!lot) throw bad('El lote no pertenece a esta finca');
  const sacks = Math.round(num(b.sacks));
  const priceLb = num(b.priceLb);
  if (sacks < 1 || sacks > lot.sacks) throw bad(`Cantidad inválida (disponible: ${lot.sacks} sacos)`);
  if (priceLb <= 0) throw bad('Precio inválido');
  const role = req.user.role;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // una cotización nueva reemplaza a las que sigan abiertas
    await client.query(
      `UPDATE messages SET quote = jsonb_set(quote, '{status}', '"superseded"')
        WHERE conversation_id = $1 AND type = 'quote' AND quote->>'status' IN ('open','accepted')`,
      [c.id],
    );
    const quote = {
      lotId: lot.id, lotName: lot.name, variety: lot.variety, process: lot.process,
      priceLb, sacks, incoterm: str(b.incoterm, 60) || 'FOB Buenaventura',
      history: [{ by: role, priceLb, sacks, at: Date.now() }],
      lastBy: role, status: 'open', acceptedBy: null, agreementId: null,
    };
    const m = await insertMessage(client, c, { sender_id: req.user.id, type: 'quote', quote });
    await client.query('UPDATE conversations SET lot_id = $2 WHERE id = $1', [c.id, lot.id]);
    await client.query('COMMIT');
    await markRead(c, req.user.id, m.id);
    res.status(201).json(S.message(m, c));
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}));

/**
 * Responde una cotización.
 * action: 'counter' (contraoferta) | 'accept' (acepta la última oferta) | 'confirm' (segunda confirmación → acuerdo)
 */
app.post('/messages/:id/quote', requireAuth, h(async (req, res) => {
  const action = req.body.action;
  if (!['counter', 'accept', 'confirm'].includes(action)) throw bad('Acción inválida');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const qm = (await client.query('SELECT * FROM messages WHERE id = $1 FOR UPDATE', [num(req.params.id, -1)])).rows[0];
    if (!qm || qm.type !== 'quote') throw notFound('Cotización no encontrada');
    const c = await myConv(req, qm.conversation_id);
    const role = req.user.role;
    const qt = qm.quote;
    const out = [];

    if (action === 'counter') {
      if (qt.status !== 'open' || qt.lastBy === role) throw bad('No puedes contraofertar esta cotización');
      const priceLb = num(req.body.priceLb);
      const sacks = Math.round(num(req.body.sacks, qt.sacks));
      if (priceLb <= 0 || sacks < 1) throw bad('Precio o cantidad inválidos');
      await client.query(`UPDATE messages SET quote = jsonb_set(quote, '{status}', '"superseded"') WHERE id = $1`, [qm.id]);
      const quote = {
        ...qt, priceLb, sacks,
        history: [...qt.history, { by: role, priceLb, sacks, at: Date.now() }],
        lastBy: role, status: 'open', acceptedBy: null,
      };
      out.push(await insertMessage(client, c, { sender_id: req.user.id, type: 'quote', quote }));
    } else if (action === 'accept') {
      if (qt.status !== 'open' || qt.lastBy === role) throw bad('No puedes aceptar esta cotización');
      await client.query(
        `UPDATE messages SET quote = quote || jsonb_build_object('status','accepted','acceptedBy',$2::text) WHERE id = $1`,
        [qm.id, role],
      );
      const f = role === 'farmer';
      out.push(await insertMessage(client, c, {
        type: 'system',
        sys_es: `${f ? 'El caficultor' : 'El comprador'} aceptó US$ ${fmtPrice(qt.priceLb)}/lb · falta la confirmación ${f ? 'del comprador' : 'del caficultor'}`,
        sys_en: `${f ? 'The farmer' : 'The buyer'} accepted US$ ${fmtPrice(qt.priceLb)}/lb · waiting for ${f ? 'the buyer' : 'the farmer'} to confirm`,
      }));
    } else {
      if (qt.status !== 'accepted' || qt.acceptedBy === role) throw bad('Esta cotización no está lista para confirmar');
      const lot = (await client.query('SELECT * FROM lots WHERE id = $1 FOR UPDATE', [qt.lotId])).rows[0];
      if (lot && lot.sacks < qt.sacks) throw bad(`El lote ya solo tiene ${lot.sacks} sacos disponibles`);
      const now = Date.now();
      const firstAt = qt.history[0]?.at || now;
      const ag = (await client.query(
        `INSERT INTO agreements (code, conversation_id, farmer_id, buyer_id, lot_id, lot_name, variety, process, sca, price_lb, sacks, incoterm, status, history)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,1,$13) RETURNING *`,
        [
          `tmp-${now}-${Math.random()}`, c.id, c.farmer_id, c.buyer_id, qt.lotId, lot?.name || qt.lotName || '',
          lot?.variety || qt.variety || '', lot?.process || qt.process || 'lavado', lot?.sca || 0,
          qt.priceLb, qt.sacks, qt.incoterm, JSON.stringify([firstAt, now]),
        ],
      )).rows[0];
      const code = `CD-${new Date().getFullYear()}-${String(ag.id).padStart(4, '0')}`;
      await client.query('UPDATE agreements SET code = $2 WHERE id = $1', [ag.id, code]);
      await client.query(
        `UPDATE messages SET quote = quote || jsonb_build_object('status','agreed','agreementId',$2::int) WHERE id = $1`,
        [qm.id, ag.id],
      );
      if (lot) await client.query('UPDATE lots SET sacks = GREATEST(0, sacks - $2) WHERE id = $1', [lot.id, qt.sacks]);
      out.push(await insertMessage(client, c, { type: 'agreement', agreement_id: ag.id }));
    }
    await client.query('COMMIT');
    for (const m of out) await markRead(c, req.user.id, m.id);
    res.json({ ok: true, messages: out.map((m) => S.message(m, c)) });
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}));

// ── Acuerdos ──────────────────────────────────────────────────────
async function myAgreement(req, id) {
  const a = await one('SELECT * FROM agreements WHERE id = $1', [num(id, -1)]);
  if (!a) throw notFound('Acuerdo no encontrado');
  if (a.farmer_id !== req.user.id && a.buyer_id !== req.user.id) throw forbidden();
  return a;
}

app.get('/agreements', requireAuth, h(async (req, res) => {
  const rows = await many(
    'SELECT * FROM agreements WHERE farmer_id = $1 OR buyer_id = $1 ORDER BY created_at DESC', [req.user.id],
  );
  res.json(await Promise.all(rows.map(S.agreement)));
}));

app.get('/agreements/:id', requireAuth, h(async (req, res) => {
  res.json(await S.agreement(await myAgreement(req, req.params.id)));
}));

// Avanza el estado: confirmado → enviado → entregado (lo puede marcar cualquiera de las dos partes)
app.post('/agreements/:id/advance', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  if (a.status >= 3) throw bad('El acuerdo ya fue entregado');
  const next = a.status + 1;
  const history = [...(a.history || [])];
  while (history.length <= next) history.push(0);
  history[next] = Date.now();
  const updated = await one('UPDATE agreements SET status = $2, history = $3 WHERE id = $1 RETURNING *', [a.id, next, JSON.stringify(history)]);
  const texts = {
    2: ['Café despachado 🚢 · en camino', 'Coffee shipped 🚢 · on its way'],
    3: ['Café entregado ✅ · ya pueden calificarse', 'Coffee delivered ✅ · you can now rate each other'],
  };
  if (a.conversation_id && texts[next]) {
    const c = await one('SELECT * FROM conversations WHERE id = $1', [a.conversation_id]);
    if (c) await insertMessage(pool, c, { type: 'system', sys_es: texts[next][0], sys_en: texts[next][1] });
  }
  res.json(await S.agreement(updated));
}));

app.post('/agreements/:id/rate', requireAuth, h(async (req, res) => {
  const a = await myAgreement(req, req.params.id);
  if (a.status < 3) throw bad('Solo se califica después de la entrega');
  const stars = Math.round(num(req.body.stars));
  if (stars < 1 || stars > 5) throw bad('Elige de 1 a 5 estrellas');
  if (await one('SELECT 1 FROM ratings WHERE agreement_id = $1 AND by_user_id = $2', [a.id, req.user.id])) {
    throw new HttpError(409, 'Ya calificaste este acuerdo');
  }
  const comment = await both(req.body.comment, req.user.lang);
  await q(
    'INSERT INTO ratings (agreement_id, by_user_id, stars, tags, comment_es, comment_en) VALUES ($1,$2,$3,$4,$5,$6)',
    [a.id, req.user.id, stars, strArr(req.body.tags), comment.es || null, comment.en || null],
  );
  res.status(201).json(await S.agreement(a));
}));

// Traducir un texto suelto (útil para vista previa)
app.post('/translate', requireAuth, h(async (req, res) => {
  const from = req.body.from === 'en' ? 'en' : 'es';
  const to = otherLang(from);
  res.json({ text: await translate(str(req.body.text, 4000), from, to), from, to });
}));

// ── Errores ───────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) return res.status(400).json({ error: 'La imagen es muy grande (máx. 6 MB)' });
  const status = err.status || 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: status >= 500 ? 'Error del servidor' : err.message });
});

const PORT = process.env.PORT || 3000;
migrate()
  .then(() => app.listen(PORT, () => console.log(`CaféDirecto API escuchando en el puerto ${PORT} · traductor: ${providerName()}`)))
  .catch((e) => {
    console.error('No se pudo preparar la base de datos:', e);
    process.exit(1);
  });
