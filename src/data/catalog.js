// Catálogos compartidos: regiones, variedades, procesos y notas de catación.

export const REGIONS = ['Huila', 'Nariño', 'Cauca', 'Quindío', 'Tolima', 'Sierra Nevada'];

export const VARIETIES = ['Castillo', 'Caturra', 'Geisha', 'Pink Bourbon', 'Colombia'];

export const PROCESSES = {
  lavado: { es: 'Lavado', en: 'Washed', icon: '💧' },
  honey: { es: 'Honey', en: 'Honey', icon: '🍯' },
  natural: { es: 'Natural', en: 'Natural', icon: '🍒' },
};

export const NOTES = {
  panela: { es: 'Panela', en: 'Panela' },
  mandarina: { es: 'Mandarina', en: 'Tangerine' },
  cacao: { es: 'Cacao', en: 'Cacao' },
  chocolate: { es: 'Chocolate', en: 'Chocolate' },
  caramelo: { es: 'Caramelo', en: 'Caramel' },
  floral: { es: 'Floral', en: 'Floral' },
  citrico: { es: 'Cítrico', en: 'Citrus' },
  durazno: { es: 'Durazno', en: 'Peach' },
  miel: { es: 'Miel', en: 'Honey' },
  jazmin: { es: 'Jazmín', en: 'Jasmine' },
  bergamota: { es: 'Bergamota', en: 'Bergamot' },
  frutosrojos: { es: 'Frutos rojos', en: 'Red berries' },
  vino: { es: 'Vino', en: 'Winey' },
  nuez: { es: 'Nuez', en: 'Walnut' },
  manzana: { es: 'Manzana verde', en: 'Green apple' },
};

export const INCOTERMS = {
  'FOB Buenaventura': { es: 'FOB Buenaventura', en: 'FOB Buenaventura' },
  'FOB Cartagena': { es: 'FOB Cartagena', en: 'FOB Cartagena' },
  'EXW Finca': { es: 'En la finca (EXW)', en: 'Ex-farm (EXW)' },
};

export const STATUS_STEPS = [
  { key: 'quoted', es: 'Cotizado', en: 'Quoted', icon: 'tag' },
  { key: 'confirmed', es: 'Confirmado', en: 'Confirmed', icon: 'handshake' },
  { key: 'shipped', es: 'Enviado', en: 'Shipped', icon: 'truck' },
  { key: 'delivered', es: 'Entregado', en: 'Delivered', icon: 'check' },
];
