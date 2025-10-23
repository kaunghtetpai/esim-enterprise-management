import React, { useState, useEffect } from 'react';
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
  Chip,
  TextField,
  InputAdornment
} from '@mui/material';
import { Search, Add, Download } from '@mui/icons-material';

interface SIMCard {
  id: string;
  iccid: string;
  lpa: string;
  carrier: string;
  status: string;
  activationDate?: string;
}

const SIMCardsPage: React.FC = () => {
  const [simCards, setSimCards] = useState<SIMCard[]>([]);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    // Sample data with provided LPA codes
    const sampleData: SIMCard[] = [
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
      },
      {
        id: '3',
        iccid: '89950182421200141347',
        lpa: 'LPA:1$mptmyanmar.china-xinghan.com$QFYB2-4F81A-FB586-HPNFN',
        carrier: 'MPT',
        status: 'Pending'
      },
      {
        id: '4',
        iccid: '89950182421199980671',
        lpa: 'LPA:1$mptmyanmar.china-xinghan.com$X9QB2-4F81A-FB543-MK9J9',
        carrier: 'MPT',
        status: 'Active'
      },
      {
        id: '5',
        iccid: '89950182421199980655',
        lpa: 'LPA:1$mptmyanmar.china-xinghan.com$X9QB2-4F81A-FB541-9SYNY',
        carrier: 'MPT',
        status: 'Active'
      }
    ];
    setSimCards(sampleData);
  }, []);

  const filteredCards = simCards.filter(card =>
    card.iccid.includes(searchTerm) ||
    card.lpa.includes(searchTerm) ||
    card.carrier.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'success';
      case 'Pending': return 'warning';
      case 'Inactive': return 'error';
      default: return 'default';
    }
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">List of SIM Cards</Typography>
        <Box>
          <Button variant="outlined" startIcon={<Download />} sx={{ mr: 1 }}>
            Export
          </Button>
          <Button variant="contained" startIcon={<Add />}>
            Add SIM Card
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6">Total SIM Cards</Typography>
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
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6">Pending</Typography>
              <Typography variant="h4" color="warning.main">
                {simCards.filter(s => s.status === 'Pending').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6">MPT Carrier</Typography>
              <Typography variant="h4" color="info.main">
                {simCards.filter(s => s.carrier === 'MPT').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card>
        <CardContent>
          <Box mb={2}>
            <TextField
              fullWidth
              placeholder="Search by ICCID, LPA, or Carrier"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
            />
          </Box>

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
                {filteredCards.map((card) => (
                  <TableRow key={card.id}>
                    <TableCell>{card.iccid}</TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
                        {card.lpa}
                      </Typography>
                    </TableCell>
                    <TableCell>{card.carrier}</TableCell>
                    <TableCell>
                      <Chip
                        label={card.status}
                        color={getStatusColor(card.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Button size="small" variant="outlined">
                        View Details
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

export default SIMCardsPage;