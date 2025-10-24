import React from 'react';
import { Box, Card, CardContent, Typography, FormControl, InputLabel, Select, MenuItem, Button, Switch, FormControlLabel } from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../services/apiClient';

interface PolicyConfig {
  carrier: string;
  autoEnable: boolean;
  localUIEnabled: boolean;
  PPR1Allowed: boolean;
  maxAttempts: number;
}

export const ESIMPolicyConfig: React.FC = () => {
  const { control, handleSubmit } = useForm<PolicyConfig>();
  const queryClient = useQueryClient();

  const policyMutation = useMutation({
    mutationFn: async (config: PolicyConfig) => {
      const response = await apiClient.post('/intune/policies/esim', config);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['policies'] });
    }
  });

  const onSubmit = (data: PolicyConfig) => {
    policyMutation.mutate(data);
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>eSIM Policy Configuration</Typography>
        
        <Box component="form" onSubmit={handleSubmit(onSubmit)} sx={{ mt: 2 }}>
          <Controller
            name="carrier"
            control={control}
            defaultValue="MPT"
            render={({ field }) => (
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Carrier</InputLabel>
                <Select {...field} label="Carrier">
                  <MenuItem value="MPT">MPT</MenuItem>
                  <MenuItem value="ATOM">ATOM</MenuItem>
                  <MenuItem value="U9">U9</MenuItem>
                  <MenuItem value="MYTEL">MYTEL</MenuItem>
                </Select>
              </FormControl>
            )}
          />

          <Controller
            name="autoEnable"
            control={control}
            defaultValue={true}
            render={({ field }) => (
              <FormControlLabel
                control={<Switch {...field} checked={field.value} />}
                label="Auto-enable profiles"
                sx={{ mb: 2, display: 'block' }}
              />
            )}
          />

          <Controller
            name="localUIEnabled"
            control={control}
            defaultValue={false}
            render={({ field }) => (
              <FormControlLabel
                control={<Switch {...field} checked={field.value} />}
                label="Allow local UI access"
                sx={{ mb: 2, display: 'block' }}
              />
            )}
          />

          <Controller
            name="PPR1Allowed"
            control={control}
            defaultValue={true}
            render={({ field }) => (
              <FormControlLabel
                control={<Switch {...field} checked={field.value} />}
                label="Allow PPR1 operations"
                sx={{ mb: 3, display: 'block' }}
              />
            )}
          />

          <Button 
            type="submit" 
            variant="contained" 
            disabled={policyMutation.isPending}
            fullWidth
          >
            Apply Policy
          </Button>
        </Box>
      </CardContent>
    </Card>
  );
};