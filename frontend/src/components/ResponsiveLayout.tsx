import React, { useState } from 'react';
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  useTheme,
  useMediaQuery,
  Breadcrumbs,
  Link,
  Container
} from '@mui/material';
import {
  Menu as MenuIcon,
  Home,
  SimCard,
  Security,
  Dashboard,
  Settings,
  NavigateNext
} from '@mui/icons-material';
import { useLocation, Link as RouterLink } from 'react-router-dom';

interface ResponsiveLayoutProps {
  children: React.ReactNode;
}

const ResponsiveLayout: React.FC<ResponsiveLayoutProps> = ({ children }) => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const location = useLocation();

  const menuItems = [
    { text: 'Dashboard', icon: <Dashboard />, path: '/' },
    { text: 'SIM Cards', icon: <SimCard />, path: '/sim-list' },
    { text: 'GSMA Certificates', icon: <Security />, path: '/gsma-certificates' },
    { text: 'Settings', icon: <Settings />, path: '/settings' }
  ];

  const getBreadcrumbs = () => {
    const pathnames = location.pathname.split('/').filter(x => x);
    const breadcrumbs = [
      <Link 
        key="home" 
        component={RouterLink} 
        to="/" 
        color="inherit" 
        underline="hover"
        aria-label="Navigate to home page"
      >
        <Home sx={{ mr: 0.5 }} fontSize="inherit" />
        Home
      </Link>
    ];

    pathnames.forEach((name, index) => {
      const routeTo = `/${pathnames.slice(0, index + 1).join('/')}`;
      const isLast = index === pathnames.length - 1;
      
      const displayName = name
        .split('-')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');

      if (isLast) {
        breadcrumbs.push(
          <Typography key={name} color="text.primary">
            {displayName}
          </Typography>
        );
      } else {
        breadcrumbs.push(
          <Link
            key={name}
            component={RouterLink}
            to={routeTo}
            color="inherit"
            underline="hover"
          >
            {displayName}
          </Link>
        );
      }
    });

    return breadcrumbs;
  };

  const drawer = (
    <Box sx={{ width: 250 }} role="navigation" aria-label="Main navigation">
      <Toolbar>
        <Typography variant="h6" noWrap component="div">
          EPM Portal
        </Typography>
      </Toolbar>
      <List>
        {menuItems.map((item) => (
          <ListItem
            key={item.text}
            component={RouterLink}
            to={item.path}
            sx={{
              color: 'inherit',
              textDecoration: 'none',
              backgroundColor: location.pathname === item.path ? 'action.selected' : 'transparent',
              '&:hover': {
                backgroundColor: 'action.hover'
              },
              minHeight: 48
            }}
            onClick={() => isMobile && setMobileOpen(false)}
          >
            <ListItemIcon sx={{ minWidth: 40 }}>
              {item.icon}
            </ListItemIcon>
            <ListItemText primary={item.text} />
          </ListItem>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { md: `calc(100% - 250px)` },
          ml: { md: '250px' },
          zIndex: theme.zIndex.drawer + 1
        }}
      >
        <Toolbar>
          {isMobile && (
            <IconButton
              color="inherit"
              aria-label="Open navigation menu"
              edge="start"
              onClick={() => setMobileOpen(!mobileOpen)}
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
          )}
          <Typography variant="h6" noWrap component="h1" sx={{ flexGrow: 1 }}>
            eSIM Enterprise Management Portal
          </Typography>
        </Toolbar>
      </AppBar>

      <Box
        component="nav"
        sx={{ width: { md: 250 }, flexShrink: { md: 0 } }}
        aria-label="Navigation drawer"
      >
        {isMobile ? (
          <Drawer
            variant="temporary"
            open={mobileOpen}
            onClose={() => setMobileOpen(false)}
            ModalProps={{
              keepMounted: true // Better mobile performance
            }}
            sx={{
              '& .MuiDrawer-paper': { 
                boxSizing: 'border-box', 
                width: 250,
                backgroundColor: 'background.paper'
              }
            }}
          >
            {drawer}
          </Drawer>
        ) : (
          <Drawer
            variant="permanent"
            sx={{
              '& .MuiDrawer-paper': {
                boxSizing: 'border-box',
                width: 250,
                backgroundColor: 'background.paper',
                borderRight: '1px solid',
                borderColor: 'divider'
              }
            }}
            open
          >
            {drawer}
          </Drawer>
        )}
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { md: `calc(100% - 250px)` },
          minHeight: '100vh',
          backgroundColor: 'background.default'
        }}
      >
        <Toolbar /> {/* Spacer for fixed AppBar */}
        
        <Container maxWidth="xl" sx={{ py: 3 }}>
          <Breadcrumbs
            separator={<NavigateNext fontSize="small" />}
            aria-label="Breadcrumb navigation"
            sx={{ mb: 3 }}
          >
            {getBreadcrumbs()}
          </Breadcrumbs>
          
          <Box
            sx={{
              minHeight: 'calc(100vh - 200px)',
              backgroundColor: 'background.paper',
              borderRadius: 2,
              p: 3,
              boxShadow: 1
            }}
          >
            {children}
          </Box>
        </Container>
      </Box>
    </Box>
  );
};

export default ResponsiveLayout;