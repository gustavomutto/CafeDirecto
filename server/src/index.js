// API de CaféDirecto (Express + PostgreSQL). Pensada para desplegarse en Railway.
// Arranque: migra la base, inicia el proceso de subastas y abre el puerto.
const { migrate } = require('./db');
const { providerName } = require('./translate');
const { createApp } = require('./app');
const { startAuctionJob } = require('./services/auctions');

const PORT = process.env.PORT || 3000;

migrate()
  .then(() => {
    startAuctionJob();
    createApp().listen(PORT, () => console.log(`CaféDirecto API escuchando en el puerto ${PORT} · traductor: ${providerName()}`));
  })
  .catch((e) => {
    console.error('No se pudo preparar la base de datos:', e);
    process.exit(1);
  });
