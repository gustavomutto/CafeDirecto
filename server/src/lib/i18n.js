// Mensajes de error en el idioma de la app.
// Las rutas escriben sus mensajes en español; si la app está en inglés (cabecera Accept-Language
// o, en versiones viejas de la app, el idioma guardado del usuario), se traducen al responder.
// Al agregar un mensaje nuevo en una ruta, agrega aquí su versión en inglés.

const EXACT = {
  // Generales
  'Ruta no encontrada': 'Route not found',
  'No encontrado': 'Not found',
  'No tienes permiso': 'You do not have permission',
  'Error del servidor': 'Server error',
  'JSON inválido': 'Invalid JSON',
  'La imagen es muy grande (máx. 6 MB)': 'The image is too large (max. 6 MB)',
  'Inicia sesión': 'Please log in',
  'Sesión vencida, vuelve a entrar': 'Your session expired, please log in again',

  // Cuenta y acceso
  'Correo inválido': 'Invalid email',
  'Rol inválido': 'Invalid role',
  'Escribe tu nombre': 'Enter your name',
  'Ese correo ya está registrado': 'That email is already registered',
  'Correo o contraseña incorrectos': 'Wrong email or password',
  'No pudimos enviar el correo. Inténtalo más tarde.': 'We could not send the email. Please try again later.',
  'El código no es válido o ya venció. Pide uno nuevo.': 'The code is invalid or expired. Request a new one.',
  'La contraseña no es correcta': 'The password is incorrect',
  'Usuario no encontrado': 'User not found',
  'La altitud debe estar entre 0 y 6.000 m': 'Altitude must be between 0 and 6,000 m',
  'Las hectáreas deben estar entre 0 y 100.000': 'Hectares must be between 0 and 100,000',
  'El puntaje SCA debe estar entre 0 y 100': 'The SCA score must be between 0 and 100',

  // Fotos
  'Falta el archivo (campo "file")': 'Missing file (field "file")',
  'Solo se aceptan imágenes JPG, PNG, WEBP, GIF o HEIC': 'Only JPG, PNG, WEBP, GIF or HEIC images are accepted',
  'Imagen no encontrada': 'Image not found',
  'Una de las fotos no existe o no es tuya. Vuelve a subirla.': 'One of the photos does not exist or is not yours. Upload it again.',

  // Lotes
  'Lote no encontrado': 'Lot not found',
  'Elige la variedad': 'Choose the variety',
  'Proceso inválido': 'Invalid process',
  'CaféDirecto recibe cafés de 80 a 100 puntos': 'CaféDirecto accepts coffees from 80 to 100 points',
  'El precio debe estar entre US$ 0,01 y US$ 100 por libra': 'The price must be between US$ 0.01 and US$ 100 per pound',
  'La cantidad debe estar entre 0 y 100.000 sacos': 'The quantity must be between 0 and 100,000 bags',
  'Precio por carga inválido': 'Invalid price per carga',
  'Solo los caficultores publican lotes': 'Only farmers can publish lots',
  'Este lote tiene una subasta abierta. Cancélala o adjudícala primero.':
    'This lot has an open auction. Cancel or award it first.',

  // Subastas
  'Subasta no encontrada': 'Auction not found',
  'Solo el dueño del lote puede subastarlo': 'Only the owner of the lot can auction it',
  'El precio base debe estar entre US$ 0,01 y US$ 100 por libra': 'The starting price must be between US$ 0.01 and US$ 100 per pound',
  'El incremento mínimo debe estar entre US$ 0,01 y US$ 5': 'The minimum increment must be between US$ 0.01 and US$ 5',
  'La subasta debe durar entre 1 hora y 30 días': 'The auction must last between 1 hour and 30 days',
  'Este lote ya tiene una subasta abierta': 'This lot already has an open auction',
  'Solo los compradores pueden ofertar': 'Only buyers can bid',
  'La subasta ya no recibe ofertas': 'The auction no longer accepts bids',
  'La oferta es demasiado alta; revisa el valor': 'The bid is too high; check the amount',
  'Solo el caficultor puede adjudicar la subasta': 'Only the farmer can award the auction',
  'La subasta ya está cerrada': 'The auction is already closed',
  'Oferta no encontrada': 'Bid not found',

  // Chat y cotizaciones
  'Conversación no encontrada': 'Conversation not found',
  'Solo se puede chatear entre caficultor y comprador': 'Chats are only between a farmer and a buyer',
  'Mensaje vacío': 'Empty message',
  'Falta la foto': 'Missing photo',
  'El lote no pertenece a esta finca': 'The lot does not belong to this farm',
  'Acción inválida': 'Invalid action',
  'Cotización no encontrada': 'Quote not found',
  'No puedes contraofertar esta cotización': 'You cannot counter this quote',
  'Cantidad inválida': 'Invalid quantity',
  'No puedes aceptar esta cotización': 'You cannot accept this quote',
  'Esta cotización no está lista para confirmar': 'This quote is not ready to be confirmed',

  // Acuerdos, calificaciones, calidad y disputas
  'Acuerdo no encontrado': 'Agreement not found',
  'El acuerdo ya fue entregado': 'The agreement was already delivered',
  'El despacho lo marca el caficultor': 'Shipping is marked by the farmer',
  'La entrega la confirma el comprador': 'Delivery is confirmed by the buyer',
  'Solo se califica después de la entrega': 'You can only rate after delivery',
  'Elige de 1 a 5 estrellas': 'Choose 1 to 5 stars',
  'Ya calificaste este acuerdo': 'You already rated this agreement',
  'Solo el comprador emite el reporte de calidad': 'Only the buyer submits the quality report',
  'El reporte de calidad se emite después de la entrega': 'The quality report is submitted after delivery',
  'Ya enviaste el reporte de calidad de este acuerdo': 'You already submitted the quality report for this agreement',
  'La humedad debe estar entre 0 y 100 %': 'Moisture must be between 0 and 100 %',
  'Los defectos no pueden ser negativos': 'Defects cannot be negative',
  'Disputa no encontrada': 'Dispute not found',
  'Elige el motivo de la disputa': 'Choose the reason for the dispute',
  'Describe el problema': 'Describe the problem',
  'Este acuerdo ya tiene una disputa abierta': 'This agreement already has an open dispute',
  'La disputa ya está resuelta': 'The dispute is already resolved',
  'Escribe una respuesta': 'Write a reply',
  'Solo quien abrió la disputa puede darla por resuelta': 'Only whoever opened the dispute can mark it as resolved',
};

// Mensajes con datos variables (cantidades, años, precios).
const PATTERNS = [
  [/^La contraseña debe tener al menos (\d+) caracteres, con letras y números$/, 'The password must have at least $1 characters, with letters and numbers'],
  [/^El lote ya solo tiene (\d+) sacos disponibles$/, 'The lot only has $1 bags left'],
  [/^Cantidad inválida \(disponible: (\d+) sacos\)$/, 'Invalid quantity (available: $1 bags)'],
  [/^La oferta mínima es (.+)\/lb$/, 'The minimum bid is $1/lb'],
  [/^El año debe estar entre (\d+) y (\d+)$/, 'The year must be between $1 and $2'],
  [/^Demasiados intentos\. Espera (\d+) min e inténtalo de nuevo\.$/, 'Too many attempts. Wait $1 min and try again.'],
];

/** Traduce un mensaje al inglés; si no está en la lista, lo deja igual. */
function toEnglish(msg) {
  if (typeof msg !== 'string') return msg;
  if (EXACT[msg]) return EXACT[msg];
  for (const [re, en] of PATTERNS) if (re.test(msg)) return msg.replace(re, en);
  return msg;
}

/** Idioma de la respuesta: el que manda la app; si no lo manda, el del usuario. */
function langOf(req) {
  // Solo cuenta si pide claramente es o en ("*" u otro idioma no dicen nada).
  const first = String(req.get('Accept-Language') || '').trim().toLowerCase().split(/[,;-]/)[0];
  if (first === 'en' || first === 'es') return first;
  return req.user?.lang === 'en' ? 'en' : 'es';
}

/** Middleware: si la respuesta trae { error } y la app está en inglés, lo traduce. */
function localizeErrors(req, res, next) {
  const json = res.json.bind(res);
  res.json = (body) => {
    if (body && typeof body.error === 'string' && langOf(req) === 'en') {
      return json({ ...body, error: toEnglish(body.error) });
    }
    return json(body);
  };
  next();
}

module.exports = { toEnglish, langOf, localizeErrors, EXACT, PATTERNS };
