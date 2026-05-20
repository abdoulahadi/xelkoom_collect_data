import React from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
} from '@mui/material';
import {
  CheckCircle,
  Pending,
  Cancel,
  Assessment,
} from '@mui/icons-material';
import { DashboardMetrics } from '../types';

interface RecordingStatusCardsProps {
  metrics: DashboardMetrics;
  loading?: boolean;
}

const RecordingStatusCards: React.FC<RecordingStatusCardsProps> = ({ metrics, loading = false }) => {
  const statusCards = [
    {
      title: 'En attente',
      value: metrics.pending_recordings,
      icon: <Pending />,
      color: '#ed6c02',
      chipColor: 'warning' as const,
    },
    {
      title: 'Validés',
      value: metrics.validated_recordings,
      icon: <CheckCircle />,
      color: '#2e7d32',
      chipColor: 'success' as const,
    },
    {
      title: 'Rejetés',
      value: metrics.rejected_recordings,
      icon: <Cancel />,
      color: '#d32f2f',
      chipColor: 'error' as const,
    },
    {
      title: 'Total',
      value: metrics.total_recordings,
      icon: <Assessment />,
      color: '#1976d2',
      chipColor: 'primary' as const,
    },
  ];

  if (loading) {
    return (
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {statusCards.map((_, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ height: 80 }} />
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Box sx={{ mb: 4 }}>
      <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
        Statut des enregistrements
      </Typography>
      <Grid container spacing={2}>
        {statusCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card
              sx={{
                height: '100%',
                transition: 'all 0.2s ease-in-out',
                '&:hover': {
                  transform: 'translateY(-2px)',
                  boxShadow: 2,
                },
              }}
            >
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                      {card.title}
                    </Typography>
                    <Typography variant="h4" fontWeight={700} color={card.color}>
                      {card.value.toLocaleString()}
                    </Typography>
                  </Box>
                  <Box
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      width: 40,
                      height: 40,
                      borderRadius: '10px',
                      backgroundColor: `${card.color}20`,
                      color: card.color,
                    }}
                  >
                    {card.icon}
                  </Box>
                </Box>
                
                <Box sx={{ mt: 2 }}>
                  <Chip
                    label={`${(metrics.total_recordings > 0 ? (card.value / metrics.total_recordings) * 100 : 0).toFixed(1)}%`}
                    size="small"
                    color={card.chipColor}
                    variant="outlined"
                  />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default RecordingStatusCards;
