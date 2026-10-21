// Utilidades de formato y cálculo

export const KG_PER_SACK = 70;
export const LB_PER_KG = 2.20462;
// Una carga = 125 kg de pergamino seco ≈ 94,3 kg de café verde (factor 92,8 kg pergamino → 70 kg verde)
export const LB_GREEN_PER_CARGA = ((125 * 70) / 92.8) * LB_PER_KG;
// Tasa fija SOLO para la demo
export const COP_PER_USD = 3900;

export const other = (role) => (role === 'farmer' ? 'buyer' : 'farmer');
export const langOf = (role) => (role === 'farmer' ? 'es' : 'en');

export function uid(prefix = 'id') {
  return prefix + Math.random().toString(36).slice(2, 8) + Date.now().toString(36).slice(-4);
}

export const sacksToLb = (sacks) => sacks * KG_PER_SACK * LB_PER_KG;

export function quoteTotal(priceLb, sacks) {
  return priceLb * sacksToLb(sacks);
}

export function copCargaToUsdLb(cop) {
  return cop / COP_PER_USD / LB_GREEN_PER_CARGA;
}

export function fmtUSD(n, lang = 'en', decimals = 2) {
  const s = new Intl.NumberFormat(lang === 'es' ? 'es-CO' : 'en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(n);
  return `US$ ${s}`;
}

export function fmtCOP(n) {
  return '$ ' + new Intl.NumberFormat('es-CO', { maximumFractionDigits: 0 }).format(n);
}

export function fmtNum(n, lang = 'en', decimals = 0) {
  return new Intl.NumberFormat(lang === 'es' ? 'es-CO' : 'en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(n);
}

export function fmtTime(ts, lang = 'en') {
  const d = new Date(ts);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  const locale = lang === 'es' ? 'es-CO' : 'en-US';
  if (sameDay) return d.toLocaleTimeString(locale, { hour: 'numeric', minute: '2-digit' });
  const diffDays = Math.floor((now - d) / 86400000);
  if (diffDays < 7) return d.toLocaleDateString(locale, { weekday: 'short' });
  return d.toLocaleDateString(locale, { day: 'numeric', month: 'short' });
}

export function fmtDate(ts, lang = 'en') {
  return new Date(ts).toLocaleDateString(lang === 'es' ? 'es-CO' : 'en-US', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

export function fmtDuration(sec) {
  const s = Math.max(0, Math.round(sec));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

/** Reputación de una finca = base histórica + calificaciones de acuerdos en la app */
export function farmRating(farm, agreements) {
  const stars = agreements.filter((a) => a.farmId === farm.id && a.ratings?.byBuyer).map((a) => a.ratings.byBuyer.stars);
  return combine(farm.rating, stars);
}

export function buyerRating(buyer, agreements) {
  const stars = agreements.filter((a) => a.buyerId === buyer.id && a.ratings?.byFarmer).map((a) => a.ratings.byFarmer.stars);
  return combine(buyer.rating, stars);
}

function combine(base, stars) {
  const sum = base.avg * base.count + stars.reduce((a, b) => a + b, 0);
  const count = base.count + stars.length;
  return { avg: count ? sum / count : 0, count };
}

export function firstName(full) {
  return String(full).split(' ')[0];
}
