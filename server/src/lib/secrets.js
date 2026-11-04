// Claves del servidor.
// JWT_SECRET es obligatoria. Solo en desarrollo o en las pruebas (NODE_ENV=development o test) el
// servidor puede arrancar sin ella, y entonces usa una clave ALEATORIA que dura lo que dura el proceso.
// Nunca hay una clave fija escrita en el código: una clave publicada en GitHub permitiría a
// cualquiera firmar tokens válidos y entrar como cualquier usuario (hallazgo H-01).
const crypto = require('crypto');

const isProduction = process.env.NODE_ENV === 'production' || !!process.env.RAILWAY_ENVIRONMENT || !!process.env.RAILWAY_ENVIRONMENT_NAME;
const devOrTest = !isProduction && ['development', 'test'].includes(process.env.NODE_ENV);

if (!process.env.JWT_SECRET && !devOrTest) {
  console.error(
    'Falta la variable JWT_SECRET (un texto largo y aleatorio, 48 caracteres o más). '
      + 'En Railway agrégala en Variables. Para trabajar en tu computador usa start-local.cmd o NODE_ENV=development.',
  );
  process.exit(1);
}
if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
  console.warn('⚠️  JWT_SECRET es corta; usa al menos 32 caracteres aleatorios.');
}
if (!process.env.JWT_SECRET) {
  console.warn(`⚠️  Sin JWT_SECRET (NODE_ENV=${process.env.NODE_ENV}): se usa una clave aleatoria de esta ejecución; las sesiones se pierden al reiniciar.`);
}

const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(48).toString('hex');
// Firma las direcciones de las fotos (/images/ID?s=FIRMA) para que no se puedan adivinar.
const MEDIA_SECRET = process.env.MEDIA_SECRET || `${JWT_SECRET}:media`;

module.exports = { isProduction, JWT_SECRET, MEDIA_SECRET };
