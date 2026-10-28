// Arma la aplicación Express: middlewares, rutas por módulo y manejo de errores.
//
//   routes/    → reciben la petición, validan y responden (capa HTTP)
//   services/  → reglas de negocio que comparten varias rutas (acuerdos, subastas, avisos, mercado)
//   serialize  → convierte filas de la base en el JSON (DTO) que consume la app
//   db         → acceso a PostgreSQL
const express = require('express');
const cors = require('cors');
const multer = require('multer');

const { securityHeaders, requestLog, corsOptions } = require('./lib/middleware');

function createApp() {
  const app = express();
  // Railway pone un proxy delante: así req.ip es la IP real del usuario (para el límite de intentos).
  app.set('trust proxy', 1);
  app.disable('x-powered-by');
  app.use(securityHeaders);
  app.use(requestLog);
  app.use(cors(corsOptions()));
  app.use(express.json({ limit: '1mb' }));

  app.use(require('./routes/misc'));
  app.use(require('./routes/images'));
  app.use(require('./routes/auth'));
  app.use(require('./routes/account'));
  app.use(require('./routes/lots'));
  app.use(require('./routes/auctions'));
  app.use(require('./routes/conversations'));
  app.use(require('./routes/agreements'));
  app.use(require('./routes/notifications'));
  app.use(require('./routes/market'));

  app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) return res.status(400).json({ error: 'La imagen es muy grande (máx. 6 MB)' });
    if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON inválido' });
    const status = err.status || 500;
    if (status >= 500) console.error(`Error en ${req.method} ${req.path} id=${req.id}:`, err);
    res.status(status).json({ error: status >= 500 ? 'Error del servidor' : err.message });
  });
  return app;
}

module.exports = { createApp };
