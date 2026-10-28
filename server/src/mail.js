// Envío de correos con Resend (https://resend.com) usando su API HTTP, sin dependencias.
// Variables: RESEND_API_KEY y MAIL_FROM (por ejemplo "CaféDirecto <no-reply@tudominio.com>").
// Sin RESEND_API_KEY, en desarrollo el correo se muestra en la consola del servidor.
const { isProduction } = require('./lib/secrets');

const configured = () => !!process.env.RESEND_API_KEY && !!process.env.MAIL_FROM;

if (!configured()) {
  console.warn(isProduction
    ? '⚠️  Falta RESEND_API_KEY o MAIL_FROM: la recuperación de contraseña no podrá enviar correos.'
    : 'ℹ️  Sin RESEND_API_KEY: los correos (códigos de recuperación) se muestran en esta consola.');
}

async function sendMail({ to, subject, text }) {
  if (!configured()) {
    if (isProduction) throw new Error('Correo no configurado');
    console.log(`\n── Correo (desarrollo) ──\nPara: ${to}\nAsunto: ${subject}\n\n${text}\n─────────────────────────\n`);
    return;
  }
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 10000);
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: process.env.MAIL_FROM, to: [to], subject, text }),
      signal: ctrl.signal,
    });
    if (!res.ok) throw new Error(`Resend respondió ${res.status}: ${(await res.text()).slice(0, 200)}`);
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { sendMail, mailConfigured: configured };
