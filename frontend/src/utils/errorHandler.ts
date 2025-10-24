import toast from 'react-hot-toast';

export interface EPMError {
  success: false;
  error: string;
  code: string;
  timestamp: string;
  details?: any;
  validationErrors?: Array<{ field: string; message: string }>;
}

export class ErrorHandler {
  static handle(error: any): void {
    try {
      if (!error) {
        this.showError('Unknown error occurred', 'UNKNOWN_ERROR');
        return;
      }

      // Handle network errors
      if (!error.response) {
        if (error.code === 'NETWORK_ERROR' || error.message?.includes('Network Error')) {
          this.showError('Network connection failed. Please check your internet connection.', 'NETWORK_ERROR');
          return;
        }
        
        if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
          this.showError('Request timeout. Please try again.', 'TIMEOUT_ERROR');
          return;
        }
        
        this.showError('Connection failed. Please try again.', 'CONNECTION_ERROR');
        return;
      }

      const { status, data } = error.response;
      const errorData: EPMError = data;

      // Handle specific HTTP status codes
      switch (status) {
        case 400:
          this.handleBadRequest(errorData);
          break;
        case 401:
          this.handleUnauthorized(errorData);
          break;
        case 403:
          this.handleForbidden(errorData);
          break;
        case 404:
          this.handleNotFound(errorData);
          break;
        case 409:
          this.handleConflict(errorData);
          break;
        case 413:
          this.showError('File or request too large', 'PAYLOAD_TOO_LARGE');
          break;
        case 429:
          this.handleRateLimit(errorData);
          break;
        case 500:
          this.handleServerError(errorData);
          break;
        case 503:
          this.handleServiceUnavailable(errorData);
          break;
        default:
          this.showError(errorData?.error || 'An unexpected error occurred', errorData?.code || 'UNKNOWN_ERROR');
      }

      // Log error for debugging
      this.logError(error, errorData);
    } catch (handlerError) {
      console.error('Error handler failed:', handlerError);
      toast.error('System error occurred');
    }
  }

  private static handleBadRequest(errorData: EPMError): void {
    if (errorData.validationErrors && errorData.validationErrors.length > 0) {
      const messages = errorData.validationErrors.map(err => `${err.field}: ${err.message}`);
      this.showError(`Validation failed: ${messages.join(', ')}`, errorData.code);
      return;
    }

    switch (errorData.code) {
      case 'MISSING_REQUIRED_FIELDS':
        this.showError('Please fill in all required fields', errorData.code);
        break;
      case 'INVALID_ICCID_FORMAT':
        this.showError('ICCID must be 19-20 digits', errorData.code);
        break;
      case 'INVALID_EMAIL_FORMAT':
        this.showError('Please enter a valid email address', errorData.code);
        break;
      case 'INVALID_PHONE_FORMAT':
        this.showError('Please enter a valid phone number', errorData.code);
        break;
      case 'INVALID_JSON':
        this.showError('Invalid data format', errorData.code);
        break;
      default:
        this.showError(errorData.error || 'Invalid request', errorData.code);
    }
  }

  private static handleUnauthorized(errorData: EPMError): void {
    switch (errorData.code) {
      case 'TOKEN_EXPIRED':
        this.showError('Session expired. Please log in again.', errorData.code);
        setTimeout(() => window.location.reload(), 2000);
        break;
      case 'INVALID_TOKEN':
        this.showError('Invalid authentication. Please log in again.', errorData.code);
        setTimeout(() => window.location.reload(), 2000);
        break;
      default:
        this.showError('Authentication required. Please log in.', errorData.code);
    }
  }

  private static handleForbidden(errorData: EPMError): void {
    switch (errorData.code) {
      case 'INSUFFICIENT_PERMISSIONS':
        this.showError('You do not have permission to perform this action', errorData.code);
        break;
      case 'CORS_ERROR':
        this.showError('Cross-origin request blocked', errorData.code);
        break;
      default:
        this.showError('Access denied', errorData.code);
    }
  }

  private static handleNotFound(errorData: EPMError): void {
    switch (errorData.code) {
      case 'PROFILE_NOT_FOUND':
        this.showError('eSIM profile not found', errorData.code);
        break;
      case 'DEVICE_NOT_FOUND':
        this.showError('Device not found', errorData.code);
        break;
      case 'USER_NOT_FOUND':
        this.showError('User not found', errorData.code);
        break;
      case 'ENDPOINT_NOT_FOUND':
        this.showError('Service endpoint not found', errorData.code);
        break;
      default:
        this.showError('Resource not found', errorData.code);
    }
  }

  private static handleConflict(errorData: EPMError): void {
    switch (errorData.code) {
      case 'DUPLICATE_ICCID':
        this.showError('eSIM profile with this ICCID already exists', errorData.code);
        break;
      case 'DUPLICATE_DEVICE':
        this.showError('Device already registered', errorData.code);
        break;
      case 'DUPLICATE_USER':
        this.showError('User already exists', errorData.code);
        break;
      case 'PROFILE_HAS_ACTIVE_ASSIGNMENTS':
        this.showError('Cannot delete profile with active device assignments', errorData.code);
        break;
      default:
        this.showError('Resource conflict detected', errorData.code);
    }
  }

  private static handleRateLimit(errorData: EPMError): void {
    const retryAfter = errorData.details?.retryAfter || 60;
    this.showError(`Too many requests. Please wait ${retryAfter} seconds before trying again.`, errorData.code);
  }

  private static handleServerError(errorData: EPMError): void {
    switch (errorData.code) {
      case 'DATABASE_ERROR':
        this.showError('Database connection failed. Please try again later.', errorData.code);
        break;
      case 'INTUNE_SERVICE_ERROR':
        this.showError('Microsoft Intune service unavailable. Please try again later.', errorData.code);
        break;
      case 'ESIM_CONFIG_ERROR':
        this.showError('eSIM configuration failed. Please check your settings.', errorData.code);
        break;
      default:
        this.showError('Server error occurred. Please try again later.', errorData.code);
    }
  }

  private static handleServiceUnavailable(errorData: EPMError): void {
    switch (errorData.code) {
      case 'SYSTEM_HEALTH_FAILURE':
        this.showError('System maintenance in progress. Please try again later.', errorData.code);
        break;
      case 'DATABASE_CONNECTION_ERROR':
        this.showError('Database service unavailable. Please try again later.', errorData.code);
        break;
      default:
        this.showError('Service temporarily unavailable. Please try again later.', errorData.code);
    }
  }

  private static showError(message: string, code: string): void {
    toast.error(message, {
      duration: 5000,
      id: code, // Prevent duplicate toasts
      style: {
        maxWidth: '500px',
      }
    });
  }

  private static logError(originalError: any, errorData?: EPMError): void {
    const errorLog = {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      userAgent: navigator.userAgent,
      originalError: {
        message: originalError.message,
        stack: originalError.stack,
        status: originalError.response?.status,
        statusText: originalError.response?.statusText
      },
      serverError: errorData,
      user: this.getCurrentUser()
    };

    console.error('EPM Frontend Error:', errorLog);

    // Send error to monitoring service in production
    if (process.env.NODE_ENV === 'production' && process.env.REACT_APP_ERROR_REPORTING_URL) {
      fetch(process.env.REACT_APP_ERROR_REPORTING_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(errorLog)
      }).catch(reportingError => {
        console.error('Failed to report error:', reportingError);
      });
    }
  }

  private static getCurrentUser(): any {
    try {
      const userStr = localStorage.getItem('currentUser');
      return userStr ? JSON.parse(userStr) : null;
    } catch {
      return null;
    }
  }

  static validateInput(value: any, type: string, required: boolean = false): string | null {
    if (required && (!value || value.toString().trim() === '')) {
      return 'This field is required';
    }

    if (!value) return null;

    switch (type) {
      case 'email':
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(value) ? null : 'Invalid email format';
      
      case 'iccid':
        const iccidRegex = /^\d{19,20}$/;
        return iccidRegex.test(value) ? null : 'ICCID must be 19-20 digits';
      
      case 'imei':
        const imeiRegex = /^\d{15}$/;
        return imeiRegex.test(value) ? null : 'IMEI must be exactly 15 digits';
      
      case 'phone':
        const phoneRegex = /^\+?[1-9]\d{1,14}$/;
        return phoneRegex.test(value.replace(/[\s-]/g, '')) ? null : 'Invalid phone number format';
      
      case 'carrier':
        const validCarriers = ['MPT', 'ATOM', 'U9', 'MYTEL'];
        return validCarriers.includes(value) ? null : 'Invalid carrier selection';
      
      default:
        return null;
    }
  }

  static async withErrorHandling<T>(
    operation: () => Promise<T>,
    customErrorHandler?: (error: any) => void
  ): Promise<T | null> {
    try {
      return await operation();
    } catch (error) {
      if (customErrorHandler) {
        customErrorHandler(error);
      } else {
        this.handle(error);
      }
      return null;
    }
  }
}