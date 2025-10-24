"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getClient = exports.query = exports.supabase = void 0;
const pg_1 = require("pg");
const supabase_js_1 = require("@supabase/supabase-js");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
exports.supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseKey);
// PostgreSQL pool for direct queries
const pool = new pg_1.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    max: parseInt(process.env.DATABASE_POOL_SIZE || '20'),
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
});
const query = async (text, params) => {
    try {
        const result = await pool.query(text, params);
        return result;
    }
    catch (error) {
        console.error('Database query error:', error);
        throw error;
    }
};
exports.query = query;
const getClient = () => pool.connect();
exports.getClient = getClient;
// Test database connection
pool.on('connect', () => {
    console.log('Connected to Supabase PostgreSQL database');
});
pool.on('error', (err) => {
    console.error('Database connection error:', err);
});
exports.default = pool;
//# sourceMappingURL=database.js.map