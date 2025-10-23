import { Request, Response, NextFunction } from 'express';
import { query } from '../config/database';

interface ErrorMetrics {
  totalErrors: number;
  errorsByType: Record<string, number>;
  errorsByEndpoint: Record<string, number>;
  lastError: Date;
}

class ComprehensiveErrorHandler {
  private static metrics: ErrorMetrics = {
    totalErrors: 0,
    errorsByType: {},
    errorsByEndpoint: {},
    lastError: new Date()
  };

  static async logError(req: Request, error: any, responseTime?: number): Promise<void> {
    try {
      const errorLog = {
        timestamp: new Date().toISOString(),
        requestId: req.headers['x-request-id'] || `req_${Date.now()}`,
        method: req.method,
        url: req.originalUrl,
        ip: req.ip,
        userAgent: req.get('user-agent'),
        userId: req.user?.userId || null,
        statusCode: error.statusCode || 500,
        errorCode: error.code || 'UNKNOWN_ERROR',
        errorMessage: error.message,
        stack: error.stack,
        requestBody: req.method !== 'GET' ? req.body : null,
        responseTime: responseTime || 0
      };

      await query(`
        INSERT INTO system_error_logs (
          timestamp, method, url, ip, error_details, request_data, user_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, [
        errorLog.timestamp,
        errorLog.method,
        errorLog.url,
        errorLog.ip,
        JSON.stringify({
          code: errorLog.errorCode,
          message: errorLog.errorMessage,
          stack: errorLog.stack,
          statusCode: errorLog.statusCode
        }),
        JSON.stringify({
          body: errorLog.requestBody,
          userAgent: errorLog.userAgent,
          requestId: errorLog.requestId
        }),
        errorLog.userId
      ]);

      this.updateMetrics(errorLog.errorCode, errorLog.url);
    } catch (logError) {
      console.error('Failed to log error:', logError);
    }
  }

  private static updateMetrics(errorCode: string, endpoint: string): void {
    this.metrics.totalErrors++;
    this.metrics.errorsByType[errorCode] = (this.metrics.errorsByType[errorCode] || 0) + 1;
    this.metrics.errorsByEndpoint[endpoint] = (this.metrics.errorsByEndpoint[endpoint] || 0) + 1;
    this.metrics.lastError = new Date();
  }

  static getMetrics(): ErrorMetrics {
    return { ...this.metrics };
  }

  static handleError = async (error: any, req: Request, res: Response, next: NextFunction) => {
    const startTime = req.startTime || Date.now();
    const responseTime = Date.now() - startTime;

    await this.logError(req, error, responseTime);

    const statusCode = error.statusCode || error.status || 500;
    const errorResponse = {
      success: false,
      error: this.getUserFriendlyMessage(error),
      code: error.code || 'INTERNAL_ERROR',
      timestamp: new Date().toISOString(),
      requestId: req.headers['x-request-id'],
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    };

    res.status(statusCode).json(errorResponse);
  };

  private static getUserFriendlyMessage(error: any): string {
    const errorMessages: Record<string, string> = {
      'VALIDATION_ERROR': 'Please check your input and try again',
      'AUTHENTICATION_FAILED': 'Please log in to continue',
      'AUTHORIZATION_FAILED': 'You do not have permission to perform this action',
      'RESOURCE_NOT_FOUND': 'The requested resource was not found',
      'DUPLICATE_RESOURCE': 'This resource already exists',
      'RATE_LIMIT_EXCEEDED': 'Too many requests. Please wait before trying again',
      'DATABASE_ERROR': 'A database error occurred. Please try again later',
      'NETWORK_ERROR': 'Network connection failed. Please check your connection',
      'TIMEOUT_ERROR': 'Request timed out. Please try again',
      'INVALID_INPUT': 'Invalid input provided. Please check your data',
      'SERVICE_UNAVAILABLE': 'Service is temporarily unavailable. Please try again later'
    };

    return errorMessages[error.code] || error.message || 'An unexpected error occurred';
  }
}

export const requestTracker = (req: Request, res: Response, next: NextFunction) => {
  req.startTime = Date.now();
  req.headers['x-request-id'] = req.headers['x-request-id'] || `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  next();
};

export const responseLogger = (req: Request, res: Response, next: NextFunction) => {
  const originalSend = res.send;
  
  res.send = function(data) {
    const responseTime = Date.now() - (req.startTime || Date.now());
    
    query(`
      INSERT INTO api_request_logs (
        request_id, method, url, status_code, response_time_ms, user_id, ip, user_agent
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `, [
      req.headers['x-request-id'],
      req.method,
      req.originalUrl,
      res.statusCode,
      responseTime,
      req.user?.userId || null,
      req.ip,
      req.get('user-agent')
    ]).catch(err => console.error('Failed to log API request:', err));

    return originalSend.call(this, data);
  };
  
  next();
};

export const healthMonitor = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const memUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();
    
    await query(`
      SELECT record_health_metric($1, $2, $3, $4, $5)
    `, ['memory_heap_used', memUsage.heapUsed / 1024 / 1024, 'MB', 512, 1024]);
    
    await query(`
      SELECT record_health_metric($1, $2, $3, $4, $5)
    `, ['cpu_user_time', cpuUsage.user / 1000, 'ms', 80, 95]);
    
    next();
  } catch (error) {
    console.error('Health monitoring failed:', error);
    next();
  }
};

export const inputValidator = (req: Request, res: Response, next: NextFunction) => {
  try {
    if (req.body) {
      const sanitized = sanitizeInput(req.body);
      req.body = sanitized;
    }
    
    if (req.query) {
      const sanitized = sanitizeInput(req.query);
      req.query = sanitized;
    }
    
    next();
  } catch (error) {
    next({ statusCode: 400, code: 'INVALID_INPUT', message: 'Invalid input data' });
  }
};

const sanitizeInput = (obj: any): any => {
  if (typeof obj === 'string') {
    return obj.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
             .replace(/javascript:/gi, '')
             .replace(/on\w+\s*=/gi, '')
             .trim();
  }
  
  if (Array.isArray(obj)) {
    return obj.map(sanitizeInput);
  }
  
  if (obj && typeof obj === 'object') {
    const sanitized: any = {};
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = sanitizeInput(value);
    }
    return sanitized;
  }
  
  return obj;
};

export const securityValidator = (req: Request, res: Response, next: NextFunction) => {
  const suspiciousPatterns = [
    /(\<|\%3C)script(.|\n)*?(\>|\%3E)/i,
    /(\<|\%3C)iframe(.|\n)*?(\>|\%3E)/i,
    /javascript\s*:/i,
    /vbscript\s*:/i,
    /onload\s*=/i,
    /onerror\s*=/i
  ];
  
  const checkValue = (value: string): boolean => {
    return suspiciousPatterns.some(pattern => pattern.test(value));
  };
  
  const checkObject = (obj: any): boolean => {
    if (typeof obj === 'string') {
      return checkValue(obj);
    }
    
    if (Array.isArray(obj)) {
      return obj.some(checkObject);
    }
    
    if (obj && typeof obj === 'object') {
      return Object.values(obj).some(checkObject);
    }
    
    return false;
  };
  
  if (checkObject(req.body) || checkObject(req.query)) {
    return res.status(400).json({
      success: false,
      error: 'Potentially malicious input detected',
      code: 'SECURITY_VIOLATION',
      timestamp: new Date().toISOString()
    });
  }
  
  next();
};

export const rateLimiter = (() => {
  const requests = new Map<string, { count: number; resetTime: number }>();
  
  return (req: Request, res: Response, next: NextFunction) => {
    const ip = req.ip;
    const now = Date.now();
    const windowMs = 60 * 1000; // 1 minute
    const maxRequests = 100;
    
    const userRequests = requests.get(ip) || { count: 0, resetTime: now + windowMs };
    
    if (now > userRequests.resetTime) {
      userRequests.count = 0;
      userRequests.resetTime = now + windowMs;
    }
    
    userRequests.count++;
    requests.set(ip, userRequests);
    
    if (userRequests.count > maxRequests) {
      return res.status(429).json({
        success: false,
        error: 'Rate limit exceeded. Please wait before making more requests',
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: Math.ceil((userRequests.resetTime - now) / 1000),
        timestamp: new Date().toISOString()
      });
    }
    
    res.setHeader('X-RateLimit-Limit', maxRequests);
    res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - userRequests.count));
    res.setHeader('X-RateLimit-Reset', Math.ceil(userRequests.resetTime / 1000));
    
    next();
  };
})();

export { ComprehensiveErrorHandler };