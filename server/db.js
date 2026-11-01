const { Pool } = require('pg');
require('dotenv').config();

const connStr = (process.env.DATABASE_URL || '').replace('?sslmode=require', '');

const pool = new Pool({
  connectionString: connStr,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('connect', () => {
  console.log('Connected to PostgreSQL pool (Supabase).');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle Neon PostgreSQL client:', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
