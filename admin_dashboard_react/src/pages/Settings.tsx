import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Alert,
  AlertTitle,
} from '@mui/material';
import {
  Refresh,
  Download,
} from '@mui/icons-material';
import toast from 'react-hot-toast';

import SystemHealthCard from '../components/SystemHealthCard';
import SystemConfigCard from '../components/SystemConfigCard';
import SystemLogsCard from '../components/SystemLogsCard';
import { useSystem } from '../hooks/useSystem';

const Settings: React.FC = () => {
  const {
    health,
    config,
    logs,
    loading,
    error,
    refreshHealth,
    refreshConfig,
    fetchLogs,
  } = useSystem();

  const [refreshing, setRefreshing] = useState(false);

  const handleRefreshAll = async () => {
    setRefreshing(true);
    try {
      await Promise.all([
        refreshHealth(),
        refreshConfig(),
        fetchLogs(1)
      ]);
      toast.success('Données système mises à jour');
    } catch (err) {
      toast.error('Erreur lors de la mise à jour');
    } finally {
      setRefreshing(false);
    }
  };

  const handleExportConfig = () => {
    if (!config || !health) {
      toast.error('Aucune donnée à exporter');
      return;
    }

    const exportData = {
      timestamp: new Date().toISOString(),
      system_health: health,
      system_config: config,
      logs_summary: logs ? {
        total_logs: logs.total,
        current_page: logs.page,
        logs_count: logs.items.length
      } : null
    };

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `xelkoom-system-report-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    
    URL.revokeObjectURL(url);
    toast.success('Rapport système exporté');
  };

  const handleLogsPageChange = (page: number) => {
    fetchLogs(page);
  };

  const handleLogsLevelFilter = (level: string | undefined) => {
    fetchLogs(1, level);
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight={700} gutterBottom>
              Paramètres système
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Configuration et monitoring de la plateforme Xelkoom
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Download />}
              onClick={handleExportConfig}
              disabled={loading || (!config && !health)}
            >
              Exporter
            </Button>
            <Button
              variant="contained"
              startIcon={<Refresh />}
              onClick={handleRefreshAll}
              disabled={refreshing}
            >
              {refreshing ? 'Actualisation...' : 'Actualiser'}
            </Button>
          </Box>
        </Box>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          <AlertTitle>Erreur système</AlertTitle>
          {error}
        </Alert>
      )}

      {/* System Health Status */}
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <SystemHealthCard health={health} loading={loading} />
        </Grid>

        <Grid item xs={12}>
          <SystemConfigCard config={config} loading={loading} />
        </Grid>

        <Grid item xs={12}>
          <SystemLogsCard
            logs={logs}
            loading={loading}
            onPageChange={handleLogsPageChange}
            onLevelFilter={handleLogsLevelFilter}
          />
        </Grid>
      </Grid>

      {/* Information Alert */}
      <Alert severity="info" sx={{ mt: 4 }}>
        <AlertTitle>Informations sur les paramètres système</AlertTitle>
        Cette page affiche l'état de santé du système, la configuration actuelle et les logs en temps réel.
        Les données sont automatiquement actualisées lors du chargement de la page.
        
        <Typography variant="body2" sx={{ mt: 1 }}>
          • <strong>État du système</strong>: Surveillance des ressources (CPU, mémoire, stockage)
        </Typography>
        <Typography variant="body2">
          • <strong>Configuration</strong>: Paramètres actuels de la plateforme (lecture seule)
        </Typography>
        <Typography variant="body2">
          • <strong>Logs</strong>: Activité système récente avec filtrage par niveau
        </Typography>
      </Alert>
    </Box>
  );
};

export default Settings;
