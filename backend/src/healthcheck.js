const http = require('http');
const { Client } = require('pg');

const PORT = process.env.PORT || 8000;
const DATABASE_URL = process.env.DATABASE_URL;

async function healthCheck() {
  try {
    // Check HTTP server
    const serverCheck = new Promise((resolve, reject) => {
      const req = http.request({
        hostname: 'localhost',
        port: PORT,
        path: '/health',
        method: 'GET',
        timeout: 5000
      }, (res) => {
        if (res.statusCode === 200) {
          resolve('Server OK');
        } else {
          reject(new Error(`Server returned status ${res.statusCode}`));
        }
      });

      req.on('error', (err) => {
        reject(new Error(`Server request failed: ${err.message}`));
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Server request timeout'));
      });

      req.end();
    });

    // Check database connection
    const dbCheck = new Promise((resolve, reject) => {
      if (!DATABASE_URL) {
        reject(new Error('DATABASE_URL not configured'));
        return;
      }

      const client = new Client({ connectionString: DATABASE_URL });
      
      const timeout = setTimeout(() => {
        client.end();
        reject(new Error('Database connection timeout'));
      }, 5000);

      client.connect()
        .then(() => client.query('SELECT 1'))
        .then(() => {
          clearTimeout(timeout);
          client.end();
          resolve('Database OK');
        })
        .catch((err) => {
          clearTimeout(timeout);
          client.end();
          reject(new Error(`Database check failed: ${err.message}`));
        });
    });

    // Run both checks
    const [serverResult, dbResult] = await Promise.all([serverCheck, dbCheck]);
    
    console.log('Health check passed:', { server: serverResult, database: dbResult });
    process.exit(0);
    
  } catch (error) {
    console.error('Health check failed:', error.message);
    process.exit(1);
  }
}

// Handle timeout
const timeout = setTimeout(() => {
  console.error('Health check timeout after 10 seconds');
  process.exit(1);
}, 10000);

healthCheck().finally(() => {
  clearTimeout(timeout);
});