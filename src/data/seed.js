import { FARMS } from './farms';
import { BUYERS } from './buyers';
import { LOTS } from './lots';
import { PHOTOS } from './photos';

export const SEED_VERSION = 3;

const MIN = 60 * 1000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

/** Construye el estado inicial de la demo (se llama también al "Reiniciar datos"). */
export function createSeed() {
  const now = Date.now();
  const ago = (ms) => now - ms;

  // ── Conversación 1: Huila (f1) ↔ Portland (b2). Negociación a medio camino. ──
  const c1 = {
    id: 'c1',
    farmId: 'f1',
    buyerId: 'b2',
    lotId: 'l1',
    unread: { farmer: 2, buyer: 0 },
    typing: null,
    autoIdx: 0,
    updatedAt: ago(40 * MIN),
    messages: [
      { id: 'c1m0', type: 'system', at: ago(3 * DAY), text: { es: 'Conversación iniciada · traducción automática activa', en: 'Conversation started · auto-translation on' } },
      {
        id: 'c1m1', type: 'text', from: 'buyer', at: ago(3 * DAY), status: 'sent', lang: 'en', exact: true,
        text: 'Hi Luz Marina! We cupped your Pink Bourbon at a fair in Bogotá. Is it still available?',
        translation: '¡Hola Luz Marina! Catamos su Pink Bourbon en una feria en Bogotá. ¿Todavía está disponible?',
        lotRef: 'l1',
      },
      {
        id: 'c1m2', type: 'voice', from: 'farmer', at: ago(3 * DAY - 2 * HOUR), status: 'sent', lang: 'es', duration: 12,
        text: 'Buenos días, Marcus. Sí, todavía tengo veintiocho sacos. Es un honey con fermentación de treinta y seis horas.',
        translation: "Good morning, Marcus. Yes, I still have twenty-eight bags. It's a honey with a thirty-six-hour fermentation.",
      },
      {
        id: 'c1m3', type: 'photo', from: 'farmer', at: ago(3 * DAY - 2 * HOUR + MIN), status: 'sent',
        src: PHOTOS.roast, caption: { es: 'Secado lento en marquesina', en: 'Slow drying in the solar dryer' },
      },
      {
        id: 'c1m4', type: 'text', from: 'buyer', at: ago(2 * DAY), status: 'sent', lang: 'en', exact: true,
        text: 'Could you send a 300 g sample?', translation: '¿Podría enviar una muestra de 300 g?',
      },
      {
        id: 'c1m5', type: 'text', from: 'farmer', at: ago(2 * DAY - HOUR), status: 'sent', lang: 'es', exact: true,
        text: 'Puedo enviar la muestra esta semana', translation: 'I can ship the sample this week',
      },
      { id: 'c1m6', type: 'system', at: ago(1 * DAY), text: { es: 'Muestra recibida en Portland 📦', en: 'Sample received in Portland 📦' } },
      {
        id: 'c1m7', type: 'text', from: 'buyer', at: ago(20 * HOUR), status: 'sent', lang: 'en', exact: true,
        text: 'The sample cupped beautifully!', translation: '¡La muestra salió hermosa en taza!',
      },
      {
        id: 'c1m8', type: 'quote', from: 'farmer', at: ago(6 * HOUR), status: 'sent',
        quote: {
          lotId: 'l1', priceLb: 5.9, sacks: 20, incoterm: 'FOB Buenaventura',
          history: [{ by: 'farmer', priceLb: 5.9, sacks: 20, at: ago(6 * HOUR) }],
          lastBy: 'farmer', status: 'superseded', acceptedBy: null, agreementId: null,
        },
      },
      {
        id: 'c1m9', type: 'quote', from: 'buyer', at: ago(45 * MIN), status: 'sent',
        quote: {
          lotId: 'l1', priceLb: 5.45, sacks: 20, incoterm: 'FOB Buenaventura',
          history: [
            { by: 'farmer', priceLb: 5.9, sacks: 20, at: ago(6 * HOUR) },
            { by: 'buyer', priceLb: 5.45, sacks: 20, at: ago(45 * MIN) },
          ],
          lastBy: 'buyer', status: 'open', acceptedBy: null, agreementId: null,
        },
      },
      {
        id: 'c1m10', type: 'text', from: 'buyer', at: ago(40 * MIN), status: 'sent', lang: 'en', exact: true,
        text: 'We can commit to 20 bags if we meet at 5.45.',
        translation: 'Podemos comprometernos con 20 sacos si llegamos a 5,45.',
      },
    ],
  };

  // ── Conversación 2: Huila (f1) ↔ Tokio (b3). Acuerdo cerrado y calificado. ──
  const c2 = {
    id: 'c2',
    farmId: 'f1',
    buyerId: 'b3',
    lotId: 'l2',
    unread: { farmer: 0, buyer: 0 },
    typing: null,
    autoIdx: 0,
    updatedAt: ago(9 * DAY),
    messages: [
      { id: 'c2m0', type: 'system', at: ago(80 * DAY), text: { es: 'Conversación iniciada · traducción automática activa', en: 'Conversation started · auto-translation on' } },
      {
        id: 'c2m1', type: 'text', from: 'buyer', at: ago(80 * DAY), status: 'sent', lang: 'en', exact: true,
        text: 'Hello from Tokyo! Our cafés are looking for a washed Caturra.',
        translation: '¡Hola desde Tokio! Nuestras cafeterías buscan un Caturra lavado.',
      },
      {
        id: 'c2m2', type: 'text', from: 'farmer', at: ago(80 * DAY - 3 * HOUR), status: 'sent', lang: 'es', exact: true,
        text: 'Tengo muestra disponible', translation: 'I have a sample available',
      },
      {
        id: 'c2m3', type: 'quote', from: 'farmer', at: ago(70 * DAY), status: 'sent',
        quote: {
          lotId: 'l2', priceLb: 5.1, sacks: 15, incoterm: 'FOB Buenaventura',
          history: [{ by: 'farmer', priceLb: 5.1, sacks: 15, at: ago(70 * DAY) }],
          lastBy: 'farmer', status: 'agreed', acceptedBy: 'buyer', agreementId: 'a1',
        },
      },
      { id: 'c2m4', type: 'agreement', at: ago(69 * DAY), agreementId: 'a1' },
      { id: 'c2m5', type: 'system', at: ago(10 * DAY), text: { es: 'Entregado en Tokio ✅', en: 'Delivered in Tokyo ✅' } },
      {
        id: 'c2m6', type: 'text', from: 'buyer', at: ago(9 * DAY), status: 'sent', lang: 'en', exact: true,
        text: 'The coffee arrived perfectly. Arigato!', translation: 'El café llegó perfecto. ¡Arigato!',
      },
    ],
  };

  // ── Conversación 3: Berlín (b1) ↔ Nariño (f2). Charla inicial. ──
  const c3 = {
    id: 'c3',
    farmId: 'f2',
    buyerId: 'b1',
    lotId: 'l3',
    unread: { farmer: 0, buyer: 1 },
    typing: null,
    autoIdx: 0,
    updatedAt: ago(2 * HOUR),
    messages: [
      { id: 'c3m0', type: 'system', at: ago(1 * DAY), text: { es: 'Conversación iniciada · traducción automática activa', en: 'Conversation started · auto-translation on' } },
      {
        id: 'c3m1', type: 'text', from: 'buyer', at: ago(1 * DAY), status: 'sent', lang: 'en', exact: true,
        text: 'Hi! I love your coffee profile.', translation: '¡Hola! Me encanta el perfil de su café.', lotRef: 'l3',
      },
      {
        id: 'c3m2', type: 'text', from: 'farmer', at: ago(2 * HOUR), status: 'sent', lang: 'es', exact: true,
        text: 'Muchas gracias, Lena. Nuestro café crece a 2.150 metros, cerca del volcán Galeras.',
        translation: 'Thank you very much, Lena. Our coffee grows at 2,150 meters, near the Galeras volcano.',
      },
    ],
  };

  const agreements = [
    {
      id: 'a1',
      code: 'CD-2026-0098',
      convId: 'c2',
      farmId: 'f1',
      buyerId: 'b3',
      lotId: 'l2',
      lotName: 'Lote Familia',
      variety: 'Caturra',
      process: 'lavado',
      sca: 86,
      priceLb: 5.1,
      sacks: 15,
      incoterm: 'FOB Buenaventura',
      createdAt: ago(69 * DAY),
      status: 3,
      history: [ago(70 * DAY), ago(69 * DAY), ago(40 * DAY), ago(10 * DAY)],
      ratings: {
        byBuyer: {
          stars: 5,
          tags: ['quality', 'communication'],
          comment: {
            en: 'The cup matched the sample perfectly. Very clear communication.',
            es: 'La taza coincidió perfectamente con la muestra. Comunicación muy clara.',
          },
          at: ago(9 * DAY),
        },
        byFarmer: {
          stars: 5,
          tags: ['payment', 'communication'],
          comment: {
            es: 'Pagaron a tiempo y explicaron todo con paciencia.',
            en: 'They paid on time and explained everything patiently.',
          },
          at: ago(9 * DAY),
        },
      },
    },
    {
      id: 'a2',
      code: 'CD-2026-0101',
      convId: null,
      farmId: 'f4',
      buyerId: 'b1',
      lotId: 'l5',
      lotName: 'Geisha Cristalina',
      variety: 'Geisha',
      process: 'natural',
      sca: 89,
      priceLb: 13.8,
      sacks: 5,
      incoterm: 'FOB Cartagena',
      createdAt: ago(30 * DAY),
      status: 2,
      history: [ago(32 * DAY), ago(30 * DAY), ago(6 * DAY)],
      ratings: {},
    },
  ];

  return {
    version: SEED_VERSION,
    onboarded: false,
    role: 'buyer',
    offline: false,
    syncing: false,
    me: { farmer: 'f1', buyer: 'b1' },
    farms: structuredClone(FARMS),
    buyers: structuredClone(BUYERS),
    lots: structuredClone(LOTS).map((l, i) => ({ ...l, createdAt: ago((20 + i) * DAY) })),
    conversations: [c1, c2, c3],
    agreements,
    voiceIdx: 0,
  };
}
