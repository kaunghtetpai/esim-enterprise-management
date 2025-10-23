import React, { useState, useEffect } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  Refresh,
  Add,
  Download,
  Upload,
  Settings,
  Notifications,
  DeviceHub,
  SimCard,
  People
} from '@mui/icons-material';

interface DashboardStats {
  totalProfiles: number;
  activeProfiles: number;
  totalDevices: number;
  managedDevices: number;
  totalUsers: number;
  departments: number;
  pendingActivations: number;
  failedActivations: number;
  monthlyUsage: {
    carrier: string;
    usage: number;
    cost: number;
  }[];
  recentActivities: {
    id: string;
    action: string;
    user: string;
    timestamp: string;
    status: string;
  }[];
}

export const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [bulkDialog, setBulkDialog] = useState({ open: false, type: null });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/v1/dashboard/stats');
      const data = await response.json();
      setStats(data);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleBulkAction = (type: string) => {
    setBulkDialog({ open: true, type });
  };

  const processBulkAction = async () => {
    if (!selectedFile || !bulkDialog.type) return;

    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('action', bulkDialog.type);

    try {
      const response = await fetch('/api/v1/esim/bulk-action', {
        method: 'POST',
        body: formData
      });
      
      if (response.ok) {
        setBulkDialog({ open: false, type: null });
        setSelectedFile(null);
        loadDashboardData();
      }
    } catch (error) {
      console.error('Bulk action failed:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success': return 'success';
      case 'failed': return 'error';
      case 'pending': return 'warning';
      default: return 'default';
    }
  };

  if (loading) {
    return <Box p={3}>Loading dashboard...</Box>;
  }

  return (
    <Box p={3}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          eSIM Business Manager - Admin Dashboard
        </Typography>
        <Box>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadDashboardData}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => handleBulkAction('activation')}
          >
            Bulk Actions
          </Button>
        </Box>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <SimCard color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Total eSIM Profiles
                  </Typography>
                  <Typography variant="h5">
                    {stats?.totalProfiles || 0}
                  </Typography>
                  <Typography variant="body2" color="success.main">
                    {stats?.activeProfiles || 0} Active
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <DeviceHub color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Total Devices
                  </Typography>
                  <Typography variant="h5">
                    {stats?.totalDevices || 0}
                  </Typography>
                  <Typography variant="body2" color="success.main">
                    {stats?.managedDevices || 0} Managed
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <People color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Total Users
                  </Typography>
                  <Typography variant="h5">
                    {stats?.totalUsers || 0}
                  </Typography>
                  <Typography variant="body2" color="info.main">
                    {stats?.departments || 0} Departments
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Notifications color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Pending Activations
                  </Typography>
                  <Typography variant="h5">
                    {stats?.pendingActivations || 0}
                  </Typography>
                  <Typography variant="body2" color="error.main">
                    {stats?.failedActivations || 0} Failed
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Quick Actions */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Quick Actions
              </Typography>
              <Box display="flex" flexWrap="wrap" gap={1}>
                <Button
                  variant="outlined"
                  startIcon={<Add />}
                  onClick={() => handleBulkAction('activation')}
                >
                  Bulk Activation
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Upload />}
                  onClick={() => handleBulkAction('migration')}
                >
                  Bulk Migration
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Download />}
                  onClick={() => window.open('/api/v1/reports/export')}
                >
                  Export Report
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<Settings />}
                  onClick={() => window.location.href = '/settings'}
                >
                  Settings
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Monthly Usage by Carrier
              </Typography>
              {stats?.monthlyUsage?.map((usage, index) => (
                <Box key={index} display="flex" justifyContent="space-between" mb={1}>
                  <Typography variant="body2">{usage.carrier}</Typography>
                  <Box>
                    <Typography variant="body2" component="span">
                      {usage.usage}MB
                    </Typography>
                    <Typography variant="body2" color="textSecondary" component="span" ml={1}>
                      ${usage.cost}
                    </Typography>
                  </Box>
                </Box>
              ))}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Activities */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Recent Activities
          </Typography>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Action</TableCell>
                  <TableCell>User</TableCell>
                  <TableCell>Timestamp</TableCell>
                  <TableCell>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {stats?.recentActivities?.map((activity) => (
                  <TableRow key={activity.id}>
                    <TableCell>{activity.action}</TableCell>
                    <TableCell>{activity.user}</TableCell>
                    <TableCell>
                      {new Date(activity.timestamp).toLocaleString()}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={activity.status}
                        color={getStatusColor(activity.status) as any}
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

      {/* Bulk Action Dialog */}
      <Dialog open={bulkDialog.open} onClose={() => setBulkDialog({ open: false, type: null })}>
        <DialogTitle>
          Bulk {bulkDialog.type}
        </DialogTitle>
        <DialogContent>
          <Box mt={2}>
            <input
              type="file"
              accept=".csv,.xlsx"
              onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
              style={{ marginBottom: 16 }}
            />
            <Typography variant="body2" color="textSecondary">
              Upload CSV or Excel file with device and profile information
            </Typography>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBulkDialog({ open: false, type: null })}>
            Cancel
          </Button>
          <Button
            onClick={processBulkAction}
            variant="contained"
            disabled={!selectedFile}
          >
            Process
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};