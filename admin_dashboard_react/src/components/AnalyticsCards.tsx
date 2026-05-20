import React from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  LinearProgress,
} from '@mui/material';
import {
  People,
  TextFields,
  GraphicEq,
  Timer,
} from '@mui/icons-material';
import { DashboardMetrics } from '../types';

interface AnalyticsCardsProps {
  metrics: DashboardMetrics;
  loading?: boolean;
}

const AnalyticsCards: React.FC<AnalyticsCardsProps> = ({ metrics, loading = false }) => {
  const formatDuration = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = Math.floor(seconds % 60);

    if (hours > 0) {
      return `${hours}h ${minutes}m ${remainingSeconds}s`;
    } else if (minutes > 0) {
      return `${minutes}m ${remainingSeconds}s`;
    } else {
      return `${remainingSeconds}s`;
    }
  };

  const calculatePercentage = (value: number, total: number): number => {
    return total > 0 ? Math.round((value / total) * 100) : 0;
  };

  const cards = [
    {
      title: 'Utilisateurs',
      icon: <People />,
      value: metrics.total_users,
      subtitle: `${metrics.active_users} actifs`,
      color: '#1976d2',
      progress: calculatePercentage(metrics.active_users, metrics.total_users),
    },
    {
      title: 'Phrases',
      icon: <TextFields />,
      value: metrics.total_sentences,
      subtitle: `${metrics.available_sentences} disponibles`,
      color: '#388e3c',
      progress: calculatePercentage(metrics.available_sentences, metrics.total_sentences),
    },
    {
      title: 'Enregistrements',
      icon: <GraphicEq />,
      value: metrics.total_recordings,
      subtitle: `${metrics.validated_recordings} validés`,
      color: '#f57c00',
      progress: calculatePercentage(metrics.validated_recordings, metrics.total_recordings),
    },
    {
      title: 'Durée audio totale',
      icon: <Timer />,
      value: formatDuration(metrics.total_audio_duration),
      subtitle: 'Contenu validé',
      color: '#7b1fa2',
      isString: true,
    },
  ];

  if (loading) {
    return (
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {cards.map((_, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ height: 120 }}>
                  <LinearProgress />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      {cards.map((card, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card
            sx={{
              height: '100%',
              transition: 'all 0.3s ease-in-out',
              '&:hover': {
                transform: 'translateY(-4px)',
                boxShadow: 3,
              },
            }}
          >
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 48,
                    height: 48,
                    borderRadius: '12px',
                    backgroundColor: `${card.color}20`,
                    color: card.color,
                    mr: 2,
                  }}
                >
                  {card.icon}
                </Box>
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    {card.title}
                  </Typography>
                  <Typography variant="h5" fontWeight={700}>
                    {card.isString ? card.value : card.value.toLocaleString()}
                  </Typography>
                </Box>
              </Box>

              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {card.subtitle}
              </Typography>

              {!card.isString && card.progress !== undefined && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LinearProgress
                    variant="determinate"
                    value={card.progress}
                    sx={{
                      flex: 1,
                      height: 6,
                      borderRadius: 3,
                      backgroundColor: `${card.color}20`,
                      '& .MuiLinearProgress-bar': {
                        backgroundColor: card.color,
                        borderRadius: 3,
                      },
                    }}
                  />
                  <Typography variant="caption" color="text.secondary">
                    {card.progress}%
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};

export default AnalyticsCards;
