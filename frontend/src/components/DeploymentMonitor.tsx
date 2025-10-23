import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Button,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  CheckCircle,
  Error,
  Warning,
  Refresh,
  GitHub,
  Cloud,
  Microsoft,
  Sync,
  Build,
  CheckCircleOutline
} from '@mui/icons-material';

interface DeploymentStatus {
  platform: string;
  status: 'healthy' | 'error' | 'warning';
  last_check: string;
  error_count: number;
}

interface DeploymentError {
  id: string;
  platform: string;
  error_type: string;
  error_message: string;
  status: string;
  created_at: string;
}

const DeploymentMonitor: React.FC = () => {
  const [deploymentStatus, setDeploymentStatus] = useState<DeploymentStatus[]>([]);
  const [errors, setErrors] = useState<DeploymentError[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);

  const fetchDeploymentStatus = async () => {
    try {
      const response = await fetch('/api/v1/deployment/check-all');
      const data = await response.json();
      if (data.success) {
        setDeploymentStatus(data.data);
      }
    } catch (error) {
      console.error('Failed to fetch deployment status:', error);
    }
  };

  const fetchErrors = async () => {
    try {
      const response = await fetch('/api/v1/deployment/errors');
      const data = await response.json();
      if (data.success) {
        setErrors(data.data);
      }
    } catch (error) {
      console.error('Failed to fetch errors:', error);
    }
  };

  const syncAllPlatforms = async () => {
    setSyncing(true);
    try {
      const response = await fetch('/api/v1/deployment/sync-all', {
        method: 'POST'
      });
      const data = await response.json();
      if (data.success) {
        await fetchDeploymentStatus();
        await fetchErrors();
      }
    } catch (error) {
      console.error('Failed to sync platforms:', error);
    } finally {
      setSyncing(false);
    }
  };

  const resolveError = async (errorId: string) => {
    try {
      const response = await fetch(`/api/v1/deployment/errors/${errorId}/resolve`, {
        method: 'POST'
      });
      if (response.ok) {
        await fetchErrors();
      }
    } catch (error) {
      console.error('Failed to resolve error:', error);
    }
  };

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      await Promise.all([fetchDeploymentStatus(), fetchErrors()]);
      setLoading(false);
    };

    loadData();
    const interval = setInterval(loadData, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
  }, []);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle color="success" />;
      case 'error':
        return <Error color="error" />;
      case 'warning':
        return <Warning color="warning" />;
      default:
        return <CircularProgress size={20} />;
    }
  };

  const getPlatformIcon = (platform: string) => {
    switch (platform) {
      case 'github':
        return <GitHub />;
      case 'vercel':
        return <Cloud />;
      case 'azure':
      case 'intune':
        return <Microsoft />;
      default:
        return <Build />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'success';
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      default:
        return 'default';
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Deployment Monitor
        </Typography>
        <Box>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={() => {
              fetchDeploymentStatus();
              fetchErrors();
            }}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Sync />}
            onClick={syncAllPlatforms}
            disabled={syncing}
          >
            {syncing ? 'Syncing...' : 'Sync All'}
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Platform Status Cards */}
        {deploymentStatus.map((platform) => (
          <Grid item xs={12} sm={6} md={3} key={platform.platform}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  {getPlatformIcon(platform.platform)}
                  <Typography variant="h6" sx={{ ml: 1, textTransform: 'capitalize' }}>
                    {platform.platform}
                  </Typography>
                </Box>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Chip
                    icon={getStatusIcon(platform.status)}
                    label={platform.status.toUpperCase()}
                    color={getStatusColor(platform.status) as any}
                    size="small"
                  />
                  {platform.error_count > 0 && (
                    <Chip
                      label={`${platform.error_count} errors`}
                      color="error"
                      size="small"
                      variant="outlined"
                    />
                  )}
                </Box>
                <Typography variant="caption" color="textSecondary" sx={{ mt: 1, display: 'block' }}>
                  Last check: {new Date(platform.last_check).toLocaleString()}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}

        {/* Quick Links */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Quick Links
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6} md={3}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<GitHub />}
                    href="https://github.com/kaunghtetpai/esim-enterprise-management"
                    target="_blank"
                  >
                    GitHub Repository
                  </Button>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<Cloud />}
                    href="https://vercel.com/e-sim/esim-enterprise-management"
                    target="_blank"
                  >
                    Vercel Dashboard
                  </Button>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<Build />}
                    href="https://esim-enterprise-management.vercel.app"
                    target="_blank"
                  >
                    Production App
                  </Button>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<Microsoft />}
                    href="https://portal.azure.com"
                    target="_blank"
                  >
                    Azure Portal
                  </Button>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Active Errors */}
        {errors.length > 0 && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Active Errors ({errors.length})
                </Typography>
                <List>
                  {errors.map((error) => (
                    <ListItem key={error.id}>
                      <ListItemIcon>
                        {getPlatformIcon(error.platform)}
                      </ListItemIcon>
                      <ListItemText
                        primary={`${error.platform.toUpperCase()}: ${error.error_type}`}
                        secondary={
                          <Box>
                            <Typography variant="body2" color="textSecondary">
                              {error.error_message}
                            </Typography>
                            <Typography variant="caption" color="textSecondary">
                              {new Date(error.created_at).toLocaleString()}
                            </Typography>
                          </Box>
                        }
                      />
                      <Tooltip title="Mark as resolved">
                        <IconButton
                          onClick={() => resolveError(error.id)}
                          color="success"
                        >
                          <CheckCircleOutline />
                        </IconButton>
                      </Tooltip>
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>
        )}

        {/* No Errors Message */}
        {errors.length === 0 && (
          <Grid item xs={12}>
            <Alert severity="success" icon={<CheckCircle />}>
              All deployment platforms are operating normally with no active errors.
            </Alert>
          </Grid>
        )}
      </Grid>
    </Box>
  );
};

export default DeploymentMonitor;