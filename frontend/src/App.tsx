import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline, Box, AppBar, Toolbar, Typography, Button } from '@mui/material';
import SIMListPage from './pages/SIMListPage';
import GSMACertificatesPage from './pages/GSMACertificatesPage';

const theme = createTheme({
  palette: {
    primary: { main: '#1976d2' },
    secondary: { main: '#dc004e' }
  }
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <AppBar position="static">
          <Toolbar>
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              EPM Portal - eSIM Enterprise Management
            </Typography>
          </Toolbar>
        </AppBar>

        <Box sx={{ p: 3 }}>
          <Routes>
            <Route path="/" element={<SIMListPage />} />
            <Route path="/sim-list" element={<SIMListPage />} />
            <Route path="/gsma-certificates" element={<GSMACertificatesPage />} />
            <Route path="*" element={
              <Box sx={{ textAlign: 'center', mt: 4 }}>
                <Typography variant="h5" gutterBottom>EPM Portal</Typography>
                <Typography variant="body1">eSIM Enterprise Management System</Typography>
              </Box>
            } />
          </Routes>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;