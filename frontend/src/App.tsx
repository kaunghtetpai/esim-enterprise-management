import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { store } from './store/store';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import ProfileManagement from './pages/ProfileManagement';
import ActivationCodeManagement from './pages/ActivationCodeManagement';
import DeviceManagement from './pages/DeviceManagement';
import CampaignManagement from './pages/CampaignManagement';
import Login from './pages/Login';

const theme = createTheme({
  palette: {
    primary: { main: '#1976d2' },
    secondary: { main: '#dc004e' },
  },
});

const App: React.FC = () => {
  return (
    <Provider store={store}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/" element={<Layout />}>
              <Route index element={<Dashboard />} />
              <Route path="profiles" element={<ProfileManagement />} />
              <Route path="activation-codes" element={<ActivationCodeManagement />} />
              <Route path="devices" element={<DeviceManagement />} />
              <Route path="campaigns" element={<CampaignManagement />} />
            </Route>
          </Routes>
        </Router>
      </ThemeProvider>
    </Provider>
  );
};

export default App;