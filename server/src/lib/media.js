// Fotos: firma de direcciones, detección del tipo real del archivo y verificación de dueño.
const crypto = require('crypto');
const { MEDIA_SECRET } = require('./secrets');

/** Firma corta (16 caracteres) del id de una imagen. */
function signature(id) {
  return crypto.createHmac('sha256', MEDIA_SECRET).update(String(id)).digest('base64url').slice(0, 16);
}

/** Dirección pública de una imagen: /images/ID?s=FIRMA (sin la firma no se puede abrir). */
const mediaPath = (id) => (id ? `/images/${id}?s=${signature(id)}` : null);

function validSignature(id, s) {
  if (typeof s !== 'string' || s.length !== 16) return false;
  const a = Buffer.from(signature(id));
  const b = Buffer.from(s);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/**
 * Tipo real de la imagen según sus primeros bytes (no se confía en lo que diga el teléfono).
 * Devuelve el MIME o null si no es una imagen permitida.
 */
function sniffImage(buf) {
  if (!buf || buf.length < 12) return null;
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'image/jpeg';
  if (buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (buf.subarray(0, 4).toString('ascii') === 'GIF8') return 'image/gif';
  if (buf.subarray(0, 4).toString('ascii') === 'RIFF' && buf.subarray(8, 12).toString('ascii') === 'WEBP') return 'image/webp';
  if (buf.subarray(4, 8).toString('ascii') === 'ftyp') {
    const brand = buf.subarray(8, 12).toString('ascii');
    if (['heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'].includes(brand)) return 'image/heic';
  }
  return null;
}

module.exports = { mediaPath, validSignature, sniffImage, signature };
