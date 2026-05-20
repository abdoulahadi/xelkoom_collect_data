import React from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  Chip,
  Grid,
  LinearProgress,
  Alert,
} from '@mui/material';
import {
  CheckCircle,
  Warning,
  Error as ErrorIcon,
  Storage,
  Memory,
} from '@mui/icons-material';
import { SystemHealth } from '../types';

interface SystemHealthCardProps {
  health: SystemHealth | null;
  loading?: boolean;
}

const SystemHealthCard: React.FC<SystemHealthCardProps> = ({ health, loading = false }) => {
  const formatBytes = (bytes: number): string => {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size = bytes;
    let unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return `${size.toFixed(1)} ${units[unitIndex]}`;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle color="success" />;
      case 'degraded':
        return <Warning color="warning" />;
      case 'error':
        return <ErrorIcon color="error" />;
      default:
        return <ErrorIcon color="disabled" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'success' as const;
      case 'degraded':
        return 'warning' as const;
      case 'error':
        return 'error' as const;
      default:
        return 'default' as const;
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader title="État du système" />
        <CardContent>
          <LinearProgress />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Vérification de l'état du système...
          </Typography>
        </CardContent>
      </Card>
    );
  }

  if (!health) {
    return (
      <Card>
        <CardHeader title="État du système" />
        <CardContent>
          <Alert severity="error">
            Impossible de récupérer l'état du système
          </Alert>
        </CardContent>
      </Card>
    );
  }

  if (health.error) {
    return (
      <Card>
        <CardHeader title="État du système" />
        <CardContent>
          <Alert severity="error">
            <Typography variant="h6">Erreur système</Typography>
            <Typography variant="body2">{health.error}</Typography>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader
        title="État du système"
        action={
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {getStatusIcon(health.status)}
            <Chip
              label={health.status === 'healthy' ? 'Sain' : 
                     health.status === 'degraded' ? 'Dégradé' : 'Erreur'}
              color={getStatusColor(health.status)}
              size="small"
            />
          </Box>
        }
        subheader={`Dernière vérification: ${new Date(health.timestamp).toLocaleString('fr-FR')}`}
      />
      <CardContent>
        <Grid container spacing={3}>
          {/* Database Status */}
          {health.database && (
            <Grid item xs={12} md={4}>
              <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Storage sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Base de données</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Status: {health.database.status}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Taille: {formatBytes(health.database.size_bytes)}
                </Typography>
              </Box>
            </Grid>
          )}

          {/* Storage Status */}
          {health.storage && (
            <Grid item xs={12} md={4}>
              <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Storage sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Stockage</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Fichiers audio: {health.storage.audio_files_count.toLocaleString()}
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Taille audio: {formatBytes(health.storage.audio_storage_size_bytes)}
                </Typography>
                <Box sx={{ mt: 1 }}>
                  <Typography variant="caption" color="text.secondary">
                    Utilisation disque: {health.storage.disk_usage_percent.toFixed(1)}%
                  </Typography>
                  <LinearProgress
                    variant="determinate"
                    value={health.storage.disk_usage_percent}
                    sx={{ mt: 0.5, height: 6 }}
                    color={health.storage.disk_usage_percent > 90 ? 'error' : 'primary'}
                  />
                  <Typography variant="caption" color="text.secondary">
                    {formatBytes(health.storage.disk_used_bytes)} / {formatBytes(health.storage.disk_total_bytes)}
                  </Typography>
                </Box>
              </Box>
            </Grid>
          )}

          {/* System Resources */}
          {health.system && (
            <Grid item xs={12} md={4}>
              <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Memory sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Ressources</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  CPU: {health.system.cpu_count} cœurs
                </Typography>
                <Box sx={{ mt: 1 }}>
                  <Typography variant="caption" color="text.secondary">
                    RAM: {health.system.memory_usage_percent.toFixed(1)}%
                  </Typography>
                  <LinearProgress
                    variant="determinate"
                    value={health.system.memory_usage_percent}
                    sx={{ mt: 0.5, height: 6 }}
                    color={health.system.memory_usage_percent > 85 ? 'error' : 'primary'}
                  />
                  <Typography variant="caption" color="text.secondary">
                    {formatBytes(health.system.memory_used_bytes)} / {formatBytes(health.system.memory_total_bytes)}
                  </Typography>
                </Box>
              </Box>
            </Grid>
          )}
        </Grid>
      </CardContent>
    </Card>
  );
};

export default SystemHealthCard;
