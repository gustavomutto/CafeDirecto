// API de CaféDirecto (Express + PostgreSQL). Pensada para desplegarse en Railway.
// Arranque: migra la base, inicia el proceso de subastas y abre el puerto.
// Al recibir SIGTERM (Railway lo envía en cada despliegue) termina ordenadamente.
const { pool, migrate } = require('./db');
const { providerName } = require('./translate');
const { createApp } = require('./app');
const { startAuctionJob, stopAuctionJob } = require('./services/auctions');

const PORT = process.env.PORT || 3000;
let server;

async function start() {
  await migrate();
  startAuctionJob();
  server = createApp().listen(PORT, () => console.log(`CaféDirecto API escuchando en el puerto ${PORT} · traductor: ${providerName()}`));
}

function shutdown(signal) {
  console.log(`${signal} recibido: cerrando…`);
  stopAuctionJob();
  const done = () => pool.end().finally(() => process.exit(0));
  if (server) server.close(done);
  else done();
  setTimeout(() => process.exit(1), 10000).unref(); // por si algo se queda colgado
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (e) => console.error('Promesa sin manejar:', e));

start().catch((e) => {
  console.error('No se pudo preparar la base de datos:', e);
  process.exit(1);
});
