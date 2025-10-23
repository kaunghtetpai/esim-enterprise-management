import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Button,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Collapse
} from '@mui/material';
import {
  CheckCircle,
  Warning,
  Error,
  Refresh,
  Build,
  ExpandMore,
  ExpandLess,
  Computer,
  Storage,
  Memory,
  NetworkCheck
} from '@mui/icons-material';

interface SystemHealth {
  overall: 'healthy' | 'warning' | 'critical';
  database: boolean;
  api: boolean;
  auth: boolean;
  network: boolean;
  disk: number;
  memory: number;
  errors: SystemError[];
}

interface SystemError {
  id: string;
  type: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  timestamp: string;
  resolved: boolean;
}

export const SystemMonitor: React.FC = () => {
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const [autoFixing, setAutoFixing] = useState(false);
  const [expanded, setExpanded] = useState(false);

  const fetchSystemHealth = async () => {
    try {
      const response = await fetch('/api/v1/system/health');
      const result = await response.json();
      if (result.success) {
        setHealth(result.data);
      }
    } catch (error) {
      console.error('Failed to fetch system health:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAutoFix = async () => {
    setAutoFixing(true);
    try {
      const response = await fetch('/api/v1/system/auto-fix', {
        method: 'POST'
      });
      const result = await response.json();
      if (result.success) {
        await fetchSystemHealth();
      }
    } catch (error) {
      console.error('Auto-fix failed:', error);
    } finally {
      setAutoFixing(false);
    }
  };

  useEffect(() => {
    fetchSystemHealth();
    const interval = setInterval(fetchSystemHealth, 30000); // Check every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const getHealthColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'success';
      case 'warning': return 'warning';
      case 'critical': return 'error';
      default: return 'default';
    }
  };

  const getHealthIcon = (status: string) => {
    switch (status) {
      case 'healthy': return <CheckCircle color="success" />;
      case 'warning': return <Warning color="warning" />;
      case 'critical': return <Error color="error" />;
      default: return <Computer />;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'info';
      case 'medium': return 'warning';
      case 'high': return 'error';
      case 'critical': return 'error';
      default: return 'default';
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>System Monitor</Typography>
        <LinearProgress />
      </Box>
    );
  }

  if (!health) {
    return (
      <Alert severity="error">
        Failed to load system health data
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5">System Monitor</Typography>
        <Box>
          <Button
            startIcon={<Refresh />}
            onClick={fetchSystemHealth}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          <Button
            startIcon={<Build />}
            onClick={handleAutoFix}
            disabled={autoFixing}
            variant="contained"
            color="primary"
          >
            {autoFixing ? 'Fixing...' : 'Auto Fix'}
          </Button>
        </Box>
      </Box>

      {/* Overall Health */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            {getHealthIcon(health.overall)}
            <Typography variant="h6" sx={{ ml: 1 }}>
              Overall System Health
            </Typography>
            <Chip
              label={health.overall.toUpperCase()}
              color={getHealthColor(health.overall) as any}
              sx={{ ml: 2 }}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Component Status */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Storage color={health.database ? 'success' : 'error'} />
                <Box sx={{ ml: 1 }}>
                  <Typography variant="subtitle2">Database</Typography>
                  <Typography variant="body2" color={health.database ? 'success.main' : 'error.main'}>
                    {health.database ? 'Connected' : 'Disconnected'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Computer color={health.api ? 'success' : 'error'} />
                <Box sx={{ ml: 1 }}>
                  <Typography variant="subtitle2">API</Typography>
                  <Typography variant="body2" color={health.api ? 'success.main' : 'error.main'}>
                    {health.api ? 'Online' : 'Offline'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <CheckCircle color={health.auth ? 'success' : 'error'} />
                <Box sx={{ ml: 1 }}>
                  <Typography variant="subtitle2">Authentication</Typography>
                  <Typography variant="body2" color={health.auth ? 'success.main' : 'error.main'}>
                    {health.auth ? 'Active' : 'Failed'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <NetworkCheck color={health.network ? 'success' : 'error'} />
                <Box sx={{ ml: 1 }}>
                  <Typography variant="subtitle2">Network</Typography>
                  <Typography variant="body2" color={health.network ? 'success.main' : 'error.main'}>
                    {health.network ? 'Connected' : 'Disconnected'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Resource Usage */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Disk Usage</Typography>
              <LinearProgress
                variant="determinate"
                value={health.disk}
                color={health.disk > 90 ? 'error' : health.disk > 75 ? 'warning' : 'primary'}
                sx={{ height: 10, borderRadius: 5 }}
              />
              <Typography variant="body2" sx={{ mt: 1 }}>
                {health.disk.toFixed(1)}% used
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Memory Usage</Typography>
              <LinearProgress
                variant="determinate"
                value={health.memory}
                color={health.memory > 90 ? 'error' : health.memory > 75 ? 'warning' : 'primary'}
                sx={{ height: 10, borderRadius: 5 }}
              />
              <Typography variant="body2" sx={{ mt: 1 }}>
                {health.memory.toFixed(1)}% used
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Errors */}
      {health.errors.length > 0 && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="h6">
                System Errors ({health.errors.length})
              </Typography>
              <IconButton onClick={() => setExpanded(!expanded)}>
                {expanded ? <ExpandLess /> : <ExpandMore />}
              </IconButton>
            </Box>
            
            <Collapse in={expanded}>
              <List>
                {health.errors.map((error) => (
                  <ListItem key={error.id}>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Typography variant="subtitle2">{error.message}</Typography>
                          <Chip
                            label={error.severity}
                            color={getSeverityColor(error.severity) as any}
                            size="small"
                            sx={{ ml: 1 }}
                          />
                        </Box>
                      }
                      secondary={
                        <Typography variant="body2" color="text.secondary">
                          {error.type} • {new Date(error.timestamp).toLocaleString()}
                        </Typography>
                      }
                    />
                  </ListItem>
                ))}
              </List>
            </Collapse>
          </CardContent>
        </Card>
      )}
    </Box>
  );
};