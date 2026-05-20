import React from 'react';
import {
  Box,
  CircularProgress,
  Typography,
  Paper,
} from '@mui/material';

interface LoadingScreenProps {
  message?: string;
  size?: number;
  fullScreen?: boolean;
}

const LoadingScreen: React.FC<LoadingScreenProps> = ({
  message = 'Chargement...',
  size = 60,
  fullScreen = true,
}) => {
  const content = (
    <Box
      display="flex"
      flexDirection="column"
      alignItems="center"
      justifyContent="center"
      gap={2}
      p={4}
    >
      <CircularProgress
        size={size}
        thickness={4}
        sx={{
          color: 'primary.main',
        }}
      />
      <Typography
        variant="body1"
        color="text.secondary"
        textAlign="center"
        sx={{
          fontWeight: 500,
        }}
      >
        {message}
      </Typography>
    </Box>
  );

  if (fullScreen) {
    return (
      <Box
        sx={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          backgroundColor: 'background.default',
          zIndex: 9999,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Paper
          elevation={3}
          sx={{
            borderRadius: 2,
            minWidth: 200,
          }}
        >
          {content}
        </Paper>
      </Box>
    );
  }

  return content;
};

export default LoadingScreen;
