import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, IconButton, Grid, Card, CardContent
} from '@mui/material';
import { Add, Refresh, PhoneAndroid, Computer, Tablet } from '@mui/icons-material';

export const DevicesPage: React.FC = () => {
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDevices();
  }, []);

  const loadDevices = async () => {
    try {
      setLoading(true);
      // Mock data for now
      setDevices([
        {
          id: '1',
          device_name: 'iPhone 14 Pro',
          model: 'iPhone14,3',
          manufacturer: 'Apple',
          serial_number: 'F2LLD2XHMD',
          imei: '123456789012345',
          compliance_state: 'compliant',
          is_managed: true,
          user_name: 'John Doe'
        },
        {
          id: '2',
          device_name: 'Samsung Galaxy S23',
          model: 'SM-S911B',
          manufacturer: 'Samsung',
          serial_number: 'R58RB1ABCDE',
          imei: '987654321098765',
          compliance_state: 'noncompliant',
          is_managed: true,
          user_name: 'Jane Smith'
        }
      ]);
    } catch (error) {
      console.error('Failed to load devices:', error);
    } finally {
      setLoading(false);
    }
  };

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
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Device Management
        </Typography>
        <Box>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadDevices}
            sx={{ mr: 1 }}
          >
            Sync from Intune
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
          >
            Register Device
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Devices
              </Typography>
              <Typography variant="h4">
                {devices.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Managed Devices
              </Typography>
              <Typography variant="h4">
                {devices.filter(d => d.is_managed).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Compliant
              </Typography>
              <Typography variant="h4">
                {devices.filter(d => d.compliance_state === 'compliant').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Non-Compliant
              </Typography>
              <Typography variant="h4">
                {devices.filter(d => d.compliance_state === 'noncompliant').length}
              </Typography>
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
            {devices.map((device) => (
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
                <TableCell>{device.user_name}</TableCell>
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
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};