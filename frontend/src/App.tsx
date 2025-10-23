import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline, Box, AppBar, Toolbar, Typography, Button, Alert, Snackbar, CircularProgress } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { authService } from './services/authService';
import { DeviceEnrollment } from './components/DeviceEnrollment';
import { ESIMPolicyConfig } from './components/eSIMPolicyConfig';
import { ProfileDeployment } from './components/ProfileDeployment';
import { SystemMonitor } from './components/SystemMonitor';
import { DiagnosticPanel } from './components/DiagnosticPanel';
import { EnterpriseSetupDashboard } from './components/EnterpriseSetupDashboard';
import { CICDDashboard } from './components/CICDDashboard';
import { CloudAuthDashboard } from './components/CloudAuthDashboard';
import { ErrorHandler } from './utils/errorHandler';
import { ErrorBoundary } from './components/ErrorBoundary';
import { useErrorRecovery } from './hooks/useErrorRecovery';

const theme = createTheme({
  palette: {
    primary: { main: '#1976d2' },
    secondary: { main: '#dc004e' }
  }
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error: any) => {
        // Don't retry on 4xx errors except 429
        if (error?.response?.status >= 400 && error?.response?.status < 500 && error?.response?.status !== 429) {
          return false;
        }
        return failureCount < 3;
      },
      staleTime: 5 * 60 * 1000,
      cacheTime: 10 * 60 * 1000,
      refetchOnWindowFocus: false,
      refetchOnReconnect: true,
      onError: (error: any) => {
        ErrorHandler.handle(error);
      }
    },
    mutations: {
      retry: (failureCount, error: any) => {
        if (error?.response?.status >= 400 && error?.response?.status < 500) {
          return false;
        }
        return failureCount < 2;
      },
      onError: (error: any) => {
        ErrorHandler.handle(error);
      }
    }
  }
});

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [systemError, setSystemError] = useState<string | null>(null);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Initialize authentication service
        await authService.initialize();
        setIsAuthenticated(authService.isAuthenticated());
        
        // Register service worker
        if ('serviceWorker' in navigator) {
          try {
            await navigator.serviceWorker.register('/sw.js');
            console.log('Service Worker registered successfully');
          } catch (swError) {
            console.error('Service Worker registration failed:', swError);
          }
        }
        
        // Set up connection monitoring
        const handleOnline = () => setIsOnline(true);
        const handleOffline = () => setIsOnline(false);
        
        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);
        
        // Cleanup
        return () => {
          window.removeEventListener('online', handleOnline);
          window.removeEventListener('offline', handleOffline);
        };
      } catch (error) {
        console.error('App initialization failed:', error);
        setSystemError('Failed to initialize application. Please refresh the page.');
      } finally {
        setLoading(false);
      }
    };

    initializeApp();
  }, []);

  const handleLogin = async () => {
    try {
      setLoading(true);
      await authService.login();
      setIsAuthenticated(true);
      setSystemError(null);
    } catch (error) {
      console.error('Login failed:', error);
      ErrorHandler.handle(error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      setLoading(true);
      await authService.logout();
      setIsAuthenticated(false);
      setSystemError(null);
    } catch (error) {
      console.error('Logout failed:', error);
      ErrorHandler.handle(error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box sx={{ 
          display: 'flex', 
          flexDirection: 'column',
          justifyContent: 'center', 
          alignItems: 'center', 
          height: '100vh',
          gap: 2
        }}>
          <CircularProgress size={60} />
          <Typography variant="h6">Loading EPM Portal...</Typography>
        </Box>
      </ThemeProvider>
    );
  }
  
  if (systemError) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box sx={{ 
          display: 'flex', 
          flexDirection: 'column',
          justifyContent: 'center', 
          alignItems: 'center', 
          height: '100vh',
          p: 3
        }}>
          <Alert severity="error" sx={{ mb: 2, maxWidth: 500 }}>
            {systemError}
          </Alert>
          <Button variant="contained" onClick={() => window.location.reload()}>
            Reload Application
          </Button>
        </Box>
      </ThemeProvider>
    );
  }

  if (!isAuthenticated) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
          <Button variant="contained" onClick={handleLogin}>
            Login with Enterprise Credentials
          </Button>
        </Box>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <ErrorBoundary>
        <QueryClientProvider client={queryClient}>
          <Router>
            {/* Connection status indicator */}
            <Snackbar 
              open={!isOnline} 
              message="No internet connection. Some features may not work."
              anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
            />
            
            <AppBar position="static">
              <Toolbar>
                <Typography variant="h6" sx={{ flexGrow: 1 }}>
                  eSIM Enterprise Management Portal
                </Typography>
                {!isOnline && (
                  <Typography variant="body2" sx={{ mr: 2, color: 'warning.main' }}>
                    Offline
                  </Typography>
                )}
                <Button color="inherit" onClick={handleLogout} disabled={loading}>
                  Logout
                </Button>
              </Toolbar>
            </AppBar>

            <Box sx={{ p: 3, minHeight: 'calc(100vh - 64px)' }}>
              <Routes>
                <Route path="/" element={<Navigate to="/enrollment" />} />
                <Route path="/enrollment" element={<DeviceEnrollment />} />
                <Route path="/policies" element={<ESIMPolicyConfig />} />
                <Route path="/deployment" element={<ProfileDeployment />} />
                <Route path="/monitoring" element={<SystemMonitor />} />
                <Route path="/diagnostics" element={<DiagnosticPanel />} />
            <Route path="/system-monitor" element={<SystemMonitor />} />
            <Route path="/enterprise-setup" element={<EnterpriseSetupDashboard />} />
            <Route path="/cicd" element={<CICDDashboard />} />
            <Route path="/auth" element={<CloudAuthDashboard />} />
                <Route path="*" element={
                  <Box sx={{ textAlign: 'center', mt: 4 }}>
                    <Typography variant="h5" gutterBottom>Page Not Found</Typography>
                    <Button variant="contained" onClick={() => window.location.href = '/'}>
                      Go to Home
                    </Button>
                  </Box>
                } />
              </Routes>
            </Box>
          </Router>
          <Toaster 
            position="top-right" 
            toastOptions={{
              duration: 5000,
              style: {
                maxWidth: '500px',
              },
              error: {
                duration: 8000,
              },
            }}
          />
        </QueryClientProvider>
      </ErrorBoundary>
    </ThemeProvider>
  );
}

export default App;