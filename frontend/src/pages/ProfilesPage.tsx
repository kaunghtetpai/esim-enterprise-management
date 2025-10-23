import React, { useState } from 'react';
import {
  Box, Typography, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, IconButton, Dialog, DialogTitle,
  DialogContent, TextField, DialogActions, Grid, Card, CardContent,
  Skeleton, Alert, useMediaQuery, useTheme
} from '@mui/material';
import { Add, Edit, Delete, Refresh, FilterList } from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';

export const ProfilesPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedProfile, setSelectedProfile] = useState(null);
  const [filter, setFilter] = useState('');

  const { data: profiles = [], isLoading, error, refetch } = useQuery({
    queryKey: ['profiles'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('esim_profiles')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return data;
    }
  });

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
      <Box 
        display="flex" 
        flexDirection={{ xs: 'column', md: 'row' }}
        justifyContent="space-between" 
        alignItems={{ xs: 'stretch', md: 'center' }}
        mb={3}
        gap={2}
      >
        <Typography variant="h4" component="h1" sx={{ fontWeight: 600 }}>
          eSIM Profiles Management
        </Typography>
        <Box display="flex" gap={1} flexDirection={{ xs: 'column', sm: 'row' }}>
          <Button
            variant="outlined"
            startIcon={<FilterList />}
            size={isMobile ? 'small' : 'medium'}
          >
            Filter
          </Button>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={() => refetch()}
            disabled={isLoading}
            size={isMobile ? 'small' : 'medium'}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleCreateProfile}
            size={isMobile ? 'small' : 'medium'}
          >
            Create Profile
          </Button>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Failed to load profiles. Please try again.
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
                    Total Profiles
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {profiles.length}
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
                    Active Profiles
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600, color: 'success.main' }}>
                    {profiles.filter(p => p.status === 'active').length}
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
                    Monthly Cost
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    ${profiles.reduce((sum, p) => sum + (p.monthly_cost || 0), 0).toFixed(2)}
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
                    Data Allowance
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {(profiles.reduce((sum, p) => sum + (p.data_allowance_mb || 0), 0) / 1024).toFixed(1)}GB
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <TableContainer component={Paper} sx={{ overflowX: 'auto' }}>
        <Table size={isMobile ? 'small' : 'medium'}>
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
            {isLoading ? (
              Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={index}>
                  {Array.from({ length: 8 }).map((_, cellIndex) => (
                    <TableCell key={cellIndex}>
                      <Skeleton variant="text" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              profiles.map((profile) => (
                <TableRow key={profile.id} hover>
                  <TableCell>
                    <Typography variant="body2" fontWeight="medium">
                      {profile.profile_name}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontFamily="monospace">
                      {profile.iccid}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={profile.carrier}
                      variant="outlined"
                      size="small"
                    />
                  </TableCell>
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
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};