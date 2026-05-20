import React from 'react';
import { Box, Typography, Button } from '@mui/material';
import { useAnalytics } from '../hooks/useAnalytics';

/**
 * Composant de test simple pour vérifier le hook useAnalytics
 * Permet de tester le comportement sans boucles infinites
 */
const AnalyticsTest: React.FC = () => {
  const { metrics, loading, error, refreshing, lastUpdated, refresh } = useAnalytics();

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        Test Analytics Hook
      </Typography>
      
      <Box sx={{ mb: 2 }}>
        <Typography>Status: {loading ? 'Loading...' : refreshing ? 'Refreshing...' : 'Ready'}</Typography>
        <Typography>Error: {error || 'None'}</Typography>
        <Typography>Last Updated: {lastUpdated?.toLocaleString() || 'Never'}</Typography>
        <Typography>Has Data: {metrics ? 'Yes' : 'No'}</Typography>
      </Box>

      <Button variant="contained" onClick={refresh} disabled={refreshing}>
        Refresh Data
      </Button>

      {metrics && (
        <Box sx={{ mt: 2 }}>
          <Typography variant="h6">Quick Stats:</Typography>
          <Typography>Users: {metrics.total_users}</Typography>
          <Typography>Recordings: {metrics.total_recordings}</Typography>
          <Typography>Daily Records: {metrics.daily_recordings.length} days</Typography>
        </Box>
      )}
    </Box>
  );
};

export default AnalyticsTest;
