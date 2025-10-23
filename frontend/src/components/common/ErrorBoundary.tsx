import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Box, Typography, Button, Alert } from '@mui/material';
import { Refresh } from '@mui/icons-material';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <Box
          display="flex"
          flexDirection="column"
          alignItems="center"
          justifyContent="center"
          minHeight="400px"
          p={3}
        >
          <Alert severity="error" sx={{ mb: 3, maxWidth: 600 }}>
            <Typography variant="h6" gutterBottom>
              Something went wrong
            </Typography>
            <Typography variant="body2" color="textSecondary" gutterBottom>
              {this.state.error?.message || 'An unexpected error occurred'}
            </Typography>
          </Alert>
          
          <Button
            variant="contained"
            startIcon={<Refresh />}
            onClick={this.handleReload}
          >
            Reload Page
          </Button>
        </Box>
      );
    }

    return this.props.children;
  }
}