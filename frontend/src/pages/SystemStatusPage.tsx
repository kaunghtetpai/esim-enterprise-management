import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Button,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Alert,
  LinearProgress
} from '@mui/material';
import {
  CheckCircle,
  Error,
  Warning,
  Refresh,
  GitHub,
  Cloud,
  Storage,
  Api,
  Security
} from '@mui/icons-material';

interface SystemStatus {
  service: string;
  status: 'healthy' | 'warning' | 'error';
  uptime: string;
  responseTime: string;
  lastCheck: string;
}

const SystemStatusPage: React.FC = () => {
  const [systemStatus, setSystemStatus] = useState<SystemStatus[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchSystemStatus = async () => {
    setLoading(true);
    // Simulate API call
    setTimeout(() => {
      setSystemStatus([
        {
          service: 'GitHub Repository',
          status: 'healthy',
          uptime: '99.9%',
          responseTime: '120ms',
          lastCheck: new Date().toLocaleTimeString()
        },
        {
          service: 'Vercel Deployment',
          status: 'error',
          uptime: '85.2%',
          responseTime: 'N/A',
          lastCheck: new Date().toLocaleTimeString()
        },
        {
          service: 'Database (Supabase)',
          status: 'healthy',
          uptime: '99.8%',
          responseTime: '45ms',
          lastCheck: new Date().toLocaleTimeString()
        },
        {
          service: 'API Backend',
          status: 'healthy',
          uptime: '99.5%',
          responseTime: '200ms',
          lastCheck: new Date().toLocaleTimeString()
        },
        {
          service: 'Microsoft Intune',
          status: 'warning',
          uptime: '98.1%',
          responseTime: '350ms',
          lastCheck: new Date().toLocaleTimeString()
        },
        {
          service: 'Azure AD Authentication',
          status: 'healthy',
          uptime: '99.9%',
          responseTime: '180ms',
          lastCheck: new Date().toLocaleTimeString()
        }
      ]);
      setLoading(false);
    }, 1000);
  };

  useEffect(() => {
    fetchSystemStatus();
  }, []);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle color="success" />;
      case 'warning':
        return <Warning color="warning" />;
      case 'error':
        return <Error color="error" />;
      default:
        return <CheckCircle />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'success';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  const getServiceIcon = (service: string) => {
    if (service.includes('GitHub')) return <GitHub />;
    if (service.includes('Vercel')) return <Cloud />;
    if (service.includes('Database')) return <Storage />;
    if (service.includes('API')) return <Api />;
    if (service.includes('Azure') || service.includes('Intune')) return <Security />;
    return <CheckCircle />;
  };

  const healthyCount = systemStatus.filter(s => s.status === 'healthy').length;
  const warningCount = systemStatus.filter(s => s.status === 'warning').length;
  const errorCount = systemStatus.filter(s => s.status === 'error').length;

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">
          System Status
        </Typography>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={fetchSystemStatus}
          disabled={loading}
        >
          Refresh Status
        </Button>
      </Box>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" color="success.main">
                Healthy Services
              </Typography>
              <Typography variant="h3" color="success.main">
                {healthyCount}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" color="warning.main">
                Warning Services
              </Typography>
              <Typography variant="h3" color="warning.main">
                {warningCount}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" color="error.main">
                Error Services
              </Typography>
              <Typography variant="h3" color="error.main">
                {errorCount}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {errorCount > 0 && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {errorCount} service(s) are experiencing issues. Please check the deployment status.
        </Alert>
      )}

      {warningCount > 0 && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          {warningCount} service(s) have warnings. Monitor performance closely.
        </Alert>
      )}

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Service Status Details
          </Typography>
          
          <List>
            {systemStatus.map((service, index) => (
              <ListItem key={index} divider>
                <ListItemIcon>
                  {getServiceIcon(service.service)}
                </ListItemIcon>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" justifyContent="space-between">
                      <Typography variant="body1">
                        {service.service}
                      </Typography>
                      <Chip
                        icon={getStatusIcon(service.status)}
                        label={service.status.toUpperCase()}
                        color={getStatusColor(service.status) as any}
                        size="small"
                      />
                    </Box>
                  }
                  secondary={
                    <Box display="flex" justifyContent="space-between" mt={1}>
                      <Typography variant="caption">
                        Uptime: {service.uptime}
                      </Typography>
                      <Typography variant="caption">
                        Response: {service.responseTime}
                      </Typography>
                      <Typography variant="caption">
                        Last Check: {service.lastCheck}
                      </Typography>
                    </Box>
                  }
                />
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>

      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Quick Actions
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                fullWidth
                variant="outlined"
                href="https://github.com/kaunghtetpai/esim-enterprise-management"
                target="_blank"
                startIcon={<GitHub />}
              >
                GitHub Repository
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                fullWidth
                variant="outlined"
                href="https://vercel.com/e-sim/esim-enterprise-management"
                target="_blank"
                startIcon={<Cloud />}
              >
                Vercel Dashboard
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                fullWidth
                variant="outlined"
                href="https://portal.azure.com"
                target="_blank"
                startIcon={<Security />}
              >
                Azure Portal
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                fullWidth
                variant="outlined"
                onClick={fetchSystemStatus}
                startIcon={<Refresh />}
              >
                Refresh All
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
};

export default SystemStatusPage;