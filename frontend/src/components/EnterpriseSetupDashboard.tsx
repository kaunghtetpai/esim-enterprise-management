import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Chip,
  Grid,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  CheckCircle,
  Error,
  Warning,
  PlayArrow,
  Refresh,
  Settings,
  Security,
  Devices,
  Group,
  Policy,
  Apps,
  Assessment
} from '@mui/icons-material';

interface SetupPhase {
  phase: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  errors: string[];
  fixed: string[];
  startTime?: string;
  endTime?: string;
}

const phaseConfig = [
  {
    id: 'Phase1_EntraID',
    title: 'Microsoft Entra ID 2 Activation',
    description: 'Activate and configure Entra ID with admin privileges',
    icon: <Security />
  },
  {
    id: 'Phase2_Intune',
    title: 'Microsoft Intune Integration',
    description: 'Integrate Entra ID with Intune for device management',
    icon: <Devices />
  },
  {
    id: 'Phase3_eSIM',
    title: 'eSIM Enterprise Management',
    description: 'Configure MPT, ATOM, and MYTEL carrier groups',
    icon: <Settings />
  },
  {
    id: 'Phase4_Policies',
    title: 'Device & Policy Management',
    description: 'Create compliance policies and configuration profiles',
    icon: <Policy />
  },
  {
    id: 'Phase5_Verification',
    title: 'System Verification',
    description: 'Verify all components and error handling',
    icon: <Assessment />
  },
  {
    id: 'Phase6_CompanyPortal',
    title: 'Company Portal Configuration',
    description: 'Configure Intune Company Portal branding',
    icon: <Apps />
  },
  {
    id: 'Phase7_FinalValidation',
    title: 'Final Validation & Reporting',
    description: 'Generate final reports and audit logs',
    icon: <CheckCircle />
  }
];

export const EnterpriseSetupDashboard: React.FC = () => {
  const [phases, setPhases] = useState<SetupPhase[]>([]);
  const [loading, setLoading] = useState(false);
  const [setupRunning, setSetupRunning] = useState(false);
  const [activeStep, setActiveStep] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedPhase, setSelectedPhase] = useState<SetupPhase | null>(null);

  const fetchSetupStatus = async () => {
    try {
      const response = await fetch('/api/v1/enterprise/status');
      const result = await response.json();
      if (result.success) {
        setPhases(result.data);
        
        // Update active step
        const completedPhases = result.data.filter((p: SetupPhase) => p.status === 'completed').length;
        setActiveStep(completedPhases);
      }
    } catch (error) {
      console.error('Failed to fetch setup status:', error);
    }
  };

  const runCompleteSetup = async () => {
    setSetupRunning(true);
    try {
      const response = await fetch('/api/v1/enterprise/setup', {
        method: 'POST'
      });
      const result = await response.json();
      
      if (result.success) {
        await fetchSetupStatus();
      }
    } catch (error) {
      console.error('Setup failed:', error);
    } finally {
      setSetupRunning(false);
    }
  };

  const runSinglePhase = async (phaseNumber: number) => {
    setLoading(true);
    try {
      const response = await fetch(`/api/v1/enterprise/phase/${phaseNumber}`, {
        method: 'POST'
      });
      const result = await response.json();
      
      if (result.success) {
        await fetchSetupStatus();
      }
    } catch (error) {
      console.error(`Phase ${phaseNumber} failed:`, error);
    } finally {
      setLoading(false);
    }
  };

  const validateSetup = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/enterprise/validate');
      const result = await response.json();
      
      // Show validation results
      console.log('Validation results:', result.data);
    } catch (error) {
      console.error('Validation failed:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSetupStatus();
    const interval = setInterval(fetchSetupStatus, 10000); // Check every 10 seconds
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'success';
      case 'failed': return 'error';
      case 'running': return 'warning';
      default: return 'default';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle color="success" />;
      case 'failed': return <Error color="error" />;
      case 'running': return <Warning color="warning" />;
      default: return null;
    }
  };

  const calculateProgress = () => {
    if (phases.length === 0) return 0;
    const completed = phases.filter(p => p.status === 'completed').length;
    return (completed / phases.length) * 100;
  };

  const openPhaseDetails = (phase: SetupPhase) => {
    setSelectedPhase(phase);
    setDialogOpen(true);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        eSIM Enterprise Management Setup
      </Typography>
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        Tenant: mdm.esim.com.mm | Admin: admin@mdm.esim.com.mm
      </Typography>

      {/* Progress Overview */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">Setup Progress</Typography>
            <Box>
              <Button
                startIcon={<PlayArrow />}
                onClick={runCompleteSetup}
                disabled={setupRunning}
                variant="contained"
                color="primary"
                sx={{ mr: 1 }}
              >
                {setupRunning ? 'Running...' : 'Run Complete Setup'}
              </Button>
              <Button
                startIcon={<Assessment />}
                onClick={validateSetup}
                disabled={loading}
                variant="outlined"
                sx={{ mr: 1 }}
              >
                Validate
              </Button>
              <Button
                startIcon={<Refresh />}
                onClick={fetchSetupStatus}
                disabled={loading}
              >
                Refresh
              </Button>
            </Box>
          </Box>
          
          <LinearProgress
            variant="determinate"
            value={calculateProgress()}
            sx={{ height: 10, borderRadius: 5, mb: 1 }}
          />
          <Typography variant="body2" color="text.secondary">
            {Math.round(calculateProgress())}% Complete ({phases.filter(p => p.status === 'completed').length}/{phases.length} phases)
          </Typography>
        </CardContent>
      </Card>

      {/* Phase Stepper */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Setup Phases</Typography>
              
              <Stepper activeStep={activeStep} orientation="vertical">
                {phaseConfig.map((config, index) => {
                  const phase = phases.find(p => p.phase === config.id);
                  const phaseNumber = index + 1;
                  
                  return (
                    <Step key={config.id}>
                      <StepLabel
                        icon={getStatusIcon(phase?.status || 'pending') || config.icon}
                        error={phase?.status === 'failed'}
                      >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="subtitle1">{config.title}</Typography>
                          <Chip
                            label={phase?.status || 'pending'}
                            color={getStatusColor(phase?.status || 'pending') as any}
                            size="small"
                          />
                        </Box>
                      </StepLabel>
                      <StepContent>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                          {config.description}
                        </Typography>
                        
                        {phase && (phase.errors.length > 0 || phase.fixed.length > 0) && (
                          <Box sx={{ mb: 2 }}>
                            {phase.errors.length > 0 && (
                              <Alert severity="error" sx={{ mb: 1 }}>
                                {phase.errors.length} error(s) found
                              </Alert>
                            )}
                            {phase.fixed.length > 0 && (
                              <Alert severity="success" sx={{ mb: 1 }}>
                                {phase.fixed.length} issue(s) fixed
                              </Alert>
                            )}
                          </Box>
                        )}
                        
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <Button
                            size="small"
                            onClick={() => runSinglePhase(phaseNumber)}
                            disabled={loading || phase?.status === 'running'}
                            variant="contained"
                          >
                            {phase?.status === 'running' ? 'Running...' : 'Run Phase'}
                          </Button>
                          {phase && (
                            <Button
                              size="small"
                              onClick={() => openPhaseDetails(phase)}
                              variant="outlined"
                            >
                              Details
                            </Button>
                          )}
                        </Box>
                      </StepContent>
                    </Step>
                  );
                })}
              </Stepper>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>System Status</Typography>
              
              <List dense>
                <ListItem>
                  <ListItemIcon>
                    <Security color={phases.find(p => p.phase === 'Phase1_EntraID')?.status === 'completed' ? 'success' : 'disabled'} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Entra ID"
                    secondary={phases.find(p => p.phase === 'Phase1_EntraID')?.status || 'pending'}
                  />
                </ListItem>
                
                <ListItem>
                  <ListItemIcon>
                    <Devices color={phases.find(p => p.phase === 'Phase2_Intune')?.status === 'completed' ? 'success' : 'disabled'} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Intune"
                    secondary={phases.find(p => p.phase === 'Phase2_Intune')?.status || 'pending'}
                  />
                </ListItem>
                
                <ListItem>
                  <ListItemIcon>
                    <Group color={phases.find(p => p.phase === 'Phase3_eSIM')?.status === 'completed' ? 'success' : 'disabled'} />
                  </ListItemIcon>
                  <ListItemText
                    primary="eSIM Carriers"
                    secondary="MPT, ATOM, MYTEL"
                  />
                </ListItem>
                
                <ListItem>
                  <ListItemIcon>
                    <Policy color={phases.find(p => p.phase === 'Phase4_Policies')?.status === 'completed' ? 'success' : 'disabled'} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Policies"
                    secondary={phases.find(p => p.phase === 'Phase4_Policies')?.status || 'pending'}
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Phase Details Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Phase Details: {selectedPhase?.phase}
        </DialogTitle>
        <DialogContent>
          {selectedPhase && (
            <Box>
              <Typography variant="h6" gutterBottom>Status: {selectedPhase.status}</Typography>
              
              {selectedPhase.errors.length > 0 && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" color="error">Errors:</Typography>
                  <List dense>
                    {selectedPhase.errors.map((error, index) => (
                      <ListItem key={index}>
                        <ListItemIcon>
                          <Error color="error" />
                        </ListItemIcon>
                        <ListItemText primary={error} />
                      </ListItem>
                    ))}
                  </List>
                </Box>
              )}
              
              {selectedPhase.fixed.length > 0 && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" color="success.main">Fixed:</Typography>
                  <List dense>
                    {selectedPhase.fixed.map((fix, index) => (
                      <ListItem key={index}>
                        <ListItemIcon>
                          <CheckCircle color="success" />
                        </ListItemIcon>
                        <ListItemText primary={fix} />
                      </ListItem>
                    ))}
                  </List>
                </Box>
              )}
              
              {selectedPhase.startTime && (
                <Typography variant="body2" color="text.secondary">
                  Started: {new Date(selectedPhase.startTime).toLocaleString()}
                </Typography>
              )}
              {selectedPhase.endTime && (
                <Typography variant="body2" color="text.secondary">
                  Completed: {new Date(selectedPhase.endTime).toLocaleString()}
                </Typography>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};