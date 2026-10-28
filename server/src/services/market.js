// Precios del café: precio interno de la FNC (Colombia), contrato "C" de la Bolsa de Nueva York (ICE)
// y la TRM oficial. El servidor los consulta, los guarda en caché 20 minutos y guarda un registro diario
// para armar el histórico. Si una fuente falla, se usa el último valor bueno (marcado como "stale").
const { q, many } = require('../db');

const CACHE_MS = 20 * 60 * 1000;
const UA = 'Mozilla/5.0 (compatible; CafeDirecto/2.0; +https://cafedirecto-production.up.railway.app)';

// Una carga = 125 kg de café pergamino seco. Con el factor de rendimiento base 94
// (94 kg de pergamino → 70 kg de café verde excelso) equivale a ≈ 93,1 kg ≈ 205,2 lb de café verde.
const KG_PER_CARGA = 125;
const FACTOR_BASE = 94;
const LB_PER_KG = 2.20462;
const LB_GREEN_PER_CARGA = ((KG_PER_CARGA * 70) / FACTOR_BASE) * LB_PER_KG;
const DEFAULT_DIFFERENTIAL = 0.25; // prima típica del café colombiano sobre la bolsa, en US$/lb

const FNC_URLS = ['https://federaciondecafeteros.org/public/', 'https://federaciondecafeteros.org/wp/'];

async function get(url, { json = false, timeout = 10000 } = {}) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA, Accept: json ? 'application/json' : 'text/html' }, signal: ctrl.signal });
    if (!res.ok) throw new Error(`${url} respondió ${res.status}`);
    return json ? res.json() : res.text();
  } finally {
    clearTimeout(timer);
  }
}

// "2.065.000" → 2065000 · "293,75" → 293.75 · "3.147,40" → 3147.4
const parseCo = (s) => Number(String(s).replace(/\./g, '').replace(',', '.'));
const day = (d) => new Date(d).toISOString().slice(0, 10);
const inRange = (v, min, max) => Number.isFinite(v) && v >= min && v <= max;

/** Lee los valores publicados en la página de la Federación Nacional de Cafeteros. */
function parseFnc(html) {
  const text = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#036;|&dollar;/g, '$')
    .replace(/\s+/g, ' ');
  // Recorre cada aparición de la etiqueta y toma el primer número que tenga sentido
  // (así un menú o un titular con el mismo texto no confunde la lectura).
  const find = (label, re, min, max) => {
    const rx = new RegExp(label, 'gi');
    let m;
    while ((m = rx.exec(text))) {
      const chunk = text.slice(m.index + m[0].length, m.index + m[0].length + 160);
      const v = chunk.match(re);
      const value = v ? parseCo(v[1]) : NaN;
      if (inRange(value, min, max)) {
        const d = chunk.match(/Fecha:?\s*(\d{4}-\d{2}-\d{2})/i);
        return { value, date: d ? d[1] : null };
      }
    }
    return null;
  };
  const out = {};
  const carga = find('Precio interno de referencia', /^[^$\d]{0,40}\$?\s*(\d{1,2}\.\d{3}\.\d{3}|\d{6,7})/, 300000, 8000000);
  if (carga) out.carga = carga;
  const ny = find('Bolsa de N(?:ueva )?Y(?:ork)?', /^[^$\d]{0,40}\$?\s*(\d{2,3}(?:[.,]\d{1,2})?)/, 40, 900);
  if (ny) out.ny = ny;
  const trm = find('Tasa de cambio', /^[^$\d]{0,40}\$?\s*(\d\.?\d{3}(?:,\d{1,2})?)/, 1500, 9000);
  if (trm) out.trm = trm;
  return out;
}

async function fetchFnc() {
  let lastErr;
  for (const url of FNC_URLS) {
    try {
      const r = parseFnc(await get(url));
      if (r.carga) return { ...r, url };
      lastErr = new Error('No se encontró el precio interno en la página');
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr;
}

/** TRM oficial (Superintendencia Financiera) desde datos abiertos: últimos 90 registros. */
async function fetchTrm() {
  const url = 'https://www.datos.gov.co/resource/32sa-8pi3.json?$order=vigenciadesde%20DESC&$limit=90';
  const rows = await get(url, { json: true });
  const list = rows
    .map((r) => ({ t: new Date(r.vigenciadesde).getTime(), v: Number(r.valor) }))
    .filter((p) => inRange(p.v, 1500, 9000) && p.t > 0)
    .sort((a, b) => a.t - b.t);
  if (!list.length) throw new Error('Sin datos de TRM');
  return list;
}

/** Contrato "C" del café (KC=F, centavos de dólar por libra) con el histórico de 3 meses. */
async function fetchNy() {
  const url = 'https://query1.finance.yahoo.com/v8/finance/chart/KC%3DF?range=3mo&interval=1d';
  const j = await get(url, { json: true });
  const r = j?.chart?.result?.[0];
  if (!r) throw new Error('Respuesta de la bolsa sin datos');
  const closes = r.indicators?.quote?.[0]?.close || [];
  const list = (r.timestamp || [])
    .map((t, i) => ({ t: t * 1000, v: closes[i] }))
    .filter((p) => inRange(p.v, 40, 900));
  const price = r.meta?.regularMarketPrice;
  if (inRange(price, 40, 900)) {
    const t = (r.meta.regularMarketTime || Date.now() / 1000) * 1000;
    if (!list.length || day(list[list.length - 1].t) !== day(t)) list.push({ t, v: price });
    else list[list.length - 1].v = price;
  }
  if (!list.length) throw new Error('Sin precios de la bolsa');
  return list;
}

let cache = null; // { at, data }
const lastGood = { fnc: null, trm: null, ny: null };

async function saveSnapshot(d, { carga, ny, trm }) {
  try {
    await q(
      `INSERT INTO market_snapshots (day, fnc_cop_carga, ny_usd_cents, trm) VALUES ($1,$2,$3,$4)
       ON CONFLICT (day) DO UPDATE SET fnc_cop_carga = COALESCE(EXCLUDED.fnc_cop_carga, market_snapshots.fnc_cop_carga),
         ny_usd_cents = COALESCE(EXCLUDED.ny_usd_cents, market_snapshots.ny_usd_cents),
         trm = COALESCE(EXCLUDED.trm, market_snapshots.trm), created_at = now()`,
      [d, carga ?? null, ny ?? null, trm ?? null],
    );
  } catch (e) {
    console.error('No se pudo guardar el registro de mercado:', e.message);
  }
}

async function build() {
  const [fncR, trmR, nyR] = await Promise.allSettled([fetchFnc(), fetchTrm(), fetchNy()]);
  for (const [name, r] of [['FNC', fncR], ['TRM', trmR], ['Bolsa NY', nyR]]) {
    if (r.status === 'rejected') console.warn(`Mercado: ${name} no disponible (${r.reason?.message || r.reason})`);
  }
  const stale = { fnc: false, trm: false, ny: false };
  let fnc = fncR.status === 'fulfilled' ? fncR.value : null;
  if (fnc) lastGood.fnc = fnc; else if (lastGood.fnc) { fnc = lastGood.fnc; stale.fnc = true; }
  let trmList = trmR.status === 'fulfilled' ? trmR.value : null;
  if (trmList) lastGood.trm = trmList; else if (lastGood.trm) { trmList = lastGood.trm; stale.trm = true; }
  let nyList = nyR.status === 'fulfilled' ? nyR.value : null;
  if (nyList) lastGood.ny = nyList; else if (lastGood.ny) { nyList = lastGood.ny; stale.ny = true; }

  // TRM: la oficial; si no hay, la que publica la FNC.
  const trmLast = trmList?.[trmList.length - 1];
  const trm = trmLast
    ? { copPerUsd: trmLast.v, date: day(trmLast.t), source: 'Superintendencia Financiera (datos.gov.co)', stale: stale.trm, history: trmList.slice(-60) }
    : fnc?.trm
      ? { copPerUsd: fnc.trm.value, date: fnc.trm.date, source: 'Federación Nacional de Cafeteros', stale: stale.fnc, history: [] }
      : null;

  // Bolsa NY: Yahoo Finance (con histórico); si no hay, el cierre que publica la FNC.
  let ny = null;
  if (nyList?.length) {
    const lastP = nyList[nyList.length - 1];
    const prev = nyList.length > 1 ? nyList[nyList.length - 2].v : null;
    ny = {
      usdCentsPerLb: Number(lastP.v.toFixed(2)),
      date: day(lastP.t),
      changePct: prev ? Number((((lastP.v - prev) / prev) * 100).toFixed(2)) : null,
      source: 'ICE Futures US · contrato C (Yahoo Finance)',
      stale: stale.ny,
      history: nyList.slice(-60).map((p) => ({ t: p.t, v: Number(p.v.toFixed(2)) })),
    };
  } else if (fnc?.ny) {
    ny = { usdCentsPerLb: fnc.ny.value, date: fnc.ny.date, changePct: null, source: 'ICE · cierre publicado por la FNC', stale: stale.fnc, history: [] };
  }

  // Precio interno: el publicado por la FNC; si no se pudo leer, un estimado con bolsa + TRM + prima.
  const prevRows = await many(
    'SELECT day, fnc_cop_carga, ny_usd_cents, trm FROM market_snapshots WHERE day > now() - interval \'120 days\' ORDER BY day ASC',
  ).catch(() => []);
  let internal = null;
  if (fnc?.carga) {
    internal = {
      copPerCarga: fnc.carga.value, date: fnc.carga.date || day(Date.now()), estimated: false, stale: stale.fnc,
      source: 'Federación Nacional de Cafeteros (precio interno de referencia)', url: fnc.url,
    };
  } else if (ny && trm) {
    // usa la última prima real conocida, o la típica
    const known = prevRows.filter((r) => r.fnc_cop_carga && r.ny_usd_cents && r.trm).pop();
    const diff = known
      ? known.fnc_cop_carga / known.trm / LB_GREEN_PER_CARGA - known.ny_usd_cents / 100
      : DEFAULT_DIFFERENTIAL;
    internal = {
      copPerCarga: Math.round(((ny.usdCentsPerLb / 100 + diff) * trm.copPerUsd * LB_GREEN_PER_CARGA) / 1000) * 1000,
      date: day(Date.now()), estimated: true, stale: false,
      source: 'Estimado con la bolsa de NY, la TRM y la prima del café colombiano',
    };
  }

  if (!stale.fnc || !stale.ny || !stale.trm) {
    await saveSnapshot(day(Date.now()), {
      carga: internal && !internal.estimated ? internal.copPerCarga : null,
      ny: ny?.usdCentsPerLb, trm: trm?.copPerUsd,
    });
  }

  let derived = null;
  if (internal) {
    const usdLb = trm ? internal.copPerCarga / trm.copPerUsd / LB_GREEN_PER_CARGA : null;
    derived = {
      copPerKg: Math.round(internal.copPerCarga / KG_PER_CARGA),
      copPerArroba: Math.round(internal.copPerCarga / 10),
      internalUsdPerLbGreen: usdLb ? Number(usdLb.toFixed(3)) : null,
      differentialUsdLb: usdLb && ny ? Number((usdLb - ny.usdCentsPerLb / 100).toFixed(3)) : null,
    };
  }

  return {
    updatedAt: Date.now(),
    internal,
    ny,
    trm,
    derived,
    internalHistory: prevRows.filter((r) => r.fnc_cop_carga).map((r) => ({ t: new Date(r.day).getTime(), v: r.fnc_cop_carga })),
    constants: { kgPerCarga: KG_PER_CARGA, factor: FACTOR_BASE, lbGreenPerCarga: Number(LB_GREEN_PER_CARGA.toFixed(2)) },
  };
}

let inflight = null;
async function coffeeMarket({ refresh = false } = {}) {
  if (!refresh && cache && Date.now() - cache.at < CACHE_MS) return cache.data;
  if (!inflight) {
    inflight = build()
      .then((data) => { cache = { at: Date.now(), data }; return data; })
      .finally(() => { inflight = null; });
  }
  return inflight;
}

module.exports = { coffeeMarket, parseFnc, LB_GREEN_PER_CARGA };
