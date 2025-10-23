import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API routes
app.get('/api/v1/dashboard/stats', (req, res) => {
  try {
    res.json({
      totalProfiles: 150,
      activeProfiles: 120,
      totalDevices: 200,
      managedDevices: 180,
      totalUsers: 50,
      departments: 8,
      pendingActivations: 5,
      failedActivations: 2,
      monthlyUsage: [
        { carrier: 'MPT', usage: 1500, cost: 45.50 },
        { carrier: 'ATOM', usage: 1200, cost: 38.20 },
        { carrier: 'U9', usage: 800, cost: 25.10 },
        { carrier: 'MYTEL', usage: 950, cost: 30.75 }
      ],
      recentActivities: [
        {
          id: '1',
          action: 'Profile Activated',
          user: 'Admin User',
          timestamp: new Date().toISOString(),
          status: 'success'
        }
      ]
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dashboard statistics' });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});