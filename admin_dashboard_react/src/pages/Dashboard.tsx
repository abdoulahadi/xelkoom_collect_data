import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Paper,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  People,
  RecordVoiceOver,
  CheckCircle,
  PendingActions,
  TrendingUp,
  Storage,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { apiService } from '../services/api';
import { DashboardMetrics } from '../types';
import BalanceDashboard from '../components/BalanceDashboard';

interface MetricCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
  subtitle?: string;
  trend?: number;
}

const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  icon,
  color,
  subtitle,
  trend,
}) => (
  <Card
    sx={{
      height: '100%',
      background: `linear-gradient(135deg, ${color}15 0%, ${color}05 100%)`,
      border: `1px solid ${color}20`,
    }}
  >
    <CardContent>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
        <Box
          sx={{
            p: 1,
            borderRadius: 2,
            backgroundColor: `${color}20`,
            color: color,
            mr: 2,
          }}
        >
          {icon}
        </Box>
        <Typography variant="h6" fontWeight={600} color="text.primary">
          {title}
        </Typography>
      </Box>
      
      <Typography variant="h4" fontWeight={700} color={color} gutterBottom>
        {typeof value === 'number' ? value.toLocaleString() : value}
      </Typography>
      
      {subtitle && (
        <Typography variant="body2" color="text.secondary">
          {subtitle}
        </Typography>
      )}
      
      {trend !== undefined && (
        <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
          <TrendingUp
            sx={{
              fontSize: 16,
              color: trend >= 0 ? 'success.main' : 'error.main',
              mr: 0.5,
            }}
          />
          <Typography
            variant="caption"
            color={trend >= 0 ? 'success.main' : 'error.main'}
          >
            {trend >= 0 ? '+' : ''}{trend}% cette semaine
          </Typography>
        </Box>
      )}
    </CardContent>
  </Card>
);

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const {
    data: metrics,
    isLoading,
    error,
    refetch,
  } = useQuery<DashboardMetrics>({
    queryKey: ['dashboard-metrics'],
    queryFn: () => apiService.getDashboardMetrics(),
    refetchInterval: 30000,
    staleTime: 10000,
  });

  if (isLoading) {
    return (
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: 400,
        }}
      >
        <CircularProgress size={60} />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" action={
        <button onClick={() => refetch()}>Réessayer</button>
      }>
        Erreur lors du chargement des métriques
      </Alert>
    );
  }

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* Page Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={700} gutterBottom>
          Tableau de bord
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Vue d'ensemble de la plateforme Xelkoom
        </Typography>
      </Box>

      {/* Metrics Grid */}
      <Grid container spacing={3}>
        {/* User Metrics */}
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Utilisateurs totaux"
            value={metrics?.total_users || 0}
            icon={<People />}
            color="#1976d2"
            subtitle={`${metrics?.active_users || 0} actifs`}
            trend={12}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Enregistrements"
            value={metrics?.total_recordings || 0}
            icon={<RecordVoiceOver />}
            color="#2e7d32"
            subtitle={formatDuration(metrics?.total_audio_duration || 0)}
            trend={8}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Approuvés"
            value={metrics?.validated_recordings || 0}
            icon={<CheckCircle />}
            color="#ed6c02"
            subtitle={`Validés`}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="En attente"
            value={metrics?.pending_recordings || 0}
            icon={<PendingActions />}
            color="#d32f2f"
            subtitle="Modération requise"
          />
        </Grid>

        {/* Phrases disponibles */}
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Phrases disponibles"
            value={metrics?.available_sentences || 0}
            icon={<Storage />}
            color="#7b1fa2"
            subtitle={`${metrics?.total_sentences || 0} total`}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Rejets"
            value={metrics?.rejected_recordings || 0}
            icon={<People />}
            color="#d32f2f"
            subtitle="Enregistrements rejetés"
          />
        </Grid>
      </Grid>

      {/* Balance Dashboard Section */}
      <Box sx={{ mt: 4 }}>
        <BalanceDashboard />
      </Box>

      {/* Quick Actions */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h5" fontWeight={600} gutterBottom>
          Actions rapides
        </Typography>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6} md={4}>
            <Paper
              sx={{
                p: 3,
                textAlign: 'center',
                cursor: 'pointer',
                '&:hover': {
                  backgroundColor: 'action.hover',
                },
              }}
              onClick={() => navigate('/moderation')}
            >
              <RecordVoiceOver sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
              <Typography variant="h6" gutterBottom>
                Modération
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {metrics?.pending_recordings || 0} enregistrements en attente
              </Typography>
            </Paper>
          </Grid>

          <Grid item xs={12} sm={6} md={4}>
            <Paper
              sx={{
                p: 3,
                textAlign: 'center',
                cursor: 'pointer',
                '&:hover': {
                  backgroundColor: 'action.hover',
                },
              }}
              onClick={() => navigate('/users')}
            >
              <People sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
              <Typography variant="h6" gutterBottom>
                Utilisateurs
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {metrics?.active_users || 0} utilisateurs actifs
              </Typography>
            </Paper>
          </Grid>

          <Grid item xs={12} sm={6} md={4}>
            <Paper
              sx={{
                p: 3,
                textAlign: 'center',
                cursor: 'pointer',
                '&:hover': {
                  backgroundColor: 'action.hover',
                },
              }}
              onClick={() => navigate('/analytics')}
            >
              <TrendingUp sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
              <Typography variant="h6" gutterBottom>
                Analytics
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Voir les statistiques détaillées
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
};

export default Dashboard;
