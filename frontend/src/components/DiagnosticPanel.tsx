import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, Button, Alert, Chip, List, ListItem, ListItemText, CircularProgress, Accordion, AccordionSummary, AccordionDetails } from '@mui/material';
import { ExpandMore, Healing, Warning, Error, CheckCircle } from '@mui/icons-material';
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiClient } from '../services/apiClient';

interface DiagnosticResult {
  component: string;
  status: 'healthy' | 'warning' | 'error';
  message: string;
  details?: any;
  timestamp: string;
}

export const DiagnosticPanel: React.FC = () => {
  const [selectedComponent, setSelectedComponent] = useState<string>('');

  const { data: healthData, refetch: refetchHealth, isLoading } = useQuery({
    queryKey: ['diagnostic-health'],
    queryFn: async () => {
      const response = await apiClient.get('/diagnostics/health');
      return response.data.data;
    },
    refetchInterval: 30000
  });

  const solveMutation = useMutation({
    mutationFn: async ({ component, issue }: { component: string; issue: string }) => {
      const response = await apiClient.post('/diagnostics/solve', { component, issue });
      return response.data.data;
    },
    onSuccess: () => {
      refetchHealth();
    }
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy': return <CheckCircle color="success" />;
      case 'warning': return <Warning color="warning" />;
      case 'error': return <Error color="error" />;
      default: return <CheckCircle />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'success';
      case 'warning': return 'warning';
      case 'error': return 'error';
      default: return 'default';
    }
  };

  const handleSolveProblem = (component: string, message: string) => {
    setSelectedComponent(component);
    solveMutation.mutate({ component, issue: message });
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5">System Diagnostics</Typography>
        <Button variant="contained" onClick={() => refetchHealth()} disabled={isLoading}>
          Run Diagnostics
        </Button>
      </Box>

      {healthData && (
        <>
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>Overall System Status</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                {getStatusIcon(healthData.overallStatus)}
                <Chip 
                  label={healthData.overallStatus.toUpperCase()} 
                  color={getStatusColor(healthData.overallStatus)}
                />
              </Box>
              
              <Box sx={{ display: 'flex', gap: 2 }}>
                <Chip label={`${healthData.summary.healthy} Healthy`} color="success" variant="outlined" />
                <Chip label={`${healthData.summary.warning} Warnings`} color="warning" variant="outlined" />
                <Chip label={`${healthData.summary.error} Errors`} color="error" variant="outlined" />
              </Box>
            </CardContent>
          </Card>

          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>Component Status</Typography>
              {healthData.results.map((result: DiagnosticResult, index: number) => (
                <Accordion key={index}>
                  <AccordionSummary expandIcon={<ExpandMore />}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, width: '100%' }}>
                      {getStatusIcon(result.status)}
                      <Typography sx={{ flexGrow: 1 }}>{result.component.replace('_', ' ').toUpperCase()}</Typography>
                      <Chip 
                        label={result.status} 
                        color={getStatusColor(result.status)}
                        size="small"
                      />
                    </Box>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      {result.message}
                    </Typography>
                    
                    {result.details && (
                      <Box sx={{ mt: 1, p: 1, bgcolor: 'grey.50', borderRadius: 1 }}>
                        <Typography variant="caption" display="block">Details:</Typography>
                        <pre style={{ fontSize: '0.75rem', margin: 0 }}>
                          {JSON.stringify(result.details, null, 2)}
                        </pre>
                      </Box>
                    )}
                    
                    {result.status !== 'healthy' && (
                      <Button
                        variant="outlined"
                        size="small"
                        startIcon={<Healing />}
                        sx={{ mt: 2 }}
                        onClick={() => handleSolveProblem(result.component, result.message)}
                        disabled={solveMutation.isPending && selectedComponent === result.component}
                      >
                        {solveMutation.isPending && selectedComponent === result.component ? 'Solving...' : 'Auto-Fix'}
                      </Button>
                    )}
                  </AccordionDetails>
                </Accordion>
              ))}
            </CardContent>
          </Card>

          {healthData.recommendations && healthData.recommendations.length > 0 && (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Recommendations</Typography>
                <List>
                  {healthData.recommendations.map((recommendation: string, index: number) => (
                    <ListItem key={index}>
                      <ListItemText primary={recommendation} />
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          )}

          {solveMutation.data && (
            <Alert 
              severity={solveMutation.data.success ? 'success' : 'warning'} 
              sx={{ mt: 2 }}
            >
              <Typography variant="subtitle2">{solveMutation.data.message}</Typography>
              {solveMutation.data.actions && (
                <List dense>
                  {solveMutation.data.actions.map((action: string, index: number) => (
                    <ListItem key={index}>
                      <ListItemText primary={`• ${action}`} />
                    </ListItem>
                  ))}
                </List>
              )}
            </Alert>
          )}
        </>
      )}
    </Box>
  );
};