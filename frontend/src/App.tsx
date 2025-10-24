import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline } from '@mui/material';
import { HelmetProvider } from 'react-helmet-async';
import ResponsiveLayout from './components/ResponsiveLayout';
import SEOHead from './components/SEOHead';
import SIMListPage from './pages/SIMListPage';
import GSMACertificatesPage from './pages/GSMACertificatesPage';
import AccessibleForm from './components/AccessibleForm';

const theme = createTheme({
  palette: {
    primary: { 
      main: '#1976d2',
      contrastText: '#ffffff'
    },
    secondary: { 
      main: '#dc004e',
      contrastText: '#ffffff'
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff'
    },
    text: {
      primary: '#212121',
      secondary: '#757575'
    }
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h1: { 
      fontSize: '2.5rem', 
      fontWeight: 600, 
      lineHeight: 1.3,
      letterSpacing: '-0.01562em'
    },
    h2: { 
      fontSize: '2rem', 
      fontWeight: 600, 
      lineHeight: 1.3,
      letterSpacing: '-0.00833em'
    },
    h3: { 
      fontSize: '1.75rem', 
      fontWeight: 600, 
      lineHeight: 1.3 
    },
    h4: { 
      fontSize: '1.5rem', 
      fontWeight: 600, 
      lineHeight: 1.3 
    },
    h5: { 
      fontSize: '1.25rem', 
      fontWeight: 600, 
      lineHeight: 1.3 
    },
    h6: { 
      fontSize: '1rem', 
      fontWeight: 600, 
      lineHeight: 1.3 
    },
    body1: { 
      fontSize: '1rem', 
      lineHeight: 1.6,
      letterSpacing: '0.00938em'
    },
    body2: { 
      fontSize: '0.875rem', 
      lineHeight: 1.6,
      letterSpacing: '0.01071em'
    }
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          minHeight: 44,
          textTransform: 'none',
          fontWeight: 500,
          borderRadius: 8,
          '&:focus-visible': {
            outline: '2px solid',
            outlineColor: 'primary.main',
            outlineOffset: 2
          }
        }
      }
    },
    MuiCard: {
      styleOverrides: {
        root: {
          padding: 24,
          borderRadius: 12,
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }
      }
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiInputBase-root': {
            minHeight: 44
          },
          '& .MuiInputBase-input:focus': {
            outline: 'none'
          },
          '& .MuiOutlinedInput-root.Mui-focused .MuiOutlinedInput-notchedOutline': {
            borderWidth: 2
          }
        }
      }
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          padding: '16px',
          borderBottom: '1px solid rgba(224, 224, 224, 1)'
        },
        head: {
          fontWeight: 600,
          backgroundColor: '#f5f5f5'
        }
      }
    }
  },
  breakpoints: {
    values: {
      xs: 0,
      sm: 600,
      md: 900,
      lg: 1200,
      xl: 1536
    }
  }
});

function App() {
  return (
    <HelmetProvider>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <SEOHead />
          <ResponsiveLayout>
            <Routes>
              <Route 
                path="/" 
                element={
                  <>
                    <SEOHead 
                      title="EPM Portal - Dashboard | eSIM Enterprise Management"
                      description="Enterprise eSIM management dashboard with real-time monitoring, device management, and carrier integration for Myanmar operators."
                    />
                    <SIMListPage />
                  </>
                } 
              />
              <Route 
                path="/sim-list" 
                element={
                  <>
                    <SEOHead 
                      title="SIM Card Management | EPM Portal"
                      description="Manage eSIM cards with LPA codes, carrier assignments, and device provisioning for enterprise users."
                      canonical="https://epm-portal.vercel.app/sim-list"
                    />
                    <SIMListPage />
                  </>
                } 
              />
              <Route 
                path="/gsma-certificates" 
                element={
                  <>
                    <SEOHead 
                      title="GSMA Certificate Issuers | EPM Portal"
                      description="Monitor GSMA live certificate issuers, SGP.21/SGP.22 compliance, and certificate authority status for eSIM security."
                      canonical="https://epm-portal.vercel.app/gsma-certificates"
                    />
                    <GSMACertificatesPage />
                  </>
                } 
              />
              <Route 
                path="/register" 
                element={
                  <>
                    <SEOHead 
                      title="Register SIM Card | EPM Portal"
                      description="Register new eSIM cards with carrier assignment, user provisioning, and enterprise compliance."
                      canonical="https://epm-portal.vercel.app/register"
                    />
                    <AccessibleForm />
                  </>
                } 
              />
              <Route 
                path="*" 
                element={
                  <>
                    <SEOHead 
                      title="Page Not Found | EPM Portal"
                      description="The requested page could not be found. Return to the EPM Portal dashboard."
                    />
                    <div style={{ textAlign: 'center', padding: '48px' }}>
                      <h1>404 - Page Not Found</h1>
                      <p>The requested page could not be found.</p>
                    </div>
                  </>
                } 
              />
            </Routes>
          </ResponsiveLayout>
        </Router>
      </ThemeProvider>
    </HelmetProvider>
  );
}

export default App;