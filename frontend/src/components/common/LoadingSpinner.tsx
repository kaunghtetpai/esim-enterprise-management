import React from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';

interface LoadingSpinnerProps {
  message?: string;
  size?: number;
  fullScreen?: boolean;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  message = 'Loading...',
  size = 40,
  fullScreen = false
}) => {
  const containerProps = fullScreen
    ? {
        position: 'fixed' as const,
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(255, 255, 255, 0.8)',
        zIndex: 9999
      }
    : {
        minHeight: '200px'
      };

  return (
    <Box
      display="flex"
      flexDirection="column"
      alignItems="center"
      justifyContent="center"
      {...containerProps}
    >
      <CircularProgress size={size} />
      {message && (
        <Typography variant="body2" color="textSecondary" mt={2}>
          {message}
        </Typography>
      )}
    </Box>
  );
};