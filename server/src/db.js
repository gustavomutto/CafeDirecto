// Conexión a PostgreSQL. Railway entrega la URL en la variable DATABASE_URL.
const fs = require('fs');
const path = require('path');
const { Pool, types } = require('pg');

// NUMERIC llega como texto por defecto; lo convertimos a número.
types.setTypeParser(1700, (v) => (v === null ? null : parseFloat(v)));

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('Falta la variable DATABASE_URL (en Railway: agrega una base PostgreSQL y referencia su DATABASE_URL).');
  process.exit(1);
}

const local = /localhost|127\.0\.0\.1|\.railway\.internal/.test(url);
const pool = new Pool({
  connectionString: url,
  ssl: local || process.env.PGSSL === 'off' ? false : { rejectUnauthorized: false },
  max: 10,
});

const q = (text, params) => pool.query(text, params);
const one = async (text, params) => (await pool.query(text, params)).rows[0] || null;
const many = async (text, params) => (await pool.query(text, params)).rows;

async function migrate() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(sql);
}

module.exports = { pool, q, one, many, migrate };
