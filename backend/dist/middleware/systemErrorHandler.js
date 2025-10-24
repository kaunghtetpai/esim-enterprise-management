"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorLogger = exports.securityHeaders = exports.rateLimitHandler = exports.requestValidator = exports.systemHealthCheck = exports.SystemError = void 0;
const database_1 = require("../config/database");
class SystemError extends Error {
    constructor(message, statusCode = 500, code = 'SYSTEM_ERROR', details) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
        Error.captureStackTrace(this, this.constructor);
    }
}
exports.SystemError = SystemError;
const systemHealthCheck = async (req, res, next) => {
    try {
        const healthChecks = await Promise.allSettled([
            checkDatabaseConnection(),
            checkMemoryUsage(),
            checkDiskSpace(),
            checkEnvironmentVariables()
        ]);
        const failures = healthChecks
            .map((result, index) => ({ result, check: ['database', 'memory', 'disk', 'environment'][index] }))
            .filter(({ result }) => result.status === 'rejected')
            .map(({ result, check }) => ({ check, error: result.reason.message }));
        if (failures.length > 0) {
            return res.status(503).json({
                success: false,
                error: 'System health check failed',
                code: 'SYSTEM_HEALTH_FAILURE',
                failures,
                timestamp: new Date().toISOString()
            });
        }
        next();
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: 'Health check system error',
            code: 'HEALTH_CHECK_ERROR',
            timestamp: new Date().toISOString()
        });
    }
};
exports.systemHealthCheck = systemHealthCheck;
const checkDatabaseConnection = async () => {
    try {
        const start = Date.now();
        await (0, database_1.query)('SELECT 1');
        const duration = Date.now() - start;
        if (duration > 5000) {
            throw new Error(`Database response time too slow: ${duration}ms`);
        }
    }
    catch (error) {
        throw new SystemError(`Database connection failed: ${error.message}`, 503, 'DATABASE_ERROR');
    }
};
const checkMemoryUsage = async () => {
    const usage = process.memoryUsage();
    const maxHeapSize = 1024 * 1024 * 1024; // 1GB
    if (usage.heapUsed > maxHeapSize * 0.9) {
        throw new SystemError(`High memory usage: ${Math.round(usage.heapUsed / 1024 / 1024)}MB`, 503, 'MEMORY_ERROR');
    }
};
const checkDiskSpace = async () => {
    try {
        const fs = require('fs');
        const stats = fs.statSync('.');
        // Basic disk check - in production, use proper disk space monitoring
    }
    catch (error) {
        throw new SystemError(`Disk space check failed: ${error.message}`, 503, 'DISK_ERROR');
    }
};
const checkEnvironmentVariables = async () => {
    const required = ['DATABASE_URL', 'JWT_SECRET', 'AZURE_CLIENT_ID', 'AZURE_TENANT_ID'];
    const missing = required.filter(env => !process.env[env]);
    if (missing.length > 0) {
        throw new SystemError(`Missing environment variables: ${missing.join(', ')}`, 503, 'ENV_ERROR');
    }
};
const requestValidator = (req, res, next) => {
    try {
        // Validate request size
        const contentLength = parseInt(req.get('content-length') || '0');
        if (contentLength > 10 * 1024 * 1024) { // 10MB limit
            return res.status(413).json({
                success: false,
                error: 'Request payload too large',
                code: 'PAYLOAD_TOO_LARGE',
                maxSize: '10MB',
                timestamp: new Date().toISOString()
            });
        }
        // Validate content type for POST/PUT
        if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
            const contentType = req.get('content-type');
            if (!contentType || !contentType.includes('application/json')) {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid content type. Expected application/json',
                    code: 'INVALID_CONTENT_TYPE',
                    timestamp: new Date().toISOString()
                });
            }
        }
        // Validate request headers
        const userAgent = req.get('user-agent');
        if (!userAgent) {
            return res.status(400).json({
                success: false,
                error: 'User-Agent header is required',
                code: 'MISSING_USER_AGENT',
                timestamp: new Date().toISOString()
            });
        }
        next();
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: 'Request validation failed',
            code: 'REQUEST_VALIDATION_ERROR',
            timestamp: new Date().toISOString()
        });
    }
};
exports.requestValidator = requestValidator;
const rateLimitHandler = (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const key = `rate_limit_${ip}`;
    // Simple in-memory rate limiting (use Redis in production)
    const requests = global[key] || { count: 0, resetTime: Date.now() + 60000 };
    if (Date.now() > requests.resetTime) {
        requests.count = 0;
        requests.resetTime = Date.now() + 60000;
    }
    requests.count++;
    global[key] = requests;
    if (requests.count > 100) { // 100 requests per minute
        return res.status(429).json({
            success: false,
            error: 'Rate limit exceeded',
            code: 'RATE_LIMIT_EXCEEDED',
            retryAfter: Math.ceil((requests.resetTime - Date.now()) / 1000),
            timestamp: new Date().toISOString()
        });
    }
    next();
};
exports.rateLimitHandler = rateLimitHandler;
const securityHeaders = (req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'");
    next();
};
exports.securityHeaders = securityHeaders;
const errorLogger = (error, req, res, next) => {
    const errorLog = {
        timestamp: new Date().toISOString(),
        method: req.method,
        url: req.url,
        ip: req.ip,
        userAgent: req.get('user-agent'),
        error: {
            message: error.message,
            stack: error.stack,
            code: error.code,
            statusCode: error.statusCode
        },
        requestBody: req.method !== 'GET' ? req.body : undefined,
        requestParams: req.params,
        requestQuery: req.query
    };
    console.error('EPM System Error:', JSON.stringify(errorLog, null, 2));
    // Log to database for audit trail
    try {
        (0, database_1.query)(`
      INSERT INTO system_error_logs (timestamp, method, url, ip, error_details, request_data)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [
            errorLog.timestamp,
            errorLog.method,
            errorLog.url,
            errorLog.ip,
            JSON.stringify(errorLog.error),
            JSON.stringify({ body: errorLog.requestBody, params: errorLog.requestParams, query: errorLog.requestQuery })
        ]).catch(dbError => console.error('Failed to log error to database:', dbError));
    }
    catch (dbError) {
        console.error('Database error logging failed:', dbError);
    }
    next(error);
};
exports.errorLogger = errorLogger;
//# sourceMappingURL=systemErrorHandler.js.map