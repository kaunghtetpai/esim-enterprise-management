import React, { useState } from 'react';
import { Box, Button, Card, CardContent, Typography, Stepper, Step, StepLabel, Alert } from '@mui/material';
import { useMutation } from '@tanstack/react-query';
import { apiClient } from '../services/apiClient';

const enrollmentSteps = [
  'Download Intune Company Portal',
  'Sign in with enterprise credentials',
  'Complete device enrollment',
  'Install required certificates'
];

export const DeviceEnrollment: React.FC = () => {
  const [activeStep, setActiveStep] = useState(0);

  const enrollMutation = useMutation({
    mutationFn: async (deviceInfo: any) => {
      const response = await apiClient.post('/intune/devices/enroll', deviceInfo);
      return response.data;
    },
    onSuccess: () => setActiveStep(prev => prev + 1),
    onError: (error: any) => console.error('Enrollment failed:', error)
  });

  const handleEnroll = () => {
    const deviceInfo = {
      deviceName: navigator.userAgent,
      platform: navigator.platform,
      userAgent: navigator.userAgent
    };
    enrollMutation.mutate(deviceInfo);
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>Device Enrollment</Typography>
        
        <Stepper activeStep={activeStep} sx={{ mb: 3 }}>
          {enrollmentSteps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {activeStep === 0 && (
          <Box>
            <Alert severity="info" sx={{ mb: 2 }}>
              Install Microsoft Intune Company Portal to manage your device
            </Alert>
            <Button 
              variant="contained" 
              onClick={handleEnroll}
              disabled={enrollMutation.isPending}
            >
              Start Enrollment
            </Button>
          </Box>
        )}

        {activeStep === enrollmentSteps.length && (
          <Alert severity="success">
            Device enrolled successfully! eSIM policies will be applied automatically.
          </Alert>
        )}
      </CardContent>
    </Card>
  );
};