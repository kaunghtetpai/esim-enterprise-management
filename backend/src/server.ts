import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { query } from './config/database';
import profileRoutes from './routes/profiles';
import deviceRoutes from './routes/devices';
import userRoutes from './routes/users';
import reportRoutes from './routes/reports';


dotenv.config();

const app = express();
const PORT = process.env.PORT || 8000;

// System middleware
app.use(securityHeaders);
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://graph.microsoft.com", "https://login.microsoftonline.com"]
    }
  }
}));
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(morgan('combined'));
app.use(rateLimitHandler);
app.use(requestValidator);
app.use(express.json({ 
  limit: '10mb',
  verify: (req, res, buf) => {
    try {
      JSON.parse(buf.toString());
    } catch (e) {
      throw new SystemError('Invalid JSON payload', 400, 'INVALID_JSON');
    }
  }
}));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request validation middleware
app.use((req: express.Request, res: express.Response, next: express.NextFunction) => {
  if (req.method === 'POST' || req.method === 'PUT') {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Request body is required',
        code: 'MISSING_BODY'
      });
    }
  }
  next();
});

// Use comprehensive error handler
app.use(ComprehensiveErrorHandler.handleError);

// Fallback error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  const statusCode = err.statusCode || err.status || 500;
  const errorCode = err.code || 'INTERNAL_ERROR';
  
  const errorResponse: any = {
    success: false,
    error: err.message || 'Internal server error',
    code: errorCode,
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method,
    requestId: req.headers['x-request-id'] || `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  };
  
  // Add error details for specific error types
  if (err.details) {
    errorResponse.details = err.details;
  }
  
  // Add validation errors
  if (err.name === 'ValidationError' && err.errors) {
    errorResponse.validationErrors = Object.keys(err.errors).map(key => ({
      field: key,
      message: err.errors[key].message
    }));
  }
  
  // Add stack trace in development
  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
  }
  
  // Log critical errors
  if (statusCode >= 500) {
    console.error('CRITICAL EPM ERROR:', {
      requestId: errorResponse.requestId,
      error: err.message,
      stack: err.stack,
      url: req.url,
      method: req.method,
      body: req.body,
      user: req.user?.userId || 'anonymous'
    });
  }
  
  res.status(statusCode).json(errorResponse);
});

// System health check endpoint
app.get('/health', systemHealthCheck, async (req, res) => {
  try {
    const dbStart = Date.now();
    const dbResult = await query('SELECT 1, NOW() as server_time');
    const dbTime = Date.now() - dbStart;
    
    const systemStats = {
      success: true,
      status: 'HEALTHY',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      database: {
        status: 'connected',
        responseTime: `${dbTime}ms`,
        serverTime: dbResult.rows[0]?.server_time
      },
      system: {
        uptime: Math.floor(process.uptime()),
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
          external: Math.round(process.memoryUsage().external / 1024 / 1024)
        },
        cpu: process.cpuUsage(),
        platform: process.platform,
        nodeVersion: process.version
      },
      services: {
        intune: process.env.AZURE_CLIENT_ID ? 'configured' : 'not_configured',
        database: 'connected',
        redis: process.env.REDIS_URL ? 'configured' : 'not_configured'
      }
    };
    
    res.json(systemStats);
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({ 
      success: false,
      status: 'UNHEALTHY', 
      timestamp: new Date().toISOString(),
      error: error.message,
      code: 'HEALTH_CHECK_FAILED'
    });
  }
});

// Import comprehensive error handler
import { ComprehensiveErrorHandler, requestTracker, responseLogger, healthMonitor, inputValidator, securityValidator, rateLimiter } from './middleware/comprehensiveErrorHandler';
import monitoringRoutes from './routes/monitoring';
import { systemController } from './controllers/systemController';
import { enterpriseController } from './controllers/enterpriseController';
import { cicdController } from './controllers/cicdController';
import { cloudAuthController } from './controllers/cloudAuthController';
import { syncController } from './controllers/syncController';
import { deploymentController } from './controllers/deploymentController';

// Apply comprehensive middleware
app.use(requestTracker);
app.use(responseLogger);
app.use(healthMonitor);
app.use(inputValidator);
app.use(securityValidator);
app.use(rateLimiter);

// API routes
app.use('/api/v1/profiles', profileRoutes);
app.use('/api/v1/devices', deviceRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/intune', require('./routes/intune').default);
app.use('/api/v1/monitoring', monitoringRoutes);
app.use('/api/v1/graph', require('./routes/graphPowerShell').default);
app.use('/api/v1/diagnostics', require('./routes/diagnostics').default);
app.use('/api/v1', require('./routes/enrollment').default);

// System monitoring routes
app.get('/api/v1/system/health', systemController.getSystemHealth.bind(systemController));
app.get('/api/v1/system/status', systemController.getSystemStatus.bind(systemController));
app.get('/api/v1/system/diagnostics', systemController.runDiagnostics.bind(systemController));
app.post('/api/v1/system/auto-fix', systemController.autoFixErrors.bind(systemController));
app.get('/api/v1/system/errors', systemController.getErrorReport.bind(systemController));
app.delete('/api/v1/system/errors', systemController.clearErrors.bind(systemController));

// Enterprise setup routes
app.post('/api/v1/enterprise/setup', enterpriseController.runCompleteSetup.bind(enterpriseController));
app.get('/api/v1/enterprise/validate', enterpriseController.validateSetup.bind(enterpriseController));
app.get('/api/v1/enterprise/status', enterpriseController.getSetupStatus.bind(enterpriseController));
app.post('/api/v1/enterprise/phase/:phaseNumber', enterpriseController.runPhase.bind(enterpriseController));
app.post('/api/v1/enterprise/carrier-groups', enterpriseController.createCarrierGroups.bind(enterpriseController));
app.post('/api/v1/enterprise/compliance-policies', enterpriseController.createCompliancePolicies.bind(enterpriseController));
app.post('/api/v1/enterprise/company-portal', enterpriseController.configureCompanyPortal.bind(enterpriseController));

// CI/CD pipeline routes
app.get('/api/v1/cicd/deployments', cicdController.getDeploymentStatus.bind(cicdController));
app.post('/api/v1/cicd/deploy', cicdController.triggerDeployment.bind(cicdController));
app.post('/api/v1/cicd/rollback', cicdController.rollbackDeployment.bind(cicdController));
app.get('/api/v1/cicd/metrics', cicdController.getCICDMetrics.bind(cicdController));
app.post('/api/v1/cicd/validate', cicdController.validateDeployment.bind(cicdController));
app.get('/api/v1/cicd/sync', cicdController.syncGitHubVercel.bind(cicdController));

// Cloud authentication routes
app.get('/api/v1/auth/status', cloudAuthController.checkAllAuth.bind(cloudAuthController));
app.post('/api/v1/auth/login/github', cloudAuthController.loginGitHub.bind(cloudAuthController));
app.post('/api/v1/auth/login/vercel', cloudAuthController.loginVercel.bind(cloudAuthController));
app.post('/api/v1/auth/login/microsoft-graph', cloudAuthController.loginMicrosoftGraph.bind(cloudAuthController));
app.get('/api/v1/auth/validate-sync', cloudAuthController.validateSync.bind(cloudAuthController));
app.post('/api/v1/auth/auto-fix', cloudAuthController.autoFix.bind(cloudAuthController));
app.post('/api/v1/auth/carrier-groups', cloudAuthController.createCarrierGroups.bind(cloudAuthController));

// Sync routes
app.get('/api/v1/sync/status', syncController.checkSyncStatus.bind(syncController));
app.post('/api/v1/sync/update-all', syncController.updateAllData.bind(syncController));
app.get('/api/v1/sync/validate-apis', syncController.validateAPIs.bind(syncController));
app.post('/api/v1/sync/fix-issues', syncController.fixSyncIssues.bind(syncController));
app.get('/api/v1/sync/check-all', syncController.checkAllSystems.bind(syncController));
app.post('/api/v1/sync/update-systems', syncController.updateAllSystems.bind(syncController));
app.post('/api/v1/sync/create-backup', syncController.createBackup.bind(syncController));
app.delete('/api/v1/sync/delete-old/:days', syncController.deleteOldData.bind(syncController));
app.delete('/api/v1/sync/clear-errors', syncController.clearErrors.bind(syncController));

// Deployment error checking routes
app.get('/api/v1/deployment/check-all', deploymentController.checkAllDeployments.bind(deploymentController));
app.get('/api/v1/deployment/errors', deploymentController.getActiveErrors.bind(deploymentController));
app.post('/api/v1/deployment/errors/:errorId/resolve', deploymentController.resolveError.bind(deploymentController));
app.post('/api/v1/deployment/sync-all', deploymentController.syncAllPlatforms.bind(deploymentController));
app.post('/api/v1/deployment/log-error', deploymentController.logError.bind(deploymentController));

// Dashboard stats
app.get('/api/v1/dashboard/stats', async (req, res) => {
  try {
    const stats = await Promise.all([
      query('SELECT COUNT(*) as total FROM esim_profiles'),
      query('SELECT COUNT(*) as active FROM esim_profiles WHERE status = $1', ['active']),
      query('SELECT COUNT(*) as total FROM devices'),
      query('SELECT COUNT(*) as managed FROM devices WHERE intune_device_id IS NOT NULL'),
      query('SELECT COUNT(*) as total FROM users'),
      query('SELECT COUNT(*) as total FROM departments')
    ]);
    
    res.json({
      success: true,
      data: {
        totalProfiles: parseInt(stats[0].rows[0].total),
        activeProfiles: parseInt(stats[1].rows[0].active),
        totalDevices: parseInt(stats[2].rows[0].total),
        managedDevices: parseInt(stats[3].rows[0].managed),
        totalUsers: parseInt(stats[4].rows[0].total),
        departments: parseInt(stats[5].rows[0].total),
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
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dashboard statistics',
      code: 'DASHBOARD_STATS_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    success: false,
    error: 'Endpoint not found',
    code: 'ENDPOINT_NOT_FOUND',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

const server = app.listen(PORT, () => {
  console.log(`EPM Portal Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API endpoints: http://localhost:${PORT}/api/v1`);
  console.log(`System ready for eSIM enterprise management`);
});

server.timeout = 30000; // 30 second timeout
server.keepAliveTimeout = 65000; // Keep alive timeout
server.headersTimeout = 66000; // Headers timeout