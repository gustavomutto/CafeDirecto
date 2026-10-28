// Política de privacidad pública (Google Play exige una dirección web con la política
// y con las instrucciones para eliminar la cuenta). Se sirve en /privacy.
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function privacyHtml() {
  const contact = process.env.CONTACT_EMAIL
    ? `<p>Contacto: <a href="mailto:${esc(process.env.CONTACT_EMAIL)}">${esc(process.env.CONTACT_EMAIL)}</a></p>`
    : '';
  return `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>CaféDirecto · Política de privacidad</title>
<style>body{font-family:system-ui,Arial,sans-serif;max-width:760px;margin:0 auto;padding:24px 16px;line-height:1.55;color:#2b1d14;background:#fbf7f2}
h1{color:#4e342e}h2{color:#6d4c41;margin-top:28px}li{margin:4px 0}small{color:#8d6e63}</style></head><body>
<h1>CaféDirecto · Política de privacidad</h1>
<small>Versión 3 · octubre de 2026</small>
<p>CaféDirecto conecta caficultores colombianos con compradores de café de especialidad. Esta política explica qué datos
guardamos, para qué y cómo puedes borrarlos.</p>
<h2>Qué datos guardamos</h2>
<ul>
<li><b>Cuenta:</b> nombre, correo, celular (opcional), idioma, foto de perfil y contraseña cifrada (nunca la guardamos en texto plano).</li>
<li><b>Perfil:</b> datos de la finca o de la empresa que tú escribes (región, historia, certificaciones, fotos).</li>
<li><b>Lotes, subastas, ofertas y acuerdos</b> que publicas o en los que participas.</li>
<li><b>Mensajes del chat</b>, sus traducciones y las fotos que envías.</li>
<li><b>Interés en lotes:</b> si eres comprador y abres un lote, el caficultor puede ver que lo viste.</li>
</ul>
<h2>Para qué los usamos</h2>
<ul>
<li>Mostrar tu perfil y tus lotes, permitir el chat traducido, las subastas y registrar los acuerdos.</li>
<li>Enviarte avisos (notificaciones) sobre interés, ofertas, mensajes y acuerdos.</li>
<li>Proteger tu cuenta (límite de intentos de inicio de sesión y recuperación de contraseña por correo).</li>
</ul>
<p>No vendemos tus datos ni los usamos para publicidad.</p>
<h2>Con quién se comparten</h2>
<ul>
<li><b>Railway</b> (alojamiento del servidor y la base de datos).</li>
<li><b>Servicios de traducción</b> (DeepL, Google Translate o MyMemory): reciben el texto de los mensajes para traducirlo.</li>
<li><b>Resend</b>: envía el correo con el código para recuperar la contraseña.</li>
<li>El <b>dictado por voz</b> lo procesa el reconocimiento de voz de tu propio teléfono; CaféDirecto solo recibe el texto.</li>
</ul>
<h2>Fotos</h2>
<p>Las fotos se guardan en nuestra base de datos y solo se pueden abrir con una dirección firmada que entrega la app.</p>
<h2 id="eliminar">Cómo eliminar tu cuenta y tus datos</h2>
<ol>
<li>Abre la app y entra a <b>Perfil</b> (o <b>Mi finca</b>).</li>
<li>Toca <b>Eliminar mi cuenta</b> y confirma con tu contraseña.</li>
</ol>
<p>Se borran de inmediato tu perfil, tus lotes, tus conversaciones, tus fotos, tus ofertas abiertas y tus notificaciones.
Si tienes acuerdos registrados, la otra parte conserva el registro del acuerdo, pero sin tus datos personales
(tu cuenta aparece como «Cuenta eliminada»).</p>
${contact}
<hr><h1>Privacy policy (English)</h1>
<p>CaféDirecto stores your account (name, email, optional phone, language, photo and a hashed password), your profile,
lots, auctions, bids, agreements, chat messages with their translations, photos, and lot views (farmers can see that a
buyer viewed their lot). Data is used only to run the service and send notifications; it is never sold or used for ads.
Processors: Railway (hosting), DeepL/Google/MyMemory (message translation), Resend (password-reset email). Voice
dictation runs on your phone. To delete your account and data, open <b>Profile → Delete my account</b> and confirm with
your password; agreements already recorded are kept for the other party without your personal data.</p>
</body></html>`;
}

module.exports = { privacyHtml };
