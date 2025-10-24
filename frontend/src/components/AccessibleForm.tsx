import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  FormControl,
  FormLabel,
  FormHelperText,
  Alert,
  CircularProgress,
  Select,
  MenuItem,
  InputLabel,
  Checkbox,
  FormControlLabel
} from '@mui/material';
import { Search, Add } from '@mui/icons-material';

interface FormData {
  iccid: string;
  carrier: string;
  userEmail: string;
  department: string;
  acceptTerms: boolean;
}

const AccessibleForm: React.FC = () => {
  const [formData, setFormData] = useState<FormData>({
    iccid: '',
    carrier: '',
    userEmail: '',
    department: '',
    acceptTerms: false
  });
  const [errors, setErrors] = useState<Partial<FormData>>({});
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const validateForm = (): boolean => {
    const newErrors: Partial<FormData> = {};
    
    if (!formData.iccid || formData.iccid.length < 19) {
      newErrors.iccid = 'ICCID must be at least 19 digits';
    }
    
    if (!formData.carrier) {
      newErrors.carrier = 'Please select a carrier';
    }
    
    if (!formData.userEmail || !/\S+@\S+\.\S+/.test(formData.userEmail)) {
      newErrors.userEmail = 'Please enter a valid email address';
    }
    
    if (!formData.department) {
      newErrors.department = 'Department is required';
    }
    
    if (!formData.acceptTerms) {
      newErrors.acceptTerms = 'You must accept the terms and conditions' as any;
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    setLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      setLoading(false);
      setSuccess(true);
    }, 2000);
  };

  const handleInputChange = (field: keyof FormData) => (
    e: React.ChangeEvent<HTMLInputElement | { value: unknown }>
  ) => {
    const value = e.target.type === 'checkbox' 
      ? (e.target as HTMLInputElement).checked 
      : e.target.value;
      
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  };

  if (success) {
    return (
      <Alert severity="success" sx={{ mt: 2 }}>
        SIM card registration completed successfully!
      </Alert>
    );
  }

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ maxWidth: 600, mx: 'auto', p: 3 }}>
      <Box mb={3}>
        <FormLabel component="legend" sx={{ fontSize: '1.25rem', fontWeight: 600, mb: 2 }}>
          SIM Card Registration Form
        </FormLabel>
      </Box>

      <FormControl fullWidth margin="normal" error={!!errors.iccid}>
        <TextField
          id="iccid-input"
          label="ICCID Number"
          value={formData.iccid}
          onChange={handleInputChange('iccid')}
          error={!!errors.iccid}
          helperText={errors.iccid || 'Enter the 19-20 digit ICCID number'}
          placeholder="89950182421199985068"
          inputProps={{
            'aria-describedby': 'iccid-helper-text',
            maxLength: 20,
            pattern: '[0-9]*',
            inputMode: 'numeric'
          }}
          sx={{ minHeight: 44 }}
        />
      </FormControl>

      <FormControl fullWidth margin="normal" error={!!errors.carrier}>
        <InputLabel id="carrier-label">Carrier</InputLabel>
        <Select
          labelId="carrier-label"
          id="carrier-select"
          value={formData.carrier}
          onChange={handleInputChange('carrier')}
          label="Carrier"
          aria-describedby="carrier-helper-text"
          sx={{ minHeight: 44 }}
        >
          <MenuItem value="MPT">MPT (Myanmar Posts and Telecommunications)</MenuItem>
          <MenuItem value="ATOM">ATOM Myanmar</MenuItem>
          <MenuItem value="U9">U9 Networks</MenuItem>
          <MenuItem value="MYTEL">MyTel Myanmar</MenuItem>
        </Select>
        {errors.carrier && (
          <FormHelperText id="carrier-helper-text">{errors.carrier}</FormHelperText>
        )}
      </FormControl>

      <FormControl fullWidth margin="normal" error={!!errors.userEmail}>
        <TextField
          id="email-input"
          label="User Email"
          type="email"
          value={formData.userEmail}
          onChange={handleInputChange('userEmail')}
          error={!!errors.userEmail}
          helperText={errors.userEmail || 'Email address for SIM card assignment'}
          placeholder="user@company.com"
          inputProps={{
            'aria-describedby': 'email-helper-text'
          }}
          sx={{ minHeight: 44 }}
        />
      </FormControl>

      <FormControl fullWidth margin="normal" error={!!errors.department}>
        <TextField
          id="department-input"
          label="Department"
          value={formData.department}
          onChange={handleInputChange('department')}
          error={!!errors.department}
          helperText={errors.department || 'User department or cost center'}
          placeholder="IT Department"
          inputProps={{
            'aria-describedby': 'department-helper-text'
          }}
          sx={{ minHeight: 44 }}
        />
      </FormControl>

      <FormControl error={!!errors.acceptTerms} sx={{ mt: 2 }}>
        <FormControlLabel
          control={
            <Checkbox
              checked={formData.acceptTerms}
              onChange={handleInputChange('acceptTerms')}
              name="acceptTerms"
              color="primary"
              inputProps={{
                'aria-describedby': 'terms-helper-text'
              }}
            />
          }
          label="I accept the terms and conditions for eSIM usage"
        />
        {errors.acceptTerms && (
          <FormHelperText id="terms-helper-text">{errors.acceptTerms}</FormHelperText>
        )}
      </FormControl>

      <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
        <Button
          type="submit"
          variant="contained"
          disabled={loading}
          startIcon={loading ? <CircularProgress size={20} /> : <Add />}
          sx={{ minHeight: 44, minWidth: 120 }}
          aria-describedby="submit-helper-text"
        >
          {loading ? 'Registering...' : 'Register SIM'}
        </Button>
        
        <Button
          type="button"
          variant="outlined"
          startIcon={<Search />}
          sx={{ minHeight: 44, minWidth: 120 }}
          onClick={() => {/* Search functionality */}}
        >
          Search Existing
        </Button>
      </Box>
      
      <FormHelperText id="submit-helper-text" sx={{ mt: 1 }}>
        All fields are required. Form data will be encrypted and stored securely.
      </FormHelperText>
    </Box>
  );
};

export default AccessibleForm;