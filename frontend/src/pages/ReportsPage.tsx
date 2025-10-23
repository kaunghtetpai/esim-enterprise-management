import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Button, Grid, Card, CardContent, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Paper, Select, MenuItem,
  FormControl, InputLabel
} from '@mui/material';
import { Download, Refresh, Assessment } from '@mui/icons-material';

export const ReportsPage: React.FC = () => {
  const [usageData, setUsageData] = useState([]);
  const [complianceData, setComplianceData] = useState([]);
  const [reportType, setReportType] = useState('usage');

  useEffect(() => {
    loadReports();
  }, []);

  const loadReports = async () => {
    // Mock data for demonstration
    setUsageData([
      { carrier: 'MPT', total_profiles: 45, active_profiles: 38, total_data_mb: 15000, total_cost: 450.50 },
      { carrier: 'ATOM', total_profiles: 32, active_profiles: 28, total_data_mb: 12000, total_cost: 380.20 },
      { carrier: 'U9', total_profiles: 28, active_profiles: 22, total_data_mb: 8000, total_cost: 250.10 },
      { carrier: 'MYTEL', total_profiles: 35, active_profiles: 30, total_data_mb: 9500, total_cost: 307.75 }
    ]);

    setComplianceData([
      { compliance_state: 'compliant', device_count: 156, percentage: 78.0 },
      { compliance_state: 'noncompliant', device_count: 32, percentage: 16.0 },
      { compliance_state: 'unknown', device_count: 12, percentage: 6.0 }
    ]);
  };

  const exportReport = () => {
    const data = reportType === 'usage' ? usageData : complianceData;
    const csv = convertToCSV(data);
    downloadCSV(csv, `${reportType}_report.csv`);
  };

  const convertToCSV = (data: any[]) => {
    if (data.length === 0) return '';
    const headers = Object.keys(data[0]).join(',');
    const rows = data.map(row => Object.values(row).join(','));
    return [headers, ...rows].join('\n');
  };

  const downloadCSV = (csv: string, filename: string) => {
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Reports & Analytics
        </Typography>
        <Box>
          <FormControl sx={{ mr: 2, minWidth: 120 }}>
            <InputLabel>Report Type</InputLabel>
            <Select
              value={reportType}
              onChange={(e) => setReportType(e.target.value)}
              label="Report Type"
            >
              <MenuItem value="usage">Usage Report</MenuItem>
              <MenuItem value="compliance">Compliance Report</MenuItem>
            </Select>
          </FormControl>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadReports}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Download />}
            onClick={exportReport}
          >
            Export CSV
          </Button>
        </Box>
      </Box>

      {reportType === 'usage' && (
        <>
          <Grid container spacing={3} mb={3}>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Box display="flex" alignItems="center">
                    <Assessment color="primary" sx={{ mr: 2 }} />
                    <Box>
                      <Typography color="textSecondary" gutterBottom>
                        Total Profiles
                      </Typography>
                      <Typography variant="h4">
                        {usageData.reduce((sum, item) => sum + item.total_profiles, 0)}
                      </Typography>
                    </Box>
                  </Box>
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
                    {usageData.reduce((sum, item) => sum + item.active_profiles, 0)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Total Data (GB)
                  </Typography>
                  <Typography variant="h4">
                    {(usageData.reduce((sum, item) => sum + item.total_data_mb, 0) / 1024).toFixed(1)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="textSecondary" gutterBottom>
                    Monthly Cost
                  </Typography>
                  <Typography variant="h4">
                    ${usageData.reduce((sum, item) => sum + item.total_cost, 0).toFixed(2)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Carrier</TableCell>
                  <TableCell>Total Profiles</TableCell>
                  <TableCell>Active Profiles</TableCell>
                  <TableCell>Data Usage (MB)</TableCell>
                  <TableCell>Monthly Cost</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {usageData.map((row) => (
                  <TableRow key={row.carrier}>
                    <TableCell>{row.carrier}</TableCell>
                    <TableCell>{row.total_profiles}</TableCell>
                    <TableCell>{row.active_profiles}</TableCell>
                    <TableCell>{row.total_data_mb.toLocaleString()}</TableCell>
                    <TableCell>${row.total_cost}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </>
      )}

      {reportType === 'compliance' && (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Compliance State</TableCell>
                <TableCell>Device Count</TableCell>
                <TableCell>Percentage</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {complianceData.map((row) => (
                <TableRow key={row.compliance_state}>
                  <TableCell>{row.compliance_state}</TableCell>
                  <TableCell>{row.device_count}</TableCell>
                  <TableCell>{row.percentage}%</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
};