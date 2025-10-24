import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, Button, List, ListItem, ListItemText, Chip, LinearProgress } from '@mui/material';
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiClient } from '../services/apiClient';

interface Device {
  id: string;
  deviceName: string;
  complianceState: string;
}

interface Profile {
  id: string;
  profile_name: string;
  carrier: string;
  ICCID: string;
}

export const ProfileDeployment: React.FC = () => {
  const [selectedDevices, setSelectedDevices] = useState<string[]>([]);
  const [selectedProfile, setSelectedProfile] = useState<string>('');

  const { data: devices } = useQuery({
    queryKey: ['intune-devices'],
    queryFn: async () => {
      const response = await apiClient.get('/intune/devices');
      return response.data.data.devices;
    }
  });

  const { data: profiles } = useQuery({
    queryKey: ['profiles'],
    queryFn: async () => {
      const response = await apiClient.get('/profiles');
      return response.data.data.profiles;
    }
  });

  const deployMutation = useMutation({
    mutationFn: async ({ deviceIds, profileId }: { deviceIds: string[], profileId: string }) => {
      const deployments = deviceIds.map(deviceId => 
        apiClient.post(`/intune/devices/${deviceId}/esim/configure`, { profileId })
      );
      return Promise.all(deployments);
    },
    onSuccess: () => {
      setSelectedDevices([]);
      setSelectedProfile('');
    }
  });

  const handleDeploy = () => {
    if (selectedDevices.length > 0 && selectedProfile) {
      deployMutation.mutate({ deviceIds: selectedDevices, profileId: selectedProfile });
    }
  };

  return (
    <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>Managed Devices</Typography>
          <List>
            {devices?.map((device: Device) => (
              <ListItem 
                key={device.id}
                button
                selected={selectedDevices.includes(device.id)}
                onClick={() => {
                  setSelectedDevices(prev => 
                    prev.includes(device.id) 
                      ? prev.filter(id => id !== device.id)
                      : [...prev, device.id]
                  );
                }}
              >
                <ListItemText 
                  primary={device.deviceName}
                  secondary={
                    <Chip 
                      label={device.complianceState} 
                      color={device.complianceState === 'compliant' ? 'success' : 'warning'}
                      size="small"
                    />
                  }
                />
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>eSIM Profiles</Typography>
          <List>
            {profiles?.map((profile: Profile) => (
              <ListItem 
                key={profile.id}
                button
                selected={selectedProfile === profile.id}
                onClick={() => setSelectedProfile(profile.id)}
              >
                <ListItemText 
                  primary={profile.profile_name}
                  secondary={`${profile.carrier} - ${profile.ICCID}`}
                />
              </ListItem>
            ))}
          </List>

          {deployMutation.isPending && <LinearProgress sx={{ mt: 2 }} />}

          <Button 
            variant="contained" 
            fullWidth 
            sx={{ mt: 2 }}
            disabled={selectedDevices.length === 0 || !selectedProfile || deployMutation.isPending}
            onClick={handleDeploy}
          >
            Deploy to {selectedDevices.length} Device(s)
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
};