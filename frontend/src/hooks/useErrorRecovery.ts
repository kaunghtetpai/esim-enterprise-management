import { useState, useCallback, useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { authService } from '../services/authService';
import toast from 'react-hot-toast';

interface RecoveryState {
  isRecovering: boolean;
  recoveryAttempts: number;
  lastRecoveryTime: Date | null;
}

export const useErrorRecovery = () => {
  const [recoveryState, setRecoveryState] = useState<RecoveryState>({
    isRecovering: false,
    recoveryAttempts: 0,
    lastRecoveryTime: null
  });
  
  const queryClient = useQueryClient();

  const attemptTokenRefresh = useCallback(async (): Promise<boolean> => {
    try {
      if (!authService.isAuthenticated()) return false;
      
      const newToken = await authService.getToken();
      if (newToken) {
        queryClient.invalidateQueries();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Token refresh failed:', error);
      return false;
    }
  }, [queryClient]);

  const attemptNetworkRecovery = useCallback(async (): Promise<boolean> => {
    try {
      const response = await fetch('/api/v1/health', { 
        method: 'GET',
        cache: 'no-cache'
      });
      return response.ok;
    } catch (error) {
      return false;
    }
  }, []);

  const clearCache = useCallback(() => {
    queryClient.clear();
    localStorage.removeItem('react-query-offline-cache');
    sessionStorage.clear();
  }, [queryClient]);

  const recoverFromError = useCallback(async (error: any): Promise<boolean> => {
    if (recoveryState.isRecovering) return false;

    setRecoveryState(prev => ({
      ...prev,
      isRecovering: true,
      recoveryAttempts: prev.recoveryAttempts + 1
    }));

    try {
      if (error?.response?.status === 401) {
        const tokenRefreshed = await attemptTokenRefresh();
        if (tokenRefreshed) {
          toast.success('Session restored successfully');
          return true;
        }
        
        await authService.logout();
        toast.error('Please log in again');
        window.location.reload();
        return false;
      }

      if (!error?.response || error?.code === 'NETWORK_ERROR') {
        const networkRestored = await attemptNetworkRecovery();
        if (networkRestored) {
          toast.success('Connection restored');
          queryClient.invalidateQueries();
          return true;
        }
        
        toast.error('Network connection failed. Please check your internet connection.');
        return false;
      }

      if (error?.message?.includes('cache') || error?.code === 'CACHE_ERROR') {
        clearCache();
        toast.success('Cache cleared. Please refresh the page.');
        return true;
      }

      if (error?.response?.status === 429) {
        const retryAfter = error?.response?.data?.retryAfter || 60;
        toast.error(`Rate limited. Retrying in ${retryAfter} seconds...`);
        
        setTimeout(() => {
          queryClient.invalidateQueries();
          toast.success('Rate limit cleared. You can try again now.');
        }, retryAfter * 1000);
        
        return true;
      }

      return false;
    } catch (recoveryError) {
      console.error('Recovery attempt failed:', recoveryError);
      return false;
    } finally {
      setRecoveryState(prev => ({
        ...prev,
        isRecovering: false,
        lastRecoveryTime: new Date()
      }));
    }
  }, [recoveryState.isRecovering, attemptTokenRefresh, attemptNetworkRecovery, clearCache, queryClient]);

  const resetRecoveryState = useCallback(() => {
    setRecoveryState({
      isRecovering: false,
      recoveryAttempts: 0,
      lastRecoveryTime: null
    });
  }, []);

  useEffect(() => {
    const handleOnline = () => {
      if (recoveryState.recoveryAttempts > 0) {
        toast.success('Connection restored');
        queryClient.invalidateQueries();
        resetRecoveryState();
      }
    };

    const handleOffline = () => {
      toast.error('Connection lost. Working in offline mode.');
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [recoveryState.recoveryAttempts, queryClient, resetRecoveryState]);

  return {
    recoveryState,
    recoverFromError,
    resetRecoveryState,
    attemptTokenRefresh,
    clearCache
  };
};

export const useAutoRetry = (maxRetries: number = 3, baseDelay: number = 1000) => {
  const [retryState, setRetryState] = useState({
    attempts: 0,
    isRetrying: false,
    lastAttempt: null as Date | null
  });

  const executeWithRetry = useCallback(async <T>(
    operation: () => Promise<T>,
    shouldRetry?: (error: any, attempt: number) => boolean
  ): Promise<T> => {
    let lastError: any;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        setRetryState({
          attempts: attempt,
          isRetrying: attempt > 0,
          lastAttempt: new Date()
        });

        const result = await operation();
        
        if (attempt > 0) {
          toast.success('Operation succeeded after retry');
        }
        
        setRetryState({
          attempts: 0,
          isRetrying: false,
          lastAttempt: null
        });
        
        return result;
      } catch (error) {
        lastError = error;
        
        const shouldContinueRetry = shouldRetry ? 
          shouldRetry(error, attempt) : 
          (attempt < maxRetries && error?.response?.status >= 500);

        if (!shouldContinueRetry || attempt === maxRetries) {
          setRetryState({
            attempts: attempt + 1,
            isRetrying: false,
            lastAttempt: new Date()
          });
          throw error;
        }

        const delay = baseDelay * Math.pow(2, attempt);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    throw lastError;
  }, [maxRetries, baseDelay]);

  return {
    retryState,
    executeWithRetry
  };
};