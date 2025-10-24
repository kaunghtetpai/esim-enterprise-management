import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Stepper,
  Step,
  StepLabel,
  Alert
} from '@mui/material';
import { QrCode, Send, CheckCircle } from '@mui/icons-material';

const ActivationPage: React.FC = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [selectedCarrier, setSelectedCarrier] = useState('');
  const [deviceInfo, setDeviceInfo] = useState('');
  const [activationCode, setActivationCode] = useState('');

  const steps = ['Select Carrier', 'Device Information', 'Generate Code', 'Activate'];

  const carriers = [
    { code: 'MPT', name: 'Myanmar Posts and Telecommunications', mcc: '414', mnc: '01' },
    { code: 'ATOM', name: 'Atom Myanmar', mcc: '414', mnc: '06' },
    { code: 'U9', name: 'U9 Networks', mcc: '414', mnc: '07' },
    { code: 'MYTEL', name: 'MyTel Myanmar', mcc: '414', mnc: '09' }
  ];

  const handleNext = () => {
    if (activeStep === 2) {
      // Generate activation code
      const code = `LPA:1$${selectedCarrier.toLowerCase()}myanmar.china-xinghan.com$${generateRandomCode()}`;
      setActivationCode(code);
    }
    setActiveStep((prevStep) => prevStep + 1);
  };

  const generateRandomCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 5; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return `${result}-4F81A-FB${Math.floor(Math.random() * 999).toString().padStart(3, '0')}-${result.substring(0, 5)}`;
  };

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Grid container spacing={2}>
            {carriers.map((carrier) => (
              <Grid item xs={12} sm={6} key={carrier.code}>
                <Card 
                  sx={{ 
                    cursor: 'pointer',
                    border: selectedCarrier === carrier.code ? 2 : 1,
                    borderColor: selectedCarrier === carrier.code ? 'primary.main' : 'grey.300'
                  }}
                  onClick={() => setSelectedCarrier(carrier.code)}
                >
                  <CardContent>
                    <Typography variant="h6">{carrier.name}</Typography>
                    <Typography variant="body2" color="textSecondary">
                      MCC: {carrier.mcc} | MNC: {carrier.mnc}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        );
      case 1:
        return (
          <Box>
            <TextField
              fullWidth
              label="Device IMEI"
              margin="normal"
              placeholder="Enter device IMEI"
            />
            <TextField
              fullWidth
              label="Device Model"
              margin="normal"
              placeholder="Enter device model"
            />
            <TextField
              fullWidth
              label="User Email"
              margin="normal"
              placeholder="Enter user email"
            />
          </Box>
        );
      case 2:
        return (
          <Box textAlign="center">
            <Typography variant="h6" gutterBottom>
              Activation Code Generated
            </Typography>
            <Card sx={{ p: 2, bgcolor: 'grey.100' }}>
              <Typography variant="body1" sx={{ fontFamily: 'monospace', wordBreak: 'break-all' }}>
                {activationCode}
              </Typography>
            </Card>
            <Box mt={2}>
              <Button variant="outlined" startIcon={<QrCode />} sx={{ mr: 1 }}>
                Generate QR Code
              </Button>
              <Button variant="outlined" startIcon={<Send />}>
                Send via SMS
              </Button>
            </Box>
          </Box>
        );
      case 3:
        return (
          <Box textAlign="center">
            <CheckCircle color="success" sx={{ fontSize: 64, mb: 2 }} />
            <Typography variant="h5" gutterBottom>
              Activation Successful
            </Typography>
            <Alert severity="success" sx={{ mt: 2 }}>
              eSIM profile has been successfully activated for {selectedCarrier} carrier
            </Alert>
          </Box>
        );
      default:
        return null;
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        SIM Card Activation
      </Typography>

      <Card>
        <CardContent>
          <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {renderStepContent(activeStep)}

          <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 4 }}>
            <Button
              disabled={activeStep === 0}
              onClick={() => setActiveStep((prev) => prev - 1)}
            >
              Back
            </Button>
            <Button
              variant="contained"
              onClick={handleNext}
              disabled={activeStep === 0 && !selectedCarrier}
            >
              {activeStep === steps.length - 1 ? 'Finish' : 'Next'}
            </Button>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default ActivationPage;