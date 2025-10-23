import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: parseInt(process.env.DATABASE_POOL_SIZE || '20'),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

export const query = async (text: string, params?: any[]) => {
  try {
    const result = await pool.query(text, params);
    return result;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

export const getClient = () => pool.connect();

// Test database connection
pool.on('connect', () => {
  console.log('Connected to Supabase PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('Database connection error:', err);
});

export default pool;