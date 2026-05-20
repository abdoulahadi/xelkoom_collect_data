import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Alert,
  AlertTitle,
  CircularProgress,
  Button,
  Grid,
  Divider,
} from '@mui/material';
import {
  Refresh,
  Download,
  Error as ErrorIcon,
} from '@mui/icons-material';
import toast from 'react-hot-toast';

import AnalyticsCards from '../components/AnalyticsCards';
import RecordingStatusCards from '../components/RecordingStatusCards';
import DailyRecordingsChart from '../components/DailyRecordingsChart';
import EngagementMetrics from '../components/EngagementMetrics';
import PeriodFilter, { PeriodFilter as PeriodFilterType } from '../components/PeriodFilter';
import { useAnalytics } from '../hooks/useAnalytics';

const Analytics: React.FC = () => {
  const [selectedPeriod, setSelectedPeriod] = useState<PeriodFilterType>('30d');

  const {
    metrics,
    loading,
    error,
    refreshing,
    lastUpdated,
    refresh,
  } = useAnalytics(selectedPeriod);

  const handleExportData = async () => {
    try {
      if (!metrics) return;
      
      // Create export data
      const exportData = {
        timestamp: new Date().toISOString(),
        period: selectedPeriod,
        metrics: {
          users: {
            total: metrics.total_users,
            active: metrics.active_users,
          },
          sentences: {
            total: metrics.total_sentences,
            available: metrics.available_sentences,
          },
          recordings: {
            total: metrics.total_recordings,
            pending: metrics.pending_recordings,
            validated: metrics.validated_recordings,
            rejected: metrics.rejected_recordings,
            total_duration: metrics.total_audio_duration,
          },
          daily_activity: metrics.daily_recordings,
        },
      };

      const dataStr = JSON.stringify(exportData, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });
      const url = URL.createObjectURL(dataBlob);
      
      const link = document.createElement('a');
      link.href = url;
      link.download = `xelkoom-analytics-${new Date().toISOString().split('T')[0]}.json`;
      link.click();
      
      URL.revokeObjectURL(url);
      toast.success('Données exportées avec succès');
    } catch (err) {
      toast.error('Erreur lors de l\'export des données');
    }
  };

  const renderError = () => (
    <Paper sx={{ p: 4, textAlign: 'center' }}>
      <ErrorIcon sx={{ fontSize: 60, color: 'error.main', mb: 2 }} />
      <Typography variant="h5" gutterBottom>
        Erreur de chargement
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        {error}
      </Typography>
      <Button
        variant="contained"
        startIcon={<Refresh />}
        onClick={refresh}
        disabled={refreshing}
      >
        {refreshing ? 'Rechargement...' : 'Réessayer'}
      </Button>
    </Paper>
  );

  const renderLoading = () => (
    <Paper sx={{ p: 6, textAlign: 'center' }}>
      <CircularProgress size={60} sx={{ mb: 2 }} />
      <Typography variant="h5" gutterBottom>
        Chargement des analytics
      </Typography>
      <Typography variant="body1" color="text.secondary">
        Récupération des données en cours...
      </Typography>
    </Paper>
  );

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight={700} gutterBottom>
              Analytics et statistiques
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Analyse détaillée des données de la plateforme Xelkoom
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Download />}
              onClick={handleExportData}
              disabled={loading || !metrics}
            >
              Exporter
            </Button>
            <Button
              variant="contained"
              startIcon={<Refresh />}
              onClick={refresh}
              disabled={refreshing}
            >
              {refreshing ? 'Actualisation...' : 'Actualiser'}
            </Button>
          </Box>
        </Box>

        {lastUpdated && (
          <Typography variant="caption" color="text.secondary">
            Dernière mise à jour: {lastUpdated.toLocaleString('fr-FR')}
          </Typography>
        )}
      </Box>

      {/* Period Filter */}
      <PeriodFilter
        value={selectedPeriod}
        onChange={setSelectedPeriod}
        disabled={loading}
      />

      {/* Error State */}
      {error && !loading && renderError()}

      {/* Loading State */}
      {loading && renderLoading()}

      {/* Analytics Content */}
      {!loading && !error && metrics && (
        <>
          {/* Main Metrics Cards */}
          <AnalyticsCards metrics={metrics} loading={loading} />

          {/* Recording Status Cards */}
          <RecordingStatusCards metrics={metrics} loading={loading} />

          <Divider sx={{ my: 4 }} />

          {/* Charts and Advanced Metrics */}
          <Grid container spacing={4}>
            <Grid item xs={12}>
              <DailyRecordingsChart metrics={metrics} loading={loading} />
            </Grid>
            
            <Grid item xs={12}>
              <EngagementMetrics metrics={metrics} loading={loading} />
            </Grid>
          </Grid>

          {/* Info Alert */}
          <Alert severity="info" sx={{ mt: 4 }}>
            <AlertTitle>Informations sur les données</AlertTitle>
            Les métriques sont calculées en temps réel à partir de la base de données. 
            La période sélectionnée affecte uniquement l'affichage du graphique d'activité quotidienne.
            {metrics.daily_recordings.length > 0 && (
              <Typography variant="body2" sx={{ mt: 1 }}>
                Données disponibles sur {metrics.daily_recordings.length} jours.
              </Typography>
            )}
          </Alert>
        </>
      )}
    </Box>
  );
};

export default Analytics;
