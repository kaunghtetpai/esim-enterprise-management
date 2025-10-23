import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  Chip,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper
} from '@mui/material';
import { NetworkCheck, Speed, TrendingUp, CellTower } from '@mui/icons-material';

const CarriersPage: React.FC = () => {
  const carriers = [
    {
      code: 'MPT',
      name: 'Myanmar Posts and Telecommunications',
      mcc: '414',
      mnc: '01',
      status: 'Active',
      coverage: 95,
      profiles: 1250,
      activeUsers: 890,
      dataUsage: '2.5TB',
      color: '#1976d2'
    },
    {
      code: 'ATOM',
      name: 'Atom Myanmar',
      mcc: '414',
      mnc: '06',
      status: 'Active',
      coverage: 88,
      profiles: 850,
      activeUsers: 620,
      dataUsage: '1.8TB',
      color: '#388e3c'
    },
    {
      code: 'U9',
      name: 'U9 Networks',
      mcc: '414',
      mnc: '07',
      status: 'Active',
      coverage: 82,
      profiles: 650,
      activeUsers: 480,
      dataUsage: '1.2TB',
      color: '#f57c00'
    },
    {
      code: 'MYTEL',
      name: 'MyTel Myanmar',
      mcc: '414',
      mnc: '09',
      status: 'Active',
      coverage: 90,
      profiles: 980,
      activeUsers: 720,
      dataUsage: '2.1TB',
      color: '#7b1fa2'
    }
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Myanmar Carriers - ATOM U9 MYTEL MPT
      </Typography>

      <Grid container spacing={3} mb={4}>
        {carriers.map((carrier) => (
          <Grid item xs={12} sm={6} md={3} key={carrier.code}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <CellTower sx={{ color: carrier.color, mr: 1 }} />
                  <Typography variant="h6">{carrier.code}</Typography>
                </Box>
                
                <Typography variant="body2" color="textSecondary" gutterBottom>
                  {carrier.name}
                </Typography>
                
                <Box mb={2}>
                  <Chip 
                    label={carrier.status} 
                    color="success" 
                    size="small" 
                    sx={{ mb: 1 }}
                  />
                  <Typography variant="caption" display="block">
                    MCC: {carrier.mcc} | MNC: {carrier.mnc}
                  </Typography>
                </Box>

                <Box mb={2}>
                  <Typography variant="body2" gutterBottom>
                    Coverage: {carrier.coverage}%
                  </Typography>
                  <LinearProgress 
                    variant="determinate" 
                    value={carrier.coverage} 
                    sx={{ height: 8, borderRadius: 4 }}
                  />
                </Box>

                <Grid container spacing={1}>
                  <Grid item xs={6}>
                    <Typography variant="caption" color="textSecondary">
                      Profiles
                    </Typography>
                    <Typography variant="h6">
                      {carrier.profiles.toLocaleString()}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="caption" color="textSecondary">
                      Active Users
                    </Typography>
                    <Typography variant="h6">
                      {carrier.activeUsers.toLocaleString()}
                    </Typography>
                  </Grid>
                </Grid>

                <Button 
                  fullWidth 
                  variant="outlined" 
                  sx={{ mt: 2 }}
                  startIcon={<NetworkCheck />}
                >
                  Manage
                </Button>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Carrier Performance Metrics
          </Typography>
          
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Carrier</TableCell>
                  <TableCell>Network Coverage</TableCell>
                  <TableCell>Total Profiles</TableCell>
                  <TableCell>Active Users</TableCell>
                  <TableCell>Data Usage</TableCell>
                  <TableCell>Performance</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {carriers.map((carrier) => (
                  <TableRow key={carrier.code}>
                    <TableCell>
                      <Box display="flex" alignItems="center">
                        <CellTower sx={{ color: carrier.color, mr: 1 }} />
                        <Box>
                          <Typography variant="body2" fontWeight="bold">
                            {carrier.code}
                          </Typography>
                          <Typography variant="caption" color="textSecondary">
                            {carrier.mcc}-{carrier.mnc}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box>
                        <Typography variant="body2">
                          {carrier.coverage}%
                        </Typography>
                        <LinearProgress 
                          variant="determinate" 
                          value={carrier.coverage} 
                          sx={{ height: 4, width: 80 }}
                        />
                      </Box>
                    </TableCell>
                    <TableCell>{carrier.profiles.toLocaleString()}</TableCell>
                    <TableCell>{carrier.activeUsers.toLocaleString()}</TableCell>
                    <TableCell>{carrier.dataUsage}</TableCell>
                    <TableCell>
                      <Chip 
                        icon={<TrendingUp />}
                        label="Excellent" 
                        color="success" 
                        size="small" 
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CarriersPage;