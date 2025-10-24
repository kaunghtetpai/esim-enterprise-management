import React, { useState } from 'react';
import {
  Box, Typography, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, IconButton, Grid, Card, CardContent,
  Skeleton, Alert, useMediaQuery, useTheme, TextField, InputAdornment
} from '@mui/material';
import { Add, Refresh, PhoneAndroid, Computer, Tablet, Search, Sync } from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';

export const DevicesPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [searchTerm, setSearchTerm] = useState('');

  const { data: devices = [], isLoading, error, refetch } = useQuery({
    queryKey: ['devices'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('devices')
        .select(`
          *,
          users(display_name)
        `)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return data || [];
    }
  });

  const filteredDevices = devices.filter(device => 
    device.device_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    device.model?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    device.serial_number?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getComplianceColor = (state: string) => {
    switch (state) {
      case 'compliant': return 'success';
      case 'noncompliant': return 'error';
      case 'unknown': return 'warning';
      default: return 'default';
    }
  };

  const getDeviceIcon = (model: string) => {
    if (model.includes('iPhone') || model.includes('Galaxy')) return <PhoneAndroid />;
    if (model.includes('iPad') || model.includes('Tab')) return <Tablet />;
    return <Computer />;
  };

  return (
    <Box p={3}>
      <Box 
        display="flex" 
        flexDirection={{ xs: 'column', md: 'row' }}
        justifyContent="space-between" 
        alignItems={{ xs: 'stretch', md: 'center' }}
        mb={3}
        gap={2}
      >
        <Typography variant="h4" component="h1" sx={{ fontWeight: 600 }}>
          Device Management
        </Typography>
        <Box display="flex" gap={1} flexDirection={{ xs: 'column', sm: 'row' }}>
          <Button
            variant="outlined"
            startIcon={<Sync />}
            onClick={() => refetch()}
            disabled={isLoading}
            size={isMobile ? 'small' : 'medium'}
          >
            Sync from Intune
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            size={isMobile ? 'small' : 'medium'}
          >
            Register Device
          </Button>
        </Box>
      </Box>

      <Box mb={3}>
        <TextField
          fullWidth
          placeholder="Search devices by name, model, or serial number..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search />
              </InputAdornment>
            ),
          }}
          sx={{ maxWidth: { md: 400 } }}
        />
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Failed to load devices. Please try again.
        </Alert>
      )}

      <Grid container spacing={{ xs: 2, md: 3 }} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              {isLoading ? (
                <Skeleton variant="rectangular" height={60} />
              ) : (
                <>
                  <Typography color="textSecondary" gutterBottom>
                    Total Devices
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {filteredDevices.length}
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              {isLoading ? (
                <Skeleton variant="rectangular" height={60} />
              ) : (
                <>
                  <Typography color="textSecondary" gutterBottom>
                    Managed Devices
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600, color: 'primary.main' }}>
                    {filteredDevices.filter(d => d.is_managed).length}
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              {isLoading ? (
                <Skeleton variant="rectangular" height={60} />
              ) : (
                <>
                  <Typography color="textSecondary" gutterBottom>
                    Compliant
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600, color: 'success.main' }}>
                    {filteredDevices.filter(d => d.compliance_state === 'compliant').length}
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              {isLoading ? (
                <Skeleton variant="rectangular" height={60} />
              ) : (
                <>
                  <Typography color="textSecondary" gutterBottom>
                    Non-Compliant
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600, color: 'error.main' }}>
                    {filteredDevices.filter(d => d.compliance_state === 'noncompliant').length}
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Device</TableCell>
              <TableCell>Model</TableCell>
              <TableCell>Serial Number</TableCell>
              <TableCell>IMEI</TableCell>
              <TableCell>User</TableCell>
              <TableCell>Compliance</TableCell>
              <TableCell>Managed</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={index}>
                  {Array.from({ length: 7 }).map((_, cellIndex) => (
                    <TableCell key={cellIndex}>
                      <Skeleton variant="text" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              filteredDevices.map((device) => (
              <TableRow key={device.id}>
                <TableCell>
                  <Box display="flex" alignItems="center">
                    {getDeviceIcon(device.model)}
                    <Box ml={1}>
                      <Typography variant="body2" fontWeight="medium">
                        {device.device_name}
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        {device.manufacturer}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>{device.model}</TableCell>
                <TableCell>{device.serial_number}</TableCell>
                <TableCell>{device.imei}</TableCell>
                <TableCell>{device.users?.display_name || 'Unassigned'}</TableCell>
                <TableCell>
                  <Chip
                    label={device.compliance_state}
                    color={getComplianceColor(device.compliance_state)}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={device.is_managed ? 'Yes' : 'No'}
                    color={device.is_managed ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
              </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};