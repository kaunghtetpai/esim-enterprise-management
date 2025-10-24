"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.corsErrorHandler = exports.rateLimitHandler = exports.timeoutHandler = exports.handleUncaughtException = exports.handleUnhandledRejection = exports.notFoundHandler = exports.globalErrorHandler = exports.asyncHandler = exports.handleDatabaseError = exports.AppError = void 0;
// Custom error class
class AppError extends Error {
    constructor(message, statusCode, code = 'INTERNAL_ERROR') {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}
exports.AppError = AppError;
// Database error handler
const handleDatabaseError = (error) => {
    switch (error.code) {
        case '23505': // Unique violation
            return new AppError('Duplicate entry found', 409, 'DUPLICATE_ENTRY');
        case '23503': // Foreign key violation
            return new AppError('Invalid reference to related data', 400, 'INVALID_REFERENCE');
        case '23502': // Not null violation
            return new AppError('Required field is missing', 400, 'MISSING_REQUIRED_FIELD');
        case '23514': // Check violation
            return new AppError('Data validation failed', 400, 'VALIDATION_FAILED');
        case '42P01': // Undefined table
            return new AppError('Database table not found', 500, 'TABLE_NOT_FOUND');
        case '42703': // Undefined column
            return new AppError('Database column not found', 500, 'COLUMN_NOT_FOUND');
        case '08003': // Connection does not exist
        case '08006': // Connection failure
            return new AppError('Database connection failed', 503, 'DATABASE_CONNECTION_ERROR');
        case '53300': // Too many connections
            return new AppError('Database connection limit reached', 503, 'CONNECTION_LIMIT_REACHED');
        default:
            return new AppError('Database operation failed', 500, 'DATABASE_ERROR');
    }
};
exports.handleDatabaseError = handleDatabaseError;
// Async error wrapper
const asyncHandler = (fn) => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};
exports.asyncHandler = asyncHandler;
// Global error handler middleware
const globalErrorHandler = (err, req, res, next) => {
    let error = { ...err };
    error.message = err.message;
    // Log error details
    console.error('Error Details:', {
        message: error.message,
        stack: error.stack,
        url: req.url,
        method: req.method,
        body: req.body,
        params: req.params,
        query: req.query,
        timestamp: new Date().toISOString(),
        userAgent: req.get('User-Agent'),
        ip: req.ip
    });
    // Handle specific error types
    if (error.code && error.code.startsWith('23')) {
        error = (0, exports.handleDatabaseError)(error);
    }
    // Handle JWT errors
    if (error.name === 'JsonWebTokenError') {
        error = new AppError('Invalid token', 401, 'INVALID_TOKEN');
    }
    if (error.name === 'TokenExpiredError') {
        error = new AppError('Token expired', 401, 'TOKEN_EXPIRED');
    }
    // Handle validation errors
    if (error.name === 'ValidationError') {
        const message = Object.values(error.errors).map((val) => val.message).join(', ');
        error = new AppError(message, 400, 'VALIDATION_ERROR');
    }
    // Handle cast errors
    if (error.name === 'CastError') {
        error = new AppError('Invalid data format', 400, 'INVALID_DATA_FORMAT');
    }
    // Handle syntax errors
    if (error instanceof SyntaxError) {
        error = new AppError('Invalid JSON format', 400, 'INVALID_JSON');
    }
    // Handle rate limit errors
    if (error.message && error.message.includes('Too many requests')) {
        error = new AppError('Too many requests', 429, 'RATE_LIMIT_EXCEEDED');
    }
    // Default error response
    const statusCode = error.statusCode || 500;
    const errorResponse = {
        success: false,
        error: error.message || 'Internal server error',
        code: error.code || 'INTERNAL_ERROR',
        timestamp: new Date().toISOString(),
        path: req.originalUrl,
        method: req.method
    };
    // Add stack trace in development
    if (process.env.NODE_ENV === 'development') {
        errorResponse.stack = error.stack;
    }
    // Add request ID if available
    if (req.headers['x-request-id']) {
        errorResponse.requestId = req.headers['x-request-id'];
    }
    res.status(statusCode).json(errorResponse);
};
exports.globalErrorHandler = globalErrorHandler;
// 404 handler
const notFoundHandler = (req, res, next) => {
    const error = new AppError(`Route ${req.originalUrl} not found`, 404, 'ROUTE_NOT_FOUND');
    next(error);
};
exports.notFoundHandler = notFoundHandler;
// Unhandled promise rejection handler
const handleUnhandledRejection = () => {
    process.on('unhandledRejection', (reason, promise) => {
        console.error('Unhandled Promise Rejection:', {
            reason: reason.message || reason,
            stack: reason.stack,
            timestamp: new Date().toISOString()
        });
        // Graceful shutdown
        process.exit(1);
    });
};
exports.handleUnhandledRejection = handleUnhandledRejection;
// Uncaught exception handler
const handleUncaughtException = () => {
    process.on('uncaughtException', (error) => {
        console.error('Uncaught Exception:', {
            message: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString()
        });
        // Graceful shutdown
        process.exit(1);
    });
};
exports.handleUncaughtException = handleUncaughtException;
// Request timeout handler
const timeoutHandler = (timeout = 30000) => {
    return (req, res, next) => {
        const timer = setTimeout(() => {
            if (!res.headersSent) {
                res.status(408).json({
                    success: false,
                    error: 'Request timeout',
                    code: 'REQUEST_TIMEOUT',
                    timestamp: new Date().toISOString()
                });
            }
        }, timeout);
        res.on('finish', () => {
            clearTimeout(timer);
        });
        next();
    };
};
exports.timeoutHandler = timeoutHandler;
// Rate limiting error handler
const rateLimitHandler = (req, res) => {
    res.status(429).json({
        success: false,
        error: 'Too many requests from this IP',
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: Math.round(req.rateLimit?.resetTime / 1000) || 60,
        timestamp: new Date().toISOString()
    });
};
exports.rateLimitHandler = rateLimitHandler;
// CORS error handler
const corsErrorHandler = (req, res, next) => {
    const origin = req.headers.origin;
    const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];
    if (origin && !allowedOrigins.includes(origin)) {
        return res.status(403).json({
            success: false,
            error: 'CORS policy violation',
            code: 'CORS_ERROR',
            timestamp: new Date().toISOString()
        });
    }
    next();
};
exports.corsErrorHandler = corsErrorHandler;
