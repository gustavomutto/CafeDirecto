// Convierte filas de la base de datos en el JSON que consume la app.
const { many, one } = require('./db');
const { mediaPath } = require('./lib/media');

// Dirección firmada de una foto (ver lib/media.js).
const img = (id) => mediaPath(id);
const ms = (d) => (d ? new Date(d).getTime() : 0);

function publicUser(u) {
  if (!u) return null;
  return { id: u.id, role: u.role, name: u.name, lang: u.lang, photo: img(u.photo_id), createdAt: ms(u.created_at) };
}

function meUser(u) {
  return { ...publicUser(u), email: u.email, phone: u.phone || '' };
}

/** Reputación: promedio y número de calificaciones recibidas por un usuario. */
async function ratingOf(userId) {
  const r = await one(
    `SELECT COALESCE(AVG(r.stars),0)::float AS avg, COUNT(*)::int AS count
       FROM ratings r JOIN agreements a ON a.id = r.agreement_id
      WHERE r.by_user_id <> $1 AND (a.farmer_id = $1 OR a.buyer_id = $1)`,
    [userId],
  );
  return { avg: r.avg, count: r.count };
}

async function reviewsOf(userId) {
  const rows = await many(
    `SELECT r.*, u.name AS by_name, u.role AS by_role, f.name AS farm_name, b.company
       FROM ratings r
       JOIN agreements a ON a.id = r.agreement_id
       JOIN users u ON u.id = r.by_user_id
       LEFT JOIN farms f ON f.user_id = u.id
       LEFT JOIN buyers b ON b.user_id = u.id
      WHERE r.by_user_id <> $1 AND (a.farmer_id = $1 OR a.buyer_id = $1)
      ORDER BY r.created_at DESC LIMIT 20`,
    [userId],
  );
  return rows.map((r) => ({
    by: r.by_role === 'farmer' ? (r.farm_name || r.by_name) : (r.company || r.by_name),
    stars: r.stars,
    text: r.comment_es || r.comment_en ? { es: r.comment_es || '', en: r.comment_en || '' } : null,
    verified: true,
  }));
}

async function farmProfile(user, farm) {
  farm = farm || {};
  return {
    userId: user.id,
    producer: user.name,
    producerPhoto: img(user.photo_id),
    lang: user.lang,
    name: farm.name || '',
    region: farm.region || '',
    municipality: farm.municipality || '',
    altitude: farm.altitude || 0,
    hectares: farm.hectares || 0,
    varieties: farm.varieties || [],
    processes: farm.processes || [],
    sca: farm.sca || 0,
    notes: farm.notes || [],
    since: farm.since || null,
    story: { es: farm.story_es || '', en: farm.story_en || '' },
    quote: { es: farm.quote_es || '', en: farm.quote_en || '' },
    certifications: (farm.certifications || '').split('\n').map((s) => s.trim()).filter(Boolean),
    cover: img(farm.cover_id),
    gallery: (farm.gallery || []).map(img),
    rating: await ratingOf(user.id),
    reviews: await reviewsOf(user.id),
  };
}

async function buyerProfile(user, b) {
  b = b || {};
  return {
    userId: user.id,
    contact: user.name,
    contactPhoto: img(user.photo_id),
    lang: user.lang,
    company: b.company || '',
    city: b.city || '',
    country: b.country || '',
    type: b.type || '',
    volume: b.volume || '',
    since: b.since || null,
    about: { es: b.about_es || '', en: b.about_en || '' },
    looking: { es: b.looking_es || '', en: b.looking_en || '' },
    cover: img(b.cover_id),
    verified: true,
    rating: await ratingOf(user.id),
    reviews: await reviewsOf(user.id),
  };
}

const LOT_SELECT = `
  SELECT l.*, f.name AS farm_name, f.region, f.municipality, f.altitude, f.hectares,
         u.name AS producer, u.photo_id AS producer_photo,
         (SELECT COALESCE(AVG(r.stars),0)::float FROM ratings r JOIN agreements a ON a.id=r.agreement_id
           WHERE r.by_user_id <> l.farmer_id AND a.farmer_id = l.farmer_id) AS rating_avg,
         (SELECT COUNT(*)::int FROM ratings r JOIN agreements a ON a.id=r.agreement_id
           WHERE r.by_user_id <> l.farmer_id AND a.farmer_id = l.farmer_id) AS rating_count,
         (SELECT json_build_object(
                   'id', au.id, 'endsAt', au.ends_at, 'basePriceLb', au.base_price_lb, 'minIncrementLb', au.min_increment_lb,
                   'sacks', au.sacks, 'status', au.status,
                   'highest', (SELECT MAX(bd.price_lb) FROM bids bd WHERE bd.auction_id = au.id),
                   'bids', (SELECT COUNT(*) FROM bids bd WHERE bd.auction_id = au.id),
                   'bidders', (SELECT COUNT(DISTINCT bd.buyer_id) FROM bids bd WHERE bd.auction_id = au.id))
            FROM auctions au WHERE au.lot_id = l.id AND au.status = 'open' ORDER BY au.id DESC LIMIT 1) AS auction_json
    FROM lots l
    JOIN users u ON u.id = l.farmer_id
    LEFT JOIN farms f ON f.user_id = l.farmer_id`;

function lot(r) {
  return {
    id: r.id,
    farmerId: r.farmer_id,
    name: r.name,
    variety: r.variety,
    process: r.process,
    sacks: r.sacks,
    sca: r.sca,
    priceLb: r.price_lb,
    priceCarga: r.price_carga,
    notes: r.notes || [],
    harvest: r.harvest || '',
    photo: img(r.photo_id),
    active: r.active,
    auction: auctionSummary(r.auction_json),
    createdAt: ms(r.created_at),
    isNew: Date.now() - ms(r.created_at) < 7 * 86400000,
    farm: {
      name: r.farm_name || '',
      region: r.region || '',
      municipality: r.municipality || '',
      altitude: r.altitude || 0,
      hectares: r.hectares || 0,
      producer: r.producer,
      producerPhoto: img(r.producer_photo),
      rating: { avg: r.rating_avg || 0, count: r.rating_count || 0 },
    },
  };
}

/** Fase de una subasta: live (recibe ofertas), ended (terminó, falta elegir), awarded, cancelled, expired. */
function auctionPhase(status, endsAt) {
  if (status !== 'open') return status;
  return ms(endsAt) > Date.now() ? 'live' : 'ended';
}

function auctionSummary(j) {
  if (!j) return null;
  return {
    id: j.id,
    endsAt: ms(j.endsAt),
    basePriceLb: Number(j.basePriceLb),
    minIncrementLb: Number(j.minIncrementLb),
    sacks: j.sacks,
    phase: auctionPhase(j.status, j.endsAt),
    highest: j.highest == null ? null : Number(j.highest),
    bids: Number(j.bids) || 0,
    bidders: Number(j.bidders) || 0,
  };
}

/**
 * Subasta completa. El caficultor ve quién ofertó; cada comprador ve sus propias ofertas
 * y a los demás como "Comprador 1, 2…" (para que la puja sea justa).
 */
function auction(a, lotRow, bidRows, viewer) {
  const isOwner = viewer.id === a.farmer_id;
  const alias = new Map();
  for (const b of [...bidRows].sort((x, y) => x.id - y.id)) if (!alias.has(b.buyer_id)) alias.set(b.buyer_id, alias.size + 1);
  const bids = [...bidRows].sort((x, y) => Number(y.price_lb) - Number(x.price_lb) || x.id - y.id).map((b) => ({
    id: b.id,
    priceLb: Number(b.price_lb),
    status: b.status,
    at: ms(b.created_at),
    mine: b.buyer_id === viewer.id,
    alias: alias.get(b.buyer_id),
    bidder: isOwner || b.buyer_id === viewer.id
      ? { id: b.buyer_id, name: b.buyer_name, company: b.company || '', country: b.country || '', photo: img(b.buyer_photo) }
      : null,
  }));
  const highest = bids.length ? bids[0].priceLb : null;
  const minNext = highest == null ? Number(a.base_price_lb) : Number((highest + Number(a.min_increment_lb)).toFixed(2));
  const myBest = bids.find((b) => b.mine) || null;
  return {
    id: a.id,
    lotId: a.lot_id,
    farmerId: a.farmer_id,
    basePriceLb: Number(a.base_price_lb),
    minIncrementLb: Number(a.min_increment_lb),
    sacks: a.sacks,
    incoterm: a.incoterm,
    endsAt: ms(a.ends_at),
    createdAt: ms(a.created_at),
    phase: auctionPhase(a.status, a.ends_at),
    highest,
    minNext,
    bidders: alias.size,
    bids,
    myBest: myBest ? myBest.priceLb : null,
    leading: !!myBest && bids[0].mine,
    winningBidId: a.winning_bid_id,
    agreementId: a.agreement_id,
    lot: lotRow ? lot(lotRow) : null,
  };
}

function notification(n) {
  return {
    id: n.id,
    type: n.type,
    title: { es: n.title_es, en: n.title_en },
    body: { es: n.body_es, en: n.body_en },
    data: n.data || {},
    read: !!n.read_at,
    createdAt: ms(n.created_at),
  };
}

function message(m, conv) {
  return {
    id: m.id,
    conversationId: m.conversation_id,
    senderId: m.sender_id,
    from: m.sender_id == null ? null : m.sender_id === conv.farmer_id ? 'farmer' : 'buyer',
    type: m.type,
    text: m.text,
    lang: m.lang,
    translation: m.translation,
    viaVoice: m.via_voice,
    photo: img(m.photo_id),
    quote: m.quote,
    agreementId: m.agreement_id,
    sys: m.sys_es || m.sys_en ? { es: m.sys_es || '', en: m.sys_en || '' } : null,
    createdAt: ms(m.created_at),
  };
}

async function agreement(a) {
  const f = await one(
    `SELECT u.name, u.photo_id, f.name AS farm_name, f.region FROM users u LEFT JOIN farms f ON f.user_id=u.id WHERE u.id=$1`,
    [a.farmer_id],
  );
  const b = await one(
    `SELECT u.name, u.photo_id, b.company, b.city, b.country FROM users u LEFT JOIN buyers b ON b.user_id=u.id WHERE u.id=$1`,
    [a.buyer_id],
  );
  const ratings = await many('SELECT * FROM ratings WHERE agreement_id = $1', [a.id]);
  const rat = (uid) => {
    const r = ratings.find((x) => x.by_user_id === uid);
    if (!r) return null;
    return {
      stars: r.stars,
      tags: r.tags || [],
      comment: r.comment_es || r.comment_en ? { es: r.comment_es || '', en: r.comment_en || '' } : null,
      at: ms(r.created_at),
    };
  };
  return {
    id: a.id,
    code: a.code,
    conversationId: a.conversation_id,
    farmerId: a.farmer_id,
    buyerId: a.buyer_id,
    lotId: a.lot_id,
    lotName: a.lot_name,
    variety: a.variety,
    process: a.process,
    sca: a.sca,
    priceLb: a.price_lb,
    sacks: a.sacks,
    incoterm: a.incoterm,
    status: a.status,
    history: a.history || [],
    createdAt: ms(a.created_at),
    farmer: { name: f?.name || '', photo: img(f?.photo_id), farmName: f?.farm_name || '', region: f?.region || '' },
    buyer: { name: b?.name || '', photo: img(b?.photo_id), company: b?.company || '', city: b?.city || '', country: b?.country || '' },
    ratings: { byFarmer: rat(a.farmer_id), byBuyer: rat(a.buyer_id) },
    quality: qualityReport(await one('SELECT * FROM quality_reports WHERE agreement_id = $1', [a.id])),
    disputes: (await many('SELECT * FROM disputes WHERE agreement_id = $1 ORDER BY id DESC', [a.id])).map((d) => dispute(d, a)),
  };
}

function qualityReport(r) {
  if (!r) return null;
  return {
    sca: r.sca,
    moisture: r.moisture,
    defects: r.defects,
    matchesSample: r.matches_sample,
    notes: r.notes || [],
    comment: r.comment_es || r.comment_en ? { es: r.comment_es || '', en: r.comment_en || '' } : null,
    photo: img(r.photo_id),
    at: ms(r.created_at),
  };
}

function dispute(d, a) {
  const roleOf = (uid) => (uid == null ? null : uid === a.farmer_id ? 'farmer' : 'buyer');
  return {
    id: d.id,
    agreementId: d.agreement_id,
    openedBy: roleOf(d.opened_by),
    reason: d.reason,
    status: d.status,
    events: (d.events || []).map((e) => ({
      by: roleOf(e.by),
      kind: e.kind,
      text: e.es || e.en ? { es: e.es || '', en: e.en || '' } : null,
      photo: img(e.photo),
      at: e.at,
    })),
    createdAt: ms(d.created_at),
    resolvedAt: d.resolved_at ? ms(d.resolved_at) : null,
  };
}

module.exports = {
  img, ms, publicUser, meUser, farmProfile, buyerProfile, LOT_SELECT, lot, message, agreement, ratingOf,
  auction, auctionPhase, notification,
};
