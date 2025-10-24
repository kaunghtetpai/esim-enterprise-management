import { Request, Response, NextFunction } from 'express';

// Generic validation middleware
export const validateRequest = (schema: any) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const { error } = schema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        code: 'VALIDATION_ERROR',
        details: error.details.map((detail: any) => ({
          field: detail.path.join('.'),
          message: detail.message,
          value: detail.context?.value
        })),
        timestamp: new Date().toISOString()
      });
    }
    
    next();
  };
};

// Profile validation
export const validateProfile = (req: Request, res: Response, next: NextFunction) => {
  const { iccid, profile_name, carrier, carrier_code } = req.body;
  const errors: string[] = [];

  // Required field validation
  if (!iccid) errors.push('ICCID is required');
  if (!profile_name) errors.push('Profile name is required');
  if (!carrier) errors.push('Carrier is required');
  if (!carrier_code) errors.push('Carrier code is required');

  // Format validation
  if (iccid && !/^\d{19,20}$/.test(iccid)) {
    errors.push('ICCID must be 19-20 digits');
  }

  if (profile_name && (profile_name.length < 2 || profile_name.length > 100)) {
    errors.push('Profile name must be between 2 and 100 characters');
  }

  if (carrier && !['MPT', 'ATOM', 'U9', 'MYTEL'].includes(carrier)) {
    errors.push('Carrier must be one of: MPT, ATOM, U9, MYTEL');
  }

  if (req.body.data_allowance_mb && (isNaN(req.body.data_allowance_mb) || req.body.data_allowance_mb < 0)) {
    errors.push('Data allowance must be a positive number');
  }

  if (req.body.validity_days && (isNaN(req.body.validity_days) || req.body.validity_days < 1)) {
    errors.push('Validity days must be a positive integer');
  }

  if (req.body.monthly_cost && (isNaN(req.body.monthly_cost) || req.body.monthly_cost < 0)) {
    errors.push('Monthly cost must be a positive number');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      error: 'Profile validation failed',
      code: 'PROFILE_VALIDATION_ERROR',
      details: errors,
      timestamp: new Date().toISOString()
    });
  }

  next();
};

// Device validation
export const validateDevice = (req: Request, res: Response, next: NextFunction) => {
  const { device_name, model, manufacturer } = req.body;
  const errors: string[] = [];

  // Required field validation
  if (!device_name) errors.push('Device name is required');
  if (!model) errors.push('Model is required');
  if (!manufacturer) errors.push('Manufacturer is required');

  // Format validation
  if (device_name && (device_name.length < 2 || device_name.length > 100)) {
    errors.push('Device name must be between 2 and 100 characters');
  }

  if (req.body.imei && !/^\d{15}$/.test(req.body.imei)) {
    errors.push('IMEI must be exactly 15 digits');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      error: 'Device validation failed',
      code: 'DEVICE_VALIDATION_ERROR',
      details: errors,
      timestamp: new Date().toISOString()
    });
  }

  next();
};

// User validation
export const validateUser = (req: Request, res: Response, next: NextFunction) => {
  const { azure_user_id, email, display_name, role } = req.body;
  const errors: string[] = [];

  // Required field validation
  if (!azure_user_id) errors.push('Azure User ID is required');
  if (!email) errors.push('Email is required');
  if (!display_name) errors.push('Display name is required');
  if (!role) errors.push('Role is required');

  // Format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (email && !emailRegex.test(email)) {
    errors.push('Invalid email format');
  }

  const validRoles = ['admin', 'it_staff', 'end_user'];
  if (role && !validRoles.includes(role)) {
    errors.push(`Role must be one of: ${validRoles.join(', ')}`);
  }

  if (req.body.phone && !/^\+?[1-9]\d{1,14}$/.test(req.body.phone.replace(/[\s-]/g, ''))) {
    errors.push('Invalid phone number format');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      error: 'User validation failed',
      code: 'USER_VALIDATION_ERROR',
      details: errors,
      timestamp: new Date().toISOString()
    });
  }

  next();
};

// UUID validation
export const validateUUID = (paramName: string = 'id') => {
  return (req: Request, res: Response, next: NextFunction) => {
    const id = req.params[paramName];
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        success: false,
        error: `Invalid ${paramName} format`,
        code: 'INVALID_UUID_FORMAT',
        timestamp: new Date().toISOString()
      });
    }
    
    next();
  };
};

// Pagination validation
export const validatePagination = (req: Request, res: Response, next: NextFunction) => {
  const { page = 1, limit = 20 } = req.query;
  
  const pageNum = parseInt(page as string);
  const limitNum = parseInt(limit as string);
  
  if (isNaN(pageNum) || pageNum < 1) {
    return res.status(400).json({
      success: false,
      error: 'Page must be a positive integer',
      code: 'INVALID_PAGE_PARAMETER',
      timestamp: new Date().toISOString()
    });
  }
  
  if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
    return res.status(400).json({
      success: false,
      error: 'Limit must be between 1 and 100',
      code: 'INVALID_LIMIT_PARAMETER',
      timestamp: new Date().toISOString()
    });
  }
  
  // Add validated values to request
  req.query.page = pageNum.toString();
  req.query.limit = limitNum.toString();
  
  next();
};

// Date validation
export const validateDateRange = (req: Request, res: Response, next: NextFunction) => {
  const { start_date, end_date } = req.query;
  
  if (start_date && !/^\d{4}-\d{2}-\d{2}$/.test(start_date as string)) {
    return res.status(400).json({
      success: false,
      error: 'Start date must be in YYYY-MM-DD format',
      code: 'INVALID_START_DATE_FORMAT',
      timestamp: new Date().toISOString()
    });
  }
  
  if (end_date && !/^\d{4}-\d{2}-\d{2}$/.test(end_date as string)) {
    return res.status(400).json({
      success: false,
      error: 'End date must be in YYYY-MM-DD format',
      code: 'INVALID_END_DATE_FORMAT',
      timestamp: new Date().toISOString()
    });
  }
  
  if (start_date && end_date) {
    const startDate = new Date(start_date as string);
    const endDate = new Date(end_date as string);
    
    if (startDate > endDate) {
      return res.status(400).json({
        success: false,
        error: 'Start date must be before end date',
        code: 'INVALID_DATE_RANGE',
        timestamp: new Date().toISOString()
      });
    }
  }
  
  next();
};

// Sanitize input
export const sanitizeInput = (req: Request, res: Response, next: NextFunction) => {
  const sanitizeString = (str: string): string => {
    if (typeof str !== 'string') return str;
    
    // Remove potentially dangerous characters
    return str
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '')
      .trim();
  };

  const sanitizeObject = (obj: any): any => {
    if (typeof obj !== 'object' || obj === null) return obj;
    
    if (Array.isArray(obj)) {
      return obj.map(sanitizeObject);
    }
    
    const sanitized: any = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        sanitized[key] = sanitizeString(value);
      } else if (typeof value === 'object') {
        sanitized[key] = sanitizeObject(value);
      } else {
        sanitized[key] = value;
      }
    }
    return sanitized;
  };

  if (req.body) {
    req.body = sanitizeObject(req.body);
  }
  
  if (req.query) {
    req.query = sanitizeObject(req.query);
  }
  
  next();
};