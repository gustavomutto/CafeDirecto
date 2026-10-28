// Traducción real ES ⇄ EN.
// Orden de proveedores según las variables de entorno que configures en Railway:
//   1. DEEPL_API_KEY            → DeepL (la mejor calidad; plan gratis de 500.000 caracteres/mes)
//   2. GOOGLE_TRANSLATE_API_KEY → Google Cloud Translation v2
//   3. (ninguna)                → MyMemory, gratis y sin clave (límite diario; pon MYMEMORY_EMAIL para subirlo)
// Si un proveedor falla se prueba el siguiente; si todos fallan, el mensaje se envía sin traducción.

const cache = new Map();
const MAX_CACHE = 2000;

async function withTimeout(promise, ms = 8000) {
  let t;
  const timeout = new Promise((_, rej) => { t = setTimeout(() => rej(new Error('timeout')), ms); });
  try { return await Promise.race([promise, timeout]); } finally { clearTimeout(t); }
}

async function deepl(text, from, to) {
  const key = process.env.DEEPL_API_KEY;
  const host = key.endsWith(':fx') ? 'https://api-free.deepl.com' : 'https://api.deepl.com';
  const res = await withTimeout(fetch(`${host}/v2/translate`, {
    method: 'POST',
    headers: { Authorization: `DeepL-Auth-Key ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: [text], source_lang: from.toUpperCase(), target_lang: to === 'en' ? 'EN-US' : 'ES' }),
  }));
  if (!res.ok) throw new Error(`DeepL ${res.status}`);
  const j = await res.json();
  return j.translations[0].text;
}

async function google(text, from, to) {
  const key = process.env.GOOGLE_TRANSLATE_API_KEY;
  const res = await withTimeout(fetch(`https://translation.googleapis.com/language/translate/v2?key=${encodeURIComponent(key)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ q: text, source: from, target: to, format: 'text' }),
  }));
  if (!res.ok) throw new Error(`Google ${res.status}`);
  const j = await res.json();
  return j.data.translations[0].translatedText;
}

/** Parte un texto largo en trozos de hasta `max` caracteres, cortando en fin de frase o espacio. */
function chunks(text, max = 450) {
  const out = [];
  let rest = text;
  while (rest.length > max) {
    const slice = rest.slice(0, max);
    const cut = Math.max(slice.lastIndexOf('. '), slice.lastIndexOf('? '), slice.lastIndexOf('! '), slice.lastIndexOf('\n'));
    const at = cut > max * 0.5 ? cut + 1 : (slice.lastIndexOf(' ') > 0 ? slice.lastIndexOf(' ') : max);
    out.push(rest.slice(0, at).trim());
    rest = rest.slice(at).trim();
  }
  if (rest) out.push(rest);
  return out;
}

async function mymemoryOne(text, from, to) {
  const params = new URLSearchParams({ q: text, langpair: `${from}|${to}` });
  if (process.env.MYMEMORY_EMAIL) params.set('de', process.env.MYMEMORY_EMAIL);
  const res = await withTimeout(fetch(`https://api.mymemory.translated.net/get?${params}`));
  if (!res.ok) throw new Error(`MyMemory ${res.status}`);
  const j = await res.json();
  if (j.responseStatus !== 200 && j.responseStatus !== '200') throw new Error(`MyMemory ${j.responseStatus}`);
  return j.responseData.translatedText;
}

// MyMemory acepta hasta ~500 caracteres por consulta: los textos largos se traducen por partes
// (antes se cortaban y el resto del mensaje quedaba sin traducir).
async function mymemory(text, from, to) {
  const parts = chunks(text);
  const out = [];
  for (const part of parts) out.push(await mymemoryOne(part, from, to));
  return out.join(' ');
}

function providers() {
  const list = [];
  if (process.env.DEEPL_API_KEY) list.push(['deepl', deepl]);
  if (process.env.GOOGLE_TRANSLATE_API_KEY) list.push(['google', google]);
  list.push(['mymemory', mymemory]);
  return list;
}

/** Traduce `text` de `from` a `to`. Devuelve el texto traducido o null si no se pudo. */
async function translate(text, from, to) {
  const clean = String(text || '').trim();
  if (!clean || from === to) return null;
  const key = `${from}|${to}|${clean}`;
  if (cache.has(key)) return cache.get(key);
  for (const [name, fn] of providers()) {
    try {
      const out = await fn(clean, from, to);
      if (out) {
        if (cache.size > MAX_CACHE) cache.clear();
        cache.set(key, out);
        return out;
      }
    } catch (e) {
      console.warn(`[translate] ${name} falló: ${e.message}`);
    }
  }
  return null;
}

/** Devuelve { es, en } a partir de un texto escrito en `lang`. */
async function both(text, lang) {
  const clean = String(text || '').trim();
  if (!clean) return { es: '', en: '' };
  const other = lang === 'es' ? 'en' : 'es';
  const tr = (await translate(clean, lang, other)) || clean;
  return lang === 'es' ? { es: clean, en: tr } : { es: tr, en: clean };
}

function providerName() {
  return providers()[0][0];
}

module.exports = { translate, both, providerName, chunks };
