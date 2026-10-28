// Claves del servidor. En producción (Railway) JWT_SECRET es obligatoria.
const isProduction = process.env.NODE_ENV === 'production' || !!process.env.RAILWAY_ENVIRONMENT || !!process.env.RAILWAY_ENVIRONMENT_NAME;

if (!process.env.JWT_SECRET && isProduction) {
  console.error('Falta la variable JWT_SECRET. En Railway agrégala con un texto largo y aleatorio (48 caracteres o más).');
  process.exit(1);
}
if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
  console.warn('⚠️  JWT_SECRET es corta; usa al menos 32 caracteres aleatorios.');
}
if (!process.env.JWT_SECRET) console.warn('⚠️  Usando una clave JWT de desarrollo. No la uses en producción.');

const JWT_SECRET = process.env.JWT_SECRET || 'clave-local-solo-para-desarrollo';
// Firma las direcciones de las fotos (/images/ID?s=FIRMA) para que no se puedan adivinar.
const MEDIA_SECRET = process.env.MEDIA_SECRET || `${JWT_SECRET}:media`;

module.exports = { isProduction, JWT_SECRET, MEDIA_SECRET };
