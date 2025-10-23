import { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';

export const handleValidationErrors = (req: Request, res: Response, next: NextFunction) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

export const validateProfile = [
  body('profile_name').notEmpty().withMessage('Profile name is required'),
  body('carrier').isIn(['MPT', 'ATOM', 'U9', 'MYTEL']).withMessage('Invalid carrier'),
  body('carrier_code').matches(/^414-0[1679]$/).withMessage('Invalid carrier code'),
  body('iccid').isLength({ min: 19, max: 20 }).withMessage('Invalid ICCID format'),
  body('data_allowance_mb').isInt({ min: 0 }).withMessage('Data allowance must be positive integer'),
  body('validity_days').isInt({ min: 1 }).withMessage('Validity days must be positive integer'),
  handleValidationErrors
];

export const validateDevice = [
  body('device_name').notEmpty().withMessage('Device name is required'),
  body('intune_device_id').notEmpty().withMessage('Intune device ID is required'),
  body('model').optional().isString(),
  body('manufacturer').optional().isString(),
  body('serial_number').optional().isString(),
  body('imei').optional().matches(/^\d{15}$/).withMessage('Invalid IMEI format'),
  handleValidationErrors
];

export const validateAssignment = [
  body('device_id').isUUID().withMessage('Invalid device ID'),
  body('profile_id').isUUID().withMessage('Invalid profile ID'),
  body('assignment_type').isIn(['manual', 'automatic', 'migration']).withMessage('Invalid assignment type'),
  body('notes').optional().isString(),
  handleValidationErrors
];