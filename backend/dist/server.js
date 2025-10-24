"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
const database_1 = require("./config/database");
const profiles_1 = __importDefault(require("./routes/profiles"));
const devices_1 = __importDefault(require("./routes/devices"));
const users_1 = __importDefault(require("./routes/users"));
const reports_1 = __importDefault(require("./routes/reports"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 8000;
// System middleware
app.use((0, helmet_1.default)({
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
app.use((0, cors_1.default)({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use((0, morgan_1.default)('combined'));
app.use(express_1.default.json({
    limit: '10mb',
    verify: (req, res, buf) => {
        try {
            JSON.parse(buf.toString());
        }
        catch (e) {
            throw new Error('Invalid JSON payload');
        }
    }
}));
app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
// Request validation middleware
app.use((req, res, next) => {
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
app.use(comprehensiveErrorHandler_1.ComprehensiveErrorHandler.handleError);
// Fallback error handler
app.use((err, req, res, next) => {
    const statusCode = err.statusCode || err.status || 500;
    const errorCode = err.code || 'INTERNAL_ERROR';
    const errorResponse = {
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
app.get('/health', async (req, res) => {
    try {
        const dbStart = Date.now();
        const dbResult = await (0, database_1.query)('SELECT 1, NOW() as server_time');
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
    }
    catch (error) {
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
const comprehensiveErrorHandler_1 = require("./middleware/comprehensiveErrorHandler");
const monitoring_1 = __importDefault(require("./routes/monitoring"));
const systemController_1 = require("./controllers/systemController");
const enterpriseController_1 = require("./controllers/enterpriseController");
const cicdController_1 = require("./controllers/cicdController");
const cloudAuthController_1 = require("./controllers/cloudAuthController");
const syncController_1 = require("./controllers/syncController");
const deploymentController_1 = require("./controllers/deploymentController");
// Apply comprehensive middleware
app.use(comprehensiveErrorHandler_1.requestTracker);
app.use(comprehensiveErrorHandler_1.responseLogger);
app.use(comprehensiveErrorHandler_1.healthMonitor);
app.use(comprehensiveErrorHandler_1.inputValidator);
app.use(comprehensiveErrorHandler_1.securityValidator);
app.use(comprehensiveErrorHandler_1.rateLimiter);
// API routes
app.use('/api/v1/profiles', profiles_1.default);
app.use('/api/v1/devices', devices_1.default);
app.use('/api/v1/users', users_1.default);
app.use('/api/v1/reports', reports_1.default);
app.use('/api/v1/intune', require('./routes/intune').default);
app.use('/api/v1/monitoring', monitoring_1.default);
app.use('/api/v1/graph', require('./routes/graphPowerShell').default);
app.use('/api/v1/diagnostics', require('./routes/diagnostics').default);
app.use('/api/v1', require('./routes/enrollment').default);
// System monitoring routes
app.get('/api/v1/system/health', systemController_1.systemController.getSystemHealth.bind(systemController_1.systemController));
app.get('/api/v1/system/status', systemController_1.systemController.getSystemStatus.bind(systemController_1.systemController));
app.get('/api/v1/system/diagnostics', systemController_1.systemController.runDiagnostics.bind(systemController_1.systemController));
app.post('/api/v1/system/auto-fix', systemController_1.systemController.autoFixErrors.bind(systemController_1.systemController));
app.get('/api/v1/system/errors', systemController_1.systemController.getErrorReport.bind(systemController_1.systemController));
app.delete('/api/v1/system/errors', systemController_1.systemController.clearErrors.bind(systemController_1.systemController));
// Enterprise setup routes
app.post('/api/v1/enterprise/setup', enterpriseController_1.enterpriseController.runCompleteSetup.bind(enterpriseController_1.enterpriseController));
app.get('/api/v1/enterprise/validate', enterpriseController_1.enterpriseController.validateSetup.bind(enterpriseController_1.enterpriseController));
app.get('/api/v1/enterprise/status', enterpriseController_1.enterpriseController.getSetupStatus.bind(enterpriseController_1.enterpriseController));
app.post('/api/v1/enterprise/phase/:phaseNumber', enterpriseController_1.enterpriseController.runPhase.bind(enterpriseController_1.enterpriseController));
app.post('/api/v1/enterprise/carrier-groups', enterpriseController_1.enterpriseController.createCarrierGroups.bind(enterpriseController_1.enterpriseController));
app.post('/api/v1/enterprise/compliance-policies', enterpriseController_1.enterpriseController.createCompliancePolicies.bind(enterpriseController_1.enterpriseController));
app.post('/api/v1/enterprise/company-portal', enterpriseController_1.enterpriseController.configureCompanyPortal.bind(enterpriseController_1.enterpriseController));
// CI/CD pipeline routes
app.get('/api/v1/cicd/deployments', cicdController_1.cicdController.getDeploymentStatus.bind(cicdController_1.cicdController));
app.post('/api/v1/cicd/deploy', cicdController_1.cicdController.triggerDeployment.bind(cicdController_1.cicdController));
app.post('/api/v1/cicd/rollback', cicdController_1.cicdController.rollbackDeployment.bind(cicdController_1.cicdController));
app.get('/api/v1/cicd/metrics', cicdController_1.cicdController.getCICDMetrics.bind(cicdController_1.cicdController));
app.post('/api/v1/cicd/validate', cicdController_1.cicdController.validateDeployment.bind(cicdController_1.cicdController));
app.get('/api/v1/cicd/sync', cicdController_1.cicdController.syncGitHubVercel.bind(cicdController_1.cicdController));
// Cloud authentication routes
app.get('/api/v1/auth/status', cloudAuthController_1.cloudAuthController.checkAllAuth.bind(cloudAuthController_1.cloudAuthController));
app.post('/api/v1/auth/login/github', cloudAuthController_1.cloudAuthController.loginGitHub.bind(cloudAuthController_1.cloudAuthController));
app.post('/api/v1/auth/login/vercel', cloudAuthController_1.cloudAuthController.loginVercel.bind(cloudAuthController_1.cloudAuthController));
app.post('/api/v1/auth/login/microsoft-graph', cloudAuthController_1.cloudAuthController.loginMicrosoftGraph.bind(cloudAuthController_1.cloudAuthController));
app.get('/api/v1/auth/validate-sync', cloudAuthController_1.cloudAuthController.validateSync.bind(cloudAuthController_1.cloudAuthController));
app.post('/api/v1/auth/auto-fix', cloudAuthController_1.cloudAuthController.autoFix.bind(cloudAuthController_1.cloudAuthController));
app.post('/api/v1/auth/carrier-groups', cloudAuthController_1.cloudAuthController.createCarrierGroups.bind(cloudAuthController_1.cloudAuthController));
// Sync routes
app.get('/api/v1/sync/status', syncController_1.syncController.checkSyncStatus.bind(syncController_1.syncController));
app.post('/api/v1/sync/update-all', syncController_1.syncController.updateAllData.bind(syncController_1.syncController));
app.get('/api/v1/sync/validate-apis', syncController_1.syncController.validateAPIs.bind(syncController_1.syncController));
app.post('/api/v1/sync/fix-issues', syncController_1.syncController.fixSyncIssues.bind(syncController_1.syncController));
app.get('/api/v1/sync/check-all', syncController_1.syncController.checkAllSystems.bind(syncController_1.syncController));
app.post('/api/v1/sync/update-systems', syncController_1.syncController.updateAllSystems.bind(syncController_1.syncController));
app.post('/api/v1/sync/create-backup', syncController_1.syncController.createBackup.bind(syncController_1.syncController));
app.delete('/api/v1/sync/delete-old/:days', syncController_1.syncController.deleteOldData.bind(syncController_1.syncController));
app.delete('/api/v1/sync/clear-errors', syncController_1.syncController.clearErrors.bind(syncController_1.syncController));
// Deployment error checking routes
app.get('/api/v1/deployment/check-all', deploymentController_1.deploymentController.checkAllDeployments.bind(deploymentController_1.deploymentController));
app.get('/api/v1/deployment/errors', deploymentController_1.deploymentController.getActiveErrors.bind(deploymentController_1.deploymentController));
app.post('/api/v1/deployment/errors/:errorId/resolve', deploymentController_1.deploymentController.resolveError.bind(deploymentController_1.deploymentController));
app.post('/api/v1/deployment/sync-all', deploymentController_1.deploymentController.syncAllPlatforms.bind(deploymentController_1.deploymentController));
app.post('/api/v1/deployment/log-error', deploymentController_1.deploymentController.logError.bind(deploymentController_1.deploymentController));
// Dashboard stats
app.get('/api/v1/dashboard/stats', async (req, res) => {
    try {
        const stats = await Promise.all([
            (0, database_1.query)('SELECT COUNT(*) as total FROM esim_profiles'),
            (0, database_1.query)('SELECT COUNT(*) as active FROM esim_profiles WHERE status = $1', ['active']),
            (0, database_1.query)('SELECT COUNT(*) as total FROM devices'),
            (0, database_1.query)('SELECT COUNT(*) as managed FROM devices WHERE intune_device_id IS NOT NULL'),
            (0, database_1.query)('SELECT COUNT(*) as total FROM users'),
            (0, database_1.query)('SELECT COUNT(*) as total FROM departments')
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
    }
    catch (error) {
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
