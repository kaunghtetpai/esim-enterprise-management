import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Chip,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  LinearProgress
} from '@mui/material';
import {
  GitHub,
  CloudUpload,
  Microsoft,
  Security,
  CheckCircle,
  Error,
  Warning,
  Refresh,
  Login,
  Sync,
  Build
} from '@mui/icons-material';

interface AuthStatus {
  service: string;
  authenticated: boolean;
  user?: string;
  lastCheck: string;
  error?: string;
}

interface CloudServices {
  github: AuthStatus;
  vercel: AuthStatus;
  microsoftGraph: AuthStatus;
  intune: AuthStatus;
}

export const CloudAuthDashboard: React.FC = () => {
  const [services, setServices] = useState<CloudServices | null>(null);
  const [loading, setLoading] = useState(false);
  const [loginDialogOpen, setLoginDialogOpen] = useState(false);
  const [selectedService, setSelectedService] = useState<string>('');

  const fetchAuthStatus = async () => {
    try {
      const response = await fetch('/api/v1/auth/status');
      const result = await response.json();
      if (result.success) {
        setServices(result.data);
      }
    } catch (error) {
      console.error('Failed to fetch auth status:', error);
    }
  };

  const loginToService = async (service: string) => {
    setLoading(true);
    try {
      const response = await fetch(`/api/v1/auth/login/${service}`, {
        method: 'POST'
      });
      const result = await response.json();
      
      if (result.success) {
        await fetchAuthStatus();
        setLoginDialogOpen(false);
      }
    } catch (error) {
      console.error(`${service} login failed:`, error);
    } finally {
      setLoading(false);
    }
  };

  const validateSync = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/auth/validate-sync');
      const result = await response.json();
      console.log('Sync validation:', result);
    } catch (error) {
      console.error('Sync validation failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const autoFix = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/auth/auto-fix', {
        method: 'POST'
      });
      const result = await response.json();
      
      if (result.success) {
        await fetchAuthStatus();
      }
    } catch (error) {
      console.error('Auto-fix failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const createCarrierGroups = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/auth/carrier-groups', {
        method: 'POST'
      });
      const result = await response.json();
      console.log('Carrier groups result:', result);
    } catch (error) {
      console.error('Carrier groups creation failed:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAuthStatus();
    const interval = setInterval(fetchAuthStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  const getServiceIcon = (service: string) => {
    switch (service) {
      case 'github': return <GitHub />;
      case 'vercel': return <CloudUpload />;
      case 'microsoftGraph': return <Microsoft />;
      case 'intune': return <Security />;
      default: return <CheckCircle />;
    }
  };

  const getServiceName = (service: string) => {
    switch (service) {
      case 'github': return 'GitHub';
      case 'vercel': return 'Vercel';
      case 'microsoftGraph': return 'Microsoft Graph';
      case 'intune': return 'Microsoft Intune';
      default: return service;
    }
  };

  const getStatusColor = (authenticated: boolean) => {
    return authenticated ? 'success' : 'error';
  };

  const getStatusIcon = (authenticated: boolean) => {
    return authenticated ? <CheckCircle color="success" /> : <Error color="error" />;
  };

  if (!services) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography variant="h6">Loading authentication status...</Typography>
        <LinearProgress sx={{ mt: 2 }} />
      </Box>
    );
  }

  const allAuthenticated = Object.values(services).every(s => s.authenticated);

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Cloud Authentication Dashboard
      </Typography>
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        Manage authentication for GitHub, Vercel, and Microsoft Cloud services
      </Typography>

      {/* Overall Status */}
      <Alert 
        severity={allAuthenticated ? 'success' : 'warning'} 
        sx={{ mb: 3 }}
      >
        {allAuthenticated 
          ? 'All cloud services are authenticated and ready'
          : 'Some services require authentication'
        }
      </Alert>

      {/* Action Buttons */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Button
          startIcon={<Refresh />}
          onClick={fetchAuthStatus}
          variant="outlined"
          disabled={loading}
        >
          Refresh Status
        </Button>
        <Button
          startIcon={<Sync />}
          onClick={validateSync}
          variant="outlined"
          disabled={loading}
        >
          Validate Sync
        </Button>
        <Button
          startIcon={<Build />}
          onClick={autoFix}
          variant="outlined"
          color="warning"
          disabled={loading}
        >
          Auto-Fix
        </Button>
        <Button
          startIcon={<Security />}
          onClick={createCarrierGroups}
          variant="contained"
          color="primary"
          disabled={loading}
        >
          Create Carrier Groups
        </Button>
      </Box>

      {/* Service Status Cards */}
      <Grid container spacing={3}>
        {Object.entries(services).map(([serviceKey, service]) => (
          <Grid item xs={12} sm={6} md={3} key={serviceKey}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  {getServiceIcon(serviceKey)}
                  <Typography variant="h6" sx={{ ml: 1 }}>
                    {getServiceName(serviceKey)}
                  </Typography>
                </Box>
                
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  {getStatusIcon(service.authenticated)}
                  <Chip
                    label={service.authenticated ? 'Connected' : 'Not Connected'}
                    color={getStatusColor(service.authenticated) as any}
                    size="small"
                    sx={{ ml: 1 }}
                  />
                </Box>
                
                {service.user && (
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                    User: {service.user}
                  </Typography>
                )}
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Last Check: {new Date(service.lastCheck).toLocaleString()}
                </Typography>
                
                {service.error && (
                  <Alert severity="error" sx={{ mb: 2 }}>
                    {service.error}
                  </Alert>
                )}
                
                {!service.authenticated && (
                  <Button
                    startIcon={<Login />}
                    onClick={() => {
                      setSelectedService(serviceKey);
                      setLoginDialogOpen(true);
                    }}
                    variant="contained"
                    size="small"
                    fullWidth
                  >
                    Login
                  </Button>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Service URLs */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Service URLs
          </Typography>
          
          <List dense>
            <ListItem>
              <ListItemIcon>
                <GitHub />
              </ListItemIcon>
              <ListItemText
                primary="GitHub Repository"
                secondary={
                  <Button
                    size="small"
                    href="https://github.com/kaunghtetpai/esim-enterprise-management"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    kaunghtetpai/esim-enterprise-management
                  </Button>
                }
              />
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <CloudUpload />
              </ListItemIcon>
              <ListItemText
                primary="Vercel Project"
                secondary={
                  <Button
                    size="small"
                    href="https://vercel.com/e-sim/esim-enterprise-management"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    e-sim/esim-enterprise-management
                  </Button>
                }
              />
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <Microsoft />
              </ListItemIcon>
              <ListItemText
                primary="Microsoft Entra ID"
                secondary={
                  <Button
                    size="small"
                    href="https://entra.microsoft.com"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    entra.microsoft.com
                  </Button>
                }
              />
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <Security />
              </ListItemIcon>
              <ListItemText
                primary="Microsoft Intune"
                secondary={
                  <Button
                    size="small"
                    href="https://intune.microsoft.com"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    intune.microsoft.com
                  </Button>
                }
              />
            </ListItem>
          </List>
        </CardContent>
      </Card>

      {/* Login Dialog */}
      <Dialog open={loginDialogOpen} onClose={() => setLoginDialogOpen(false)}>
        <DialogTitle>
          Login to {getServiceName(selectedService)}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2 }}>
            This will initiate the login process for {getServiceName(selectedService)}.
            Please follow the authentication prompts.
          </Typography>
          
          {selectedService === 'github' && (
            <Alert severity="info">
              GitHub login requires web authentication with repository and workflow permissions.
            </Alert>
          )}
          
          {selectedService === 'vercel' && (
            <Alert severity="info">
              Vercel login will open a web browser for authentication.
            </Alert>
          )}
          
          {selectedService === 'microsoftGraph' && (
            <Alert severity="info">
              Microsoft Graph requires admin consent for directory and device management permissions.
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoginDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={() => loginToService(selectedService)} 
            disabled={loading}
            variant="contained"
          >
            {loading ? 'Logging in...' : 'Login'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};