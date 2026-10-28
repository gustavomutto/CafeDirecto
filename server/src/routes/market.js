// Precios del café: precio interno (FNC), bolsa de Nueva York y TRM. Es público (también lo ve
// quien todavía no tiene cuenta) y tiene un límite de consultas por IP.
const express = require('express');

const { limit } = require('../ratelimit');
const { coffeeMarket } = require('../services/market');
const { h, MIN } = require('../lib/http');

const r = express.Router();

r.get('/market/coffee', limit('market', 60, MIN), h(async (req, res) => {
  res.set('Cache-Control', 'public, max-age=300');
  res.json(await coffeeMarket());
}));

module.exports = r;
