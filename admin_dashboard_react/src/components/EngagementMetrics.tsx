import React from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  Grid,
  Chip,
  LinearProgress,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  TrendingFlat,
} from '@mui/icons-material';
import { DashboardMetrics } from '../types';

interface EngagementMetricsProps {
  metrics: DashboardMetrics;
  loading?: boolean;
}

const EngagementMetrics: React.FC<EngagementMetricsProps> = ({ metrics, loading = false }) => {
  // Calculate engagement metrics
  const activeUserRate = metrics.total_users > 0 
    ? ((metrics.active_users / metrics.total_users) * 100) 
    : 0;
    
  const validationRate = metrics.total_recordings > 0 
    ? ((metrics.validated_recordings / metrics.total_recordings) * 100) 
    : 0;
    
  const rejectionRate = metrics.total_recordings > 0 
    ? ((metrics.rejected_recordings / metrics.total_recordings) * 100) 
    : 0;
    
  const pendingRate = metrics.total_recordings > 0 
    ? ((metrics.pending_recordings / metrics.total_recordings) * 100) 
    : 0;

  const sentenceUsageRate = metrics.total_sentences > 0 
    ? ((metrics.total_recordings / metrics.total_sentences) * 100) 
    : 0;

  const averageRecordingsPerUser = metrics.total_users > 0 
    ? (metrics.total_recordings / metrics.total_users) 
    : 0;

  const getTrendIcon = (rate: number) => {
    if (rate >= 70) return <TrendingUp color="success" />;
    if (rate >= 40) return <TrendingFlat color="warning" />;
    return <TrendingDown color="error" />;
  };

  const getTrendColor = (rate: number) => {
    if (rate >= 70) return 'success';
    if (rate >= 40) return 'warning';
    return 'error';
  };

  const metrics_data = [
    {
      title: 'Taux de participation',
      value: activeUserRate,
      description: 'Utilisateurs actifs',
      suffix: '%',
      trend: getTrendIcon(activeUserRate),
      color: getTrendColor(activeUserRate),
    },
    {
      title: 'Taux de validation',
      value: validationRate,
      description: 'Enregistrements approuvés',
      suffix: '%',
      trend: getTrendIcon(validationRate),
      color: getTrendColor(validationRate),
    },
    {
      title: 'Utilisation des phrases',
      value: sentenceUsageRate,
      description: 'Phrases enregistrées',
      suffix: '%',
      trend: getTrendIcon(sentenceUsageRate),
      color: getTrendColor(sentenceUsageRate),
    },
    {
      title: 'Moyenne par utilisateur',
      value: averageRecordingsPerUser,
      description: 'Enregistrements par utilisateur',
      suffix: '',
      trend: getTrendIcon(averageRecordingsPerUser * 10), // Scale for trend calculation
      color: getTrendColor(averageRecordingsPerUser * 10),
    },
  ];

  if (loading) {
    return (
      <Card sx={{ mb: 4 }}>
        <CardHeader title="Métriques d'engagement" />
        <CardContent>
          <Grid container spacing={3}>
            {[1, 2, 3, 4].map((_, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Box sx={{ height: 100 }}>
                  <LinearProgress />
                </Box>
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card sx={{ mb: 4 }}>
      <CardHeader 
        title="Métriques d'engagement" 
        subheader="Indicateurs de performance de la plateforme"
      />
      <CardContent>
        <Grid container spacing={3}>
          {metrics_data.map((metric, index) => (
            <Grid item xs={12} sm={6} md={3} key={index}>
              <Box
                sx={{
                  p: 2,
                  border: '1px solid',
                  borderColor: 'divider',
                  borderRadius: 2,
                  textAlign: 'center',
                  transition: 'all 0.2s ease-in-out',
                  '&:hover': {
                    borderColor: 'primary.main',
                    transform: 'translateY(-2px)',
                    boxShadow: 1,
                  },
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
                  {metric.trend}
                  <Typography variant="h4" sx={{ ml: 1, fontWeight: 700 }}>
                    {metric.value.toFixed(1)}{metric.suffix}
                  </Typography>
                </Box>
                
                <Typography variant="body2" sx={{ fontWeight: 600, mb: 1 }}>
                  {metric.title}
                </Typography>
                
                <Typography variant="caption" color="text.secondary" sx={{ mb: 2, display: 'block' }}>
                  {metric.description}
                </Typography>

                <Chip
                  label={metric.color === 'success' ? 'Excellent' : 
                         metric.color === 'warning' ? 'Moyen' : 'Faible'}
                  color={metric.color as 'success' | 'warning' | 'error' | 'default'}
                  size="small"
                  variant="outlined"
                />
              </Box>
            </Grid>
          ))}
        </Grid>

        {/* Additional metrics */}
        <Box sx={{ mt: 4 }}>
          <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
            Répartition des statuts
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 1 }}>
                <Typography variant="body2">En attente</Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LinearProgress 
                    variant="determinate" 
                    value={pendingRate} 
                    sx={{ width: 60, height: 6 }}
                    color="warning"
                  />
                  <Typography variant="caption">{pendingRate.toFixed(1)}%</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid item xs={12} md={4}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 1 }}>
                <Typography variant="body2">Rejetés</Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LinearProgress 
                    variant="determinate" 
                    value={rejectionRate} 
                    sx={{ width: 60, height: 6 }}
                    color="error"
                  />
                  <Typography variant="caption">{rejectionRate.toFixed(1)}%</Typography>
                </Box>
              </Box>
            </Grid>
            <Grid item xs={12} md={4}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 1 }}>
                <Typography variant="body2">Validés</Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LinearProgress 
                    variant="determinate" 
                    value={validationRate} 
                    sx={{ width: 60, height: 6 }}
                    color="success"
                  />
                  <Typography variant="caption">{validationRate.toFixed(1)}%</Typography>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Box>
      </CardContent>
    </Card>
  );
};

export default EngagementMetrics;
