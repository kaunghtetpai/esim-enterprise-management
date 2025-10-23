import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, IconButton, Dialog, DialogTitle,
  DialogContent, TextField, DialogActions, Grid, Card, CardContent
} from '@mui/material';
import { Add, Edit, Delete, Refresh } from '@mui/icons-material';
import apiService from '../services/api';

export const ProfilesPage: React.FC = () => {
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedProfile, setSelectedProfile] = useState(null);

  useEffect(() => {
    loadProfiles();
  }, []);

  const loadProfiles = async () => {
    try {
      setLoading(true);
      const data = await apiService.getProfiles();
      setProfiles(data.profiles || []);
    } catch (error) {
      console.error('Failed to load profiles:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateProfile = () => {
    setSelectedProfile(null);
    setDialogOpen(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'success';
      case 'inactive': return 'default';
      case 'suspended': return 'warning';
      case 'expired': return 'error';
      default: return 'default';
    }
  };

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          eSIM Profiles Management
        </Typography>
        <Box>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadProfiles}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleCreateProfile}
          >
            Create Profile
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Profiles
              </Typography>
              <Typography variant="h4">
                {profiles.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Active Profiles
              </Typography>
              <Typography variant="h4">
                {profiles.filter(p => p.status === 'active').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Profile Name</TableCell>
              <TableCell>ICCID</TableCell>
              <TableCell>Carrier</TableCell>
              <TableCell>Plan</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Data Allowance</TableCell>
              <TableCell>Monthly Cost</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {profiles.map((profile) => (
              <TableRow key={profile.id}>
                <TableCell>{profile.profile_name}</TableCell>
                <TableCell>{profile.iccid}</TableCell>
                <TableCell>{profile.carrier}</TableCell>
                <TableCell>{profile.plan_name}</TableCell>
                <TableCell>
                  <Chip
                    label={profile.status}
                    color={getStatusColor(profile.status)}
                    size="small"
                  />
                </TableCell>
                <TableCell>{profile.data_allowance_mb} MB</TableCell>
                <TableCell>${profile.monthly_cost}</TableCell>
                <TableCell>
                  <IconButton size="small" onClick={() => {}}>
                    <Edit />
                  </IconButton>
                  <IconButton size="small" onClick={() => {}}>
                    <Delete />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};