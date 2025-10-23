import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';
import { authService } from './authService';
import { ErrorHandler } from '../utils/errorHandler';

interface RetryConfig extends AxiosRequestConfig {
  _retry?: boolean;
  _retryCount?: number;
}

// Connection monitoring
let isOnline = navigator.onLine;
let connectionRetries = 0;

window.addEventListener('online', () => {
  isOnline = true;
  connectionRetries = 0;
  console.log('Connection restored');
});

window.addEventListener('offline', () => {
  isOnline = false;
  console.log('Connection lost');
});

export const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL || '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Request interceptor with comprehensive error handling
apiClient.interceptors.request.use(
  async (config: RetryConfig) => {
    try {
      // Add request ID for tracking
      config.headers['X-Request-ID'] = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // Add authentication token
      if (authService.isAuthenticated()) {
        const token = await authService.getToken();
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
      }
      
      // Validate request data
      if (config.data && typeof config.data === 'object') {
        try {
          JSON.stringify(config.data);
        } catch (error) {
          throw new Error('Invalid request data format');
        }
      }
      
      return config;
    } catch (error) {
      console.error('Request interceptor error:', error);
      return Promise.reject(error);
    }
  },
  (error) => {
    console.error('Request configuration error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor with retry logic and error handling
apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    // Validate response structure
    if (response.data && typeof response.data === 'object') {
      if (response.data.success === false) {
        console.warn('API returned success: false', response.data);
      }
    }
    return response;
  },
  async (error: AxiosError) => {
    const config = error.config as RetryConfig;
    
    // Handle network errors with retry
    if (!error.response && config && !config._retry) {
      config._retry = true;
      config._retryCount = (config._retryCount || 0) + 1;
      
      if (config._retryCount <= 3) {
        console.log(`Retrying request (${config._retryCount}/3):`, config.url);
        await new Promise(resolve => setTimeout(resolve, 1000 * config._retryCount));
        return apiClient(config);
      }
    }
    
    // Handle authentication errors
    if (error.response?.status === 401) {
      const errorData = error.response.data as any;
      
      if (errorData?.code === 'TOKEN_EXPIRED' && config && !config._retry) {
        config._retry = true;
        
        try {
          await authService.logout();
          await authService.login();
          const newToken = await authService.getToken();
          
          if (newToken && config.headers) {
            config.headers.Authorization = `Bearer ${newToken}`;
            return apiClient(config);
          }
        } catch (refreshError) {
          console.error('Token refresh failed:', refreshError);
          authService.logout();
          window.location.reload();
        }
      } else {
        authService.logout();
        window.location.reload();
      }
    }
    
    // Handle rate limiting with exponential backoff
    if (error.response?.status === 429 && config && !config._retry) {
      config._retry = true;
      const retryAfter = error.response.headers['retry-after'] || 5;
      
      console.log(`Rate limited, retrying after ${retryAfter} seconds`);
      await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
      return apiClient(config);
    }
    
    // Handle server errors with retry
    if (error.response?.status >= 500 && config && !config._retry) {
      config._retry = true;
      config._retryCount = (config._retryCount || 0) + 1;
      
      if (config._retryCount <= 2) {
        console.log(`Server error, retrying (${config._retryCount}/2):`, config.url);
        await new Promise(resolve => setTimeout(resolve, 2000 * config._retryCount));
        return apiClient(config);
      }
    }
    
    return Promise.reject(error);
  }
);

// API helper functions with error handling
export const apiHelpers = {
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return ErrorHandler.withErrorHandling(async () => {
      const response = await apiClient.get<T>(url, config);
      return response.data;
    }) as Promise<T>;
  },
  
  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return ErrorHandler.withErrorHandling(async () => {
      const response = await apiClient.post<T>(url, data, config);
      return response.data;
    }) as Promise<T>;
  },
  
  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return ErrorHandler.withErrorHandling(async () => {
      const response = await apiClient.put<T>(url, data, config);
      return response.data;
    }) as Promise<T>;
  },
  
  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return ErrorHandler.withErrorHandling(async () => {
      const response = await apiClient.delete<T>(url, config);
      return response.data;
    }) as Promise<T>;
  }
};