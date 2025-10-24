import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Chip,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField
} from '@mui/material';
import {
  Rocket,
  GitHub,
  CloudUpload,
  Timeline,
  CheckCircle,
  Error,
  Warning,
  Refresh,
  Undo,
  PlayArrow,
  Visibility
} from '@mui/icons-material';

interface Deployment {
  id: string;
  status: 'pending' | 'building' | 'ready' | 'error' | 'canceled';
  url?: string;
  createdAt: string;
  readyAt?: string;
}

interface CICDMetrics {
  deploymentFrequency: number;
  successRate: number;
  averageBuildTime: number;
  failureRate: number;
  lastDeployment: string;
  totalDeployments: number;
}

export const CICDDashboard: React.FC = () => {
  const [deployments, setDeployments] = useState<Deployment[]>([]);
  const [metrics, setMetrics] = useState<CICDMetrics | null>(null);
  const [loading, setLoading] = useState(false);
  const [deployDialogOpen, setDeployDialogOpen] = useState(false);
  const [rollbackDialogOpen, setRollbackDialogOpen] = useState(false);
  const [selectedDeployment, setSelectedDeployment] = useState<string>('');
  const [branch, setBranch] = useState('main');

  const fetchDeploymentStatus = async () => {
    try {
      const response = await fetch('/api/v1/cicd/deployments');
      const result = await response.json();
      if (result.success) {
        setDeployments(result.data);
      }
    } catch (error) {
      console.error('Failed to fetch deployments:', error);
    }
  };

  const fetchMetrics = async () => {
    try {
      const response = await fetch('/api/v1/cicd/metrics');
      const result = await response.json();
      if (result.success) {
        setMetrics(result.data);
      }
    } catch (error) {
      console.error('Failed to fetch metrics:', error);
    }
  };

  const triggerDeployment = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/cicd/deploy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ branch })
      });
      
      const result = await response.json();
      if (result.success) {
        await fetchDeploymentStatus();
        setDeployDialogOpen(false);
      }
    } catch (error) {
      console.error('Deployment failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const rollbackDeployment = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/cicd/rollback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ deploymentId: selectedDeployment })
      });
      
      const result = await response.json();
      if (result.success) {
        await fetchDeploymentStatus();
        setRollbackDialogOpen(false);
      }
    } catch (error) {
      console.error('Rollback failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const validateDeployment = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/cicd/validate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: 'https://esim-enterprise-management.vercel.app' })
      });
      
      const result = await response.json();
      console.log('Validation result:', result);
    } catch (error) {
      console.error('Validation failed:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDeploymentStatus();
    fetchMetrics();
    const interval = setInterval(() => {
      fetchDeploymentStatus();
      fetchMetrics();
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ready': return 'success';
      case 'building': return 'warning';
      case 'error': return 'error';
      case 'canceled': return 'default';
      default: return 'info';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ready': return <CheckCircle color="success" />;
      case 'building': return <CloudUpload color="warning" />;
      case 'error': return <Error color="error" />;
      default: return <Timeline />;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        CI/CD Pipeline Dashboard
      </Typography>
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        GitHub Repository: kaunghtetpai/esim-enterprise-management
      </Typography>

      {/* Action Buttons */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2 }}>
        <Button
          startIcon={<PlayArrow />}
          onClick={() => setDeployDialogOpen(true)}
          variant="contained"
          color="primary"
        >
          Deploy
        </Button>
        <Button
          startIcon={<Undo />}
          onClick={() => setRollbackDialogOpen(true)}
          variant="outlined"
          color="warning"
        >
          Rollback
        </Button>
        <Button
          startIcon={<Visibility />}
          onClick={validateDeployment}
          variant="outlined"
          disabled={loading}
        >
          Validate
        </Button>
        <Button
          startIcon={<Refresh />}
          onClick={() => {
            fetchDeploymentStatus();
            fetchMetrics();
          }}
          variant="outlined"
        >
          Refresh
        </Button>
      </Box>

      {/* Metrics Overview */}
      {metrics && (
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="primary">
                  {metrics.totalDeployments}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total Deployments
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="success.main">
                  {metrics.successRate.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Success Rate
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="info.main">
                  {Math.round(metrics.averageBuildTime)}s
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Avg Build Time
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="warning.main">
                  {metrics.deploymentFrequency.toFixed(1)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Deploys/Day
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Deployment Status */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Deployments
              </Typography>
              
              <List>
                {deployments.slice(0, 10).map((deployment) => (
                  <ListItem key={deployment.id}>
                    <ListItemIcon>
                      {getStatusIcon(deployment.status)}
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="subtitle2">
                            {deployment.id.substring(0, 8)}
                          </Typography>
                          <Chip
                            label={deployment.status}
                            color={getStatusColor(deployment.status) as any}
                            size="small"
                          />
                          {deployment.url && (
                            <Button
                              size="small"
                              href={deployment.url}
                              target="_blank"
                              rel="noopener noreferrer"
                            >
                              View
                            </Button>
                          )}
                        </Box>
                      }
                      secondary={
                        <Typography variant="body2" color="text.secondary">
                          {new Date(deployment.createdAt).toLocaleString()}
                          {deployment.readyAt && (
                            <> • Ready: {new Date(deployment.readyAt).toLocaleString()}</>
                          )}
                        </Typography>
                      }
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Production URLs
              </Typography>
              
              <List dense>
                <ListItem>
                  <ListItemIcon>
                    <Rocket color="primary" />
                  </ListItemIcon>
                  <ListItemText
                    primary="Vercel Production"
                    secondary={
                      <Button
                        size="small"
                        href="https://esim-enterprise-management.vercel.app"
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        esim-enterprise-management.vercel.app
                      </Button>
                    }
                  />
                </ListItem>
                
                <ListItem>
                  <ListItemIcon>
                    <CloudUpload color="secondary" />
                  </ListItemIcon>
                  <ListItemText
                    primary="Custom Domain"
                    secondary={
                      <Button
                        size="small"
                        href="https://portal.nexorasim.com"
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        portal.nexorasim.com
                      </Button>
                    }
                  />
                </ListItem>
                
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
                        View Repository
                      </Button>
                    }
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Deploy Dialog */}
      <Dialog open={deployDialogOpen} onClose={() => setDeployDialogOpen(false)}>
        <DialogTitle>Trigger Deployment</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Branch"
            value={branch}
            onChange={(e) => setBranch(e.target.value)}
            margin="normal"
            helperText="Enter the branch name to deploy"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeployDialogOpen(false)}>Cancel</Button>
          <Button onClick={triggerDeployment} disabled={loading} variant="contained">
            {loading ? 'Deploying...' : 'Deploy'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Rollback Dialog */}
      <Dialog open={rollbackDialogOpen} onClose={() => setRollbackDialogOpen(false)}>
        <DialogTitle>Rollback Deployment</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This will rollback to the previous successful deployment.
          </Alert>
          <TextField
            fullWidth
            label="Deployment ID (optional)"
            value={selectedDeployment}
            onChange={(e) => setSelectedDeployment(e.target.value)}
            margin="normal"
            helperText="Leave empty to rollback to previous deployment"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRollbackDialogOpen(false)}>Cancel</Button>
          <Button onClick={rollbackDeployment} disabled={loading} variant="contained" color="warning">
            {loading ? 'Rolling back...' : 'Rollback'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};