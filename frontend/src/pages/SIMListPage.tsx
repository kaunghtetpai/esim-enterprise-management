import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip
} from '@mui/material';
import { Add, Download } from '@mui/icons-material';

const SIMListPage: React.FC = () => {
  const simCards = [
    {
      id: '1',
      iccid: '89950182421199985068',
      lpa: 'LPA:1$mptmyanmar.china-xinghan.com$X9QB2-4F81A-FB51F-ALLLL',
      carrier: 'MPT',
      status: 'Active'
    },
    {
      id: '2',
      iccid: '89950182421199980648',
      lpa: 'LPA:1$mptmyanmar.china-xinghan.com$X9QB2-4F81A-FB540-D32H2',
      carrier: 'MPT',
      status: 'Active'
    }
  ];

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">SIM Card List</Typography>
        <Box>
          <Button variant="outlined" startIcon={<Download />} sx={{ mr: 1 }}>
            Export
          </Button>
          <Button variant="contained" startIcon={<Add />}>
            Add SIM
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6">Total SIMs</Typography>
              <Typography variant="h4" color="primary">{simCards.length}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6">Active</Typography>
              <Typography variant="h4" color="success.main">
                {simCards.filter(s => s.status === 'Active').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card>
        <CardContent>
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>ICCID</TableCell>
                  <TableCell>LPA Code</TableCell>
                  <TableCell>Carrier</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {simCards.map((card) => (
                  <TableRow key={card.id}>
                    <TableCell>{card.iccid}</TableCell>
                    <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
                      {card.lpa}
                    </TableCell>
                    <TableCell>{card.carrier}</TableCell>
                    <TableCell>
                      <Chip label={card.status} color="success" size="small" />
                    </TableCell>
                    <TableCell>
                      <Button size="small" variant="outlined">
                        View
                      </Button>
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

export default SIMListPage;