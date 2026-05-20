import React from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  Chip,
  Grid,
  List,
  ListItem,
  ListItemText,
  LinearProgress,
} from '@mui/material';
import {
  Settings,
  Security,
  AudioFile,
  Speed,
  Code,
  BugReport,
} from '@mui/icons-material';
import { SystemConfig } from '../types';

interface SystemConfigCardProps {
  config: SystemConfig | null;
  loading?: boolean;
}

const SystemConfigCard: React.FC<SystemConfigCardProps> = ({ config, loading = false }) => {
  if (loading) {
    return (
      <Card>
        <CardHeader title="Configuration système" />
        <CardContent>
          <LinearProgress />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Chargement de la configuration...
          </Typography>
        </CardContent>
      </Card>
    );
  }

  if (!config) {
    return (
      <Card>
        <CardHeader title="Configuration système" />
        <CardContent>
          <Typography color="error">
            Impossible de charger la configuration
          </Typography>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader title="Configuration système" />
      <CardContent>
        <Grid container spacing={3}>
          {/* Audio Configuration */}
          <Grid item xs={12} md={6}>
            <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <AudioFile sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Audio</Typography>
              </Box>
              <List dense>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Chemin de stockage"
                    secondary={config.audio.storage_path}
                  />
                </ListItem>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Taille maximale"
                    secondary={`${config.audio.max_size_mb} MB`}
                  />
                </ListItem>
              </List>
            </Box>
          </Grid>

          {/* Security Configuration */}
          <Grid item xs={12} md={6}>
            <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Security sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Sécurité</Typography>
              </Box>
              <List dense>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Expiration token"
                    secondary={`${config.security.token_expire_minutes} minutes`}
                  />
                </ListItem>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Algorithme"
                    secondary={config.security.algorithm}
                  />
                </ListItem>
              </List>
            </Box>
          </Grid>

          {/* Rate Limiting */}
          <Grid item xs={12} md={6}>
            <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Speed sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Limitation de débit</Typography>
              </Box>
              <List dense>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Activé"
                    secondary={
                      <Chip
                        label={config.rate_limiting.enabled ? 'Oui' : 'Non'}
                        color={config.rate_limiting.enabled ? 'success' : 'default'}
                        size="small"
                      />
                    }
                  />
                </ListItem>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Limite par défaut"
                    secondary={config.rate_limiting.default_limit}
                  />
                </ListItem>
              </List>
            </Box>
          </Grid>

          {/* Features */}
          <Grid item xs={12} md={6}>
            <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Settings sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Fonctionnalités</Typography>
              </Box>
              <List dense>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Validation Whisper"
                    secondary={
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Chip
                          label={config.features.whisper_validation ? 'Activé' : 'Désactivé'}
                          color={config.features.whisper_validation ? 'success' : 'default'}
                          size="small"
                        />
                        {config.features.whisper_validation && (
                          <Typography variant="caption" color="text.secondary">
                            Modèle: {config.features.whisper_model}
                          </Typography>
                        )}
                      </Box>
                    }
                  />
                </ListItem>
                <ListItem disablePadding>
                  <ListItemText
                    primary="Métriques"
                    secondary={
                      <Chip
                        label={config.features.metrics_enabled ? 'Activé' : 'Désactivé'}
                        color={config.features.metrics_enabled ? 'success' : 'default'}
                        size="small"
                      />
                    }
                  />
                </ListItem>
              </List>
            </Box>
          </Grid>

          {/* Environment */}
          <Grid item xs={12}>
            <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Code sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Environnement</Typography>
              </Box>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="text.secondary">Environnement</Typography>
                  <Chip
                    label={config.environment.environment}
                    color={config.environment.environment === 'production' ? 'success' : 'warning'}
                    size="small"
                    sx={{ mt: 0.5 }}
                  />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="text.secondary">Mode debug</Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', mt: 0.5 }}>
                    <BugReport sx={{ mr: 0.5, fontSize: 16 }} />
                    <Chip
                      label={config.environment.debug ? 'Activé' : 'Désactivé'}
                      color={config.environment.debug ? 'warning' : 'success'}
                      size="small"
                    />
                  </Box>
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="text.secondary">Niveau de log</Typography>
                  <Typography variant="body1" sx={{ mt: 0.5, fontWeight: 600 }}>
                    {config.environment.log_level}
                  </Typography>
                </Grid>
              </Grid>
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
};

export default SystemConfigCard;
