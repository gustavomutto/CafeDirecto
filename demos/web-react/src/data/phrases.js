// Traducción SIMULADA para la demo.
// 1) Si el texto coincide con una frase conocida (plantillas, respuestas, etc.) se usa la traducción exacta.
// 2) Si no, se traduce palabra por palabra con un glosario pequeño y se marca como "aproximada".

export const TEMPLATES = {
  farmer: [
    { id: 't1', icon: '📦', es: 'Tengo muestra disponible', en: 'I have a sample available' },
    { id: 't2', icon: '⚖️', es: '¿Cuál es su volumen?', en: 'What volume are you looking for?' },
    { id: 't3', icon: '📷', es: 'Le envío fotos del lote', en: "I'm sending you photos of the lot" },
    { id: 't4', icon: '🚚', es: 'Puedo enviar la muestra esta semana', en: 'I can ship the sample this week' },
    { id: 't5', icon: '✅', es: 'El café está listo para despacho', en: 'The coffee is ready to ship' },
    { id: 't6', icon: '🙏', es: 'Gracias por su interés en mi café', en: 'Thank you for your interest in my coffee' },
  ],
  buyer: [
    { id: 'b1', icon: '👋', en: 'Hi! I love your coffee profile.', es: '¡Hola! Me encanta el perfil de su café.' },
    { id: 'b2', icon: '📦', en: 'Could you send a 300 g sample?', es: '¿Podría enviar una muestra de 300 g?' },
    { id: 'b3', icon: '💲', en: 'What is your price per pound?', es: '¿Cuál es su precio por libra?' },
    { id: 'b4', icon: '⚖️', en: 'How many bags can you offer?', es: '¿Cuántos sacos puede ofrecer?' },
    { id: 'b5', icon: '🚢', en: 'When could it ship?', es: '¿Cuándo podría despacharse?' },
    { id: 'b6', icon: '⭐', en: 'The sample cupped beautifully!', es: '¡La muestra salió hermosa en taza!' },
    { id: 'b7', icon: '🤝', en: "Let's work together next harvest too.", es: 'Trabajemos juntos también la próxima cosecha.' },
  ],
};

// Notas de voz del caficultor: transcripción (es) + traducción (en)
export const VOICE_NOTES = [
  {
    es: 'Buenos días, le cuento que este año la cosecha salió muy bonita. El café se secó despacio en la marquesina, unos veinte días.',
    en: "Good morning, this year's harvest came out really nice. The coffee dried slowly in the solar dryer, about twenty days.",
  },
  {
    es: 'Este lote es Pink Bourbon, fermentado treinta y seis horas. En la taza sale panela y mandarina.',
    en: 'This lot is Pink Bourbon, fermented for thirty-six hours. In the cup you get panela and tangerine.',
  },
  {
    es: 'La muestra ya está empacada. Mañana la llevo al pueblo para enviarla por mensajería.',
    en: "The sample is already packed. Tomorrow I'm taking it to town to send it by courier.",
  },
  {
    es: 'Con ese precio puedo pagar bien a los recolectores y mejorar el secadero. Muchas gracias.',
    en: 'With that price I can pay the pickers well and improve the drying area. Thank you very much.',
  },
];

// Respuestas automáticas de los participantes que NO son personas de la demo
export const AUTO_REPLIES = {
  buyer: [
    { en: 'Thanks! That sounds great.', es: '¡Gracias! Suena muy bien.' },
    { en: "Perfect, I'll share it with our head roaster.", es: 'Perfecto, lo compartiré con nuestro tostador principal.' },
    { en: 'Could you send a few more photos of the drying beds?', es: '¿Podría enviar algunas fotos más de las camas de secado?' },
  ],
  farmer: [
    { es: '¡Con mucho gusto! Le envío la muestra esta semana.', en: "With pleasure! I'll send you the sample this week." },
    { es: 'Gracias por escribir. El lote está listo en bodega.', en: 'Thanks for writing. The lot is ready in storage.' },
    { es: 'Claro que sí, le comparto fotos del secado.', en: "Of course, I'll share photos of the drying." },
  ],
};

// Frases sueltas con traducción exacta (además de las anteriores)
const EXTRA = [
  { es: 'Hola', en: 'Hello' },
  { es: 'Buenos días', en: 'Good morning' },
  { es: 'Buenas tardes', en: 'Good afternoon' },
  { es: 'Muchas gracias', en: 'Thank you very much' },
  { es: 'Gracias', en: 'Thank you' },
  { es: 'Sí, claro', en: 'Yes, of course' },
  { es: 'De acuerdo', en: 'Agreed' },
  { es: 'Perfecto', en: 'Perfect' },
  { es: '¿Cuándo llega la muestra?', en: 'When does the sample arrive?' },
  { es: 'La muestra ya fue enviada', en: 'The sample has already been sent' },
  { es: 'El precio es por libra', en: 'The price is per pound' },
  { es: 'Le mando el precio ahora', en: "I'll send you the price now" },
  { es: 'Me parece un buen precio', en: 'That seems like a good price to me' },
  { es: '¿Le gustó el café?', en: 'Did you like the coffee?' },
  { en: 'Sounds good', es: 'Suena bien' },
  { en: 'Great, thank you!', es: '¡Genial, gracias!' },
  { en: 'We received the sample', es: 'Recibimos la muestra' },
  { en: 'Can you do a better price?', es: '¿Puede mejorar el precio?' },
  { en: 'We will confirm today', es: 'Confirmaremos hoy' },
  { en: 'How was the harvest this year?', es: '¿Cómo estuvo la cosecha este año?' },
  { en: 'Tell me more about your farm', es: 'Cuénteme más sobre su finca' },
];

const PHRASES = [
  ...TEMPLATES.farmer,
  ...TEMPLATES.buyer,
  ...VOICE_NOTES,
  ...AUTO_REPLIES.buyer,
  ...AUTO_REPLIES.farmer,
  ...EXTRA,
];

// Glosario palabra por palabra (sin tildes, en minúscula). Incluye algunas expresiones de 2–3 palabras.
const ES_EN = {
  'buenos dias': 'good morning', 'buenas tardes': 'good afternoon', 'buenas noches': 'good evening',
  'por favor': 'please', 'muchas gracias': 'thank you very much', 'por libra': 'per pound',
  'sacos de 70 kg': '70 kg bags', 'esta semana': 'this week', 'la proxima semana': 'next week',
  'hola': 'hello', 'gracias': 'thanks', 'si': 'yes', 'no': 'no', 'claro': 'sure', 'listo': 'ready',
  'cafe': 'coffee', 'finca': 'farm', 'lote': 'lot', 'lotes': 'lots', 'muestra': 'sample', 'muestras': 'samples',
  'precio': 'price', 'precios': 'prices', 'saco': 'bag', 'sacos': 'bags', 'kilos': 'kilos', 'libra': 'pound', 'libras': 'pounds',
  'cosecha': 'harvest', 'secado': 'drying', 'fermentacion': 'fermentation', 'lavado': 'washed', 'natural': 'natural',
  'variedad': 'variety', 'proceso': 'process', 'puntaje': 'score', 'puntos': 'points', 'taza': 'cup', 'catacion': 'cupping',
  'envio': 'shipment', 'enviar': 'send', 'mando': 'send', 'envie': 'send', 'enviamos': 'we send',
  'puedo': 'I can', 'podemos': 'we can', 'quiero': 'I want', 'tengo': 'I have', 'tenemos': 'we have', 'hay': 'there is',
  'es': 'is', 'esta': 'is', 'son': 'are', 'estan': 'are', 'fue': 'was',
  'el': 'the', 'la': 'the', 'los': 'the', 'las': 'the', 'un': 'a', 'una': 'a', 'de': 'of', 'del': 'of the', 'al': 'to the',
  'y': 'and', 'o': 'or', 'pero': 'but', 'con': 'with', 'sin': 'without', 'para': 'for', 'por': 'for', 'en': 'in', 'a': 'to',
  'mi': 'my', 'mis': 'my', 'su': 'your', 'sus': 'your', 'usted': 'you', 'ustedes': 'you', 'yo': 'I', 'nosotros': 'we',
  'que': 'that', 'cuando': 'when', 'cuanto': 'how much', 'cuantos': 'how many', 'cual': 'which', 'como': 'how', 'donde': 'where',
  'muy': 'very', 'bueno': 'good', 'buena': 'good', 'buen': 'good', 'mejor': 'better', 'excelente': 'excellent', 'bonito': 'beautiful',
  'dulce': 'sweet', 'acidez': 'acidity', 'cuerpo': 'body', 'aroma': 'aroma', 'chocolate': 'chocolate', 'panela': 'panela',
  'hoy': 'today', 'manana': 'tomorrow', 'ayer': 'yesterday', 'semana': 'week', 'mes': 'month', 'ano': 'year', 'dias': 'days',
  'familia': 'family', 'montana': 'mountain', 'altura': 'altitude', 'metros': 'meters', 'agua': 'water', 'sol': 'sun',
  'pago': 'payment', 'pagar': 'pay', 'contrato': 'contract', 'acuerdo': 'agreement', 'volumen': 'volume', 'disponible': 'available',
  'fotos': 'photos', 'foto': 'photo', 'llega': 'arrives', 'llego': 'arrived', 'recibio': 'received', 'gusto': 'liked',
  'nuevo': 'new', 'nueva': 'new', 'todo': 'all', 'tambien': 'also', 'ahora': 'now', 'ya': 'already', 'mas': 'more', 'menos': 'less',
};

const EN_ES = {
  'we are': 'somos', 'i am': 'soy', 'we love': 'nos encanta', 'i love': 'me encanta', 'we would like': 'nos gustaría',
  'small': 'pequeño', 'big': 'grande', 'sample arrived': 'la muestra llegó', 'next': 'próximo',
  'good morning': 'buenos días', 'thank you': 'gracias', 'per pound': 'por libra', 'this week': 'esta semana',
  'next week': 'la próxima semana', 'next harvest': 'la próxima cosecha', 'green coffee': 'café verde',
  'hello': 'hola', 'hi': 'hola', 'thanks': 'gracias', 'please': 'por favor', 'yes': 'sí', 'no': 'no', 'great': 'genial',
  'coffee': 'café', 'farm': 'finca', 'lot': 'lote', 'lots': 'lotes', 'sample': 'muestra', 'samples': 'muestras',
  'price': 'precio', 'prices': 'precios', 'bag': 'saco', 'bags': 'sacos', 'pound': 'libra', 'pounds': 'libras',
  'harvest': 'cosecha', 'drying': 'secado', 'fermentation': 'fermentación', 'washed': 'lavado', 'variety': 'variedad',
  'process': 'proceso', 'score': 'puntaje', 'points': 'puntos', 'cup': 'taza', 'cupping': 'catación', 'cupped': 'catamos',
  'ship': 'despachar', 'shipping': 'envío', 'send': 'enviar', 'contract': 'contrato', 'agreement': 'acuerdo', 'payment': 'pago',
  'i': 'yo', 'we': 'nosotros', 'you': 'usted', 'your': 'su', 'our': 'nuestro', 'my': 'mi',
  'is': 'es', 'are': 'son', 'was': 'fue', 'can': 'puede', 'could': 'podría', 'would': 'quisiera', 'will': 'va a',
  'the': 'el', 'a': 'un', 'an': 'un', 'of': 'de', 'and': 'y', 'or': 'o', 'but': 'pero', 'with': 'con', 'for': 'para',
  'in': 'en', 'to': 'a', 'from': 'de', 'about': 'sobre', 'this': 'este', 'that': 'ese', 'it': 'lo',
  'love': 'encanta', 'like': 'gusta', 'want': 'queremos', 'need': 'necesitamos', 'buy': 'comprar', 'order': 'pedido',
  'how': 'cómo', 'many': 'muchos', 'much': 'mucho', 'when': 'cuándo', 'what': 'qué', 'where': 'dónde', 'which': 'cuál',
  'very': 'muy', 'good': 'bueno', 'better': 'mejor', 'excellent': 'excelente', 'beautiful': 'hermoso', 'sweet': 'dulce',
  'acidity': 'acidez', 'body': 'cuerpo', 'clean': 'limpio', 'today': 'hoy', 'tomorrow': 'mañana', 'week': 'semana',
  'month': 'mes', 'year': 'año', 'volume': 'volumen', 'available': 'disponible', 'photos': 'fotos', 'photo': 'foto',
  'roastery': 'tostaduría', 'roaster': 'tostador', 'customers': 'clientes', 'also': 'también', 'now': 'ahora', 'more': 'más',
};

export function norm(s) {
  return String(s)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[¿¡?!.,;:()"“”']/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

const PHRASE_INDEX = { es: new Map(), en: new Map() };
for (const p of PHRASES) {
  if (p.es && p.en) {
    PHRASE_INDEX.es.set(norm(p.es), p.en);
    PHRASE_INDEX.en.set(norm(p.en), p.es);
  }
}

/** Traduce un texto. Devuelve { text, exact }. */
export function translate(text, from) {
  const exactHit = PHRASE_INDEX[from].get(norm(text));
  if (exactHit) return { text: exactHit, exact: true };

  const dict = from === 'es' ? ES_EN : EN_ES;
  const tokens = text.split(/\s+/).filter(Boolean);
  const out = [];
  let i = 0;
  while (i < tokens.length) {
    let matched = false;
    // Busca primero expresiones de 3, luego 2, luego 1 palabra
    for (let size = 3; size >= 1 && !matched; size--) {
      if (i + size > tokens.length) continue;
      const slice = tokens.slice(i, i + size);
      const key = norm(slice.join(' '));
      if (dict[key]) {
        const trailing = (slice[slice.length - 1].match(/[?!.,;:]+$/) || [''])[0];
        let word = dict[key];
        if (i === 0) word = word.charAt(0).toUpperCase() + word.slice(1);
        out.push(word + trailing);
        i += size;
        matched = true;
      }
    }
    if (!matched) {
      out.push(tokens[i].replace(/^[¿¡]/, ''));
      i++;
    }
  }
  let result = out.join(' ');
  if (from === 'en' && /\?$/.test(result)) result = '¿' + result;
  return { text: result, exact: false };
}
