import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Link
} from '@mui/material';
import { Security, CheckCircle, Schedule } from '@mui/icons-material';

const GSMACertificatesPage: React.FC = () => {
  const certificates = [
    {
      id: '1',
      name: 'GSM Association - RSP2 Root CI1',
      ca: 'DigiCert',
      specs: 'SGP.21 and SGP.22 version 2 and version 3',
      keyId: '81370f5125d0b1d408d4c3b232e6d25e795bebfb',
      expiry: '2/21/2052',
      crl: 'http://gsma-crl.symauth.com/offlineca/gsma-rsp2-root-ci1.crl',
      status: 'Active'
    },
    {
      id: '2',
      name: 'GSM Association - M2M31 Root CI2',
      ca: 'Cybertrust',
      specs: 'SGP.01 and SGP.02',
      keyId: 'd7a7d0c7c04ea76076e3f44faebde8779e2948d4',
      expiry: '3/15/2052',
      crl: null,
      status: 'Active'
    },
    {
      id: '3',
      name: 'OISITE GSMA CI G1',
      ca: 'WISeKey',
      specs: 'SGP.21 and SGP.22 version 2 and version 3',
      keyId: '4c27967ad20c14b391e9601e41e604ad57c0222f',
      expiry: '1/7/2059',
      crl: 'http://public.wisekey.com/crl/ogsmacig1.crl',
      status: 'Active'
    }
  ];

  return (
    <Box>
      <Box display="flex" alignItems="center" mb={3}>
        <Security sx={{ mr: 2, fontSize: 32, color: 'primary.main' }} />
        <Typography variant="h4">GSMA Live Certificate Issuers</Typography>
      </Box>

      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">Total Certificates</Typography>
              <Typography variant="h4" color="primary">{certificates.length}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">Active CIs</Typography>
              <Typography variant="h4" color="success.main">
                {certificates.filter(c => c.status === 'Active').length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">SGP.22 Compliant</Typography>
              <Typography variant="h4" color="info.main">
                {certificates.filter(c => c.specs.includes('SGP.22')).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Certificate Authority Details
          </Typography>
          
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Certificate Name</TableCell>
                  <TableCell>CA Provider</TableCell>
                  <TableCell>Specifications</TableCell>
                  <TableCell>Key ID</TableCell>
                  <TableCell>Expiry Date</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>CRL</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {certificates.map((cert) => (
                  <TableRow key={cert.id}>
                    <TableCell>
                      <Box display="flex" alignItems="center">
                        <Security sx={{ mr: 1, color: 'primary.main' }} />
                        <Typography variant="body2" fontWeight="medium">
                          {cert.name}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>{cert.ca}</TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                        {cert.specs}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                        {cert.keyId}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box display="flex" alignItems="center">
                        <Schedule sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                        <Typography variant="body2">
                          {cert.expiry}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        icon={<CheckCircle />}
                        label={cert.status}
                        color="success"
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {cert.crl ? (
                        <Link 
                          href={cert.crl} 
                          target="_blank" 
                          rel="noopener noreferrer"
                          sx={{ fontSize: '0.8rem' }}
                        >
                          View CRL
                        </Link>
                      ) : (
                        <Typography variant="body2" color="text.secondary">
                          N/A
                        </Typography>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            GSMA Compliance Information
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Typography variant="body2" paragraph>
                <strong>SGP.21:</strong> Remote SIM Provisioning Architecture for Embedded UICC
              </Typography>
              <Typography variant="body2" paragraph>
                <strong>SGP.22:</strong> Remote SIM Provisioning for Consumer Devices
              </Typography>
            </Grid>
            <Grid item xs={12} md={6}>
              <Typography variant="body2" paragraph>
                <strong>SGP.01:</strong> Embedded SIM Remote Provisioning Architecture
              </Typography>
              <Typography variant="body2" paragraph>
                <strong>SGP.02:</strong> Remote Provisioning Architecture for Embedded UICC Technical Specification
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
};

export default GSMACertificatesPage;