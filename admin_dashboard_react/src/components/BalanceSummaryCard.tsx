import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  Grid,
  LinearProgress,
  Alert,
  AlertTitle,
  Button,
} from '@mui/material';
import {
  Balance as BalanceIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  CheckCircle as CheckCircleIcon,
  Info as InfoIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { RecordingDistributionStats } from '../types';

const BalanceSummaryCard: React.FC = () => {
  const [stats, setStats] = useState<RecordingDistributionStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const data = await apiService.getRecordingDistributionStats();
      setStats(data);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des statistiques');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Card>
        <CardContent>
          <Box display="flex" alignItems="center" gap={1} mb={2}>
            <BalanceIcon color="primary" />
            <Typography variant="h6">Équilibrage de la Collecte</Typography>
          </Box>
          <LinearProgress />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Chargement des statistiques...
          </Typography>
        </CardContent>
      </Card>
    );
  }

  if (error || !stats) {
    return (
      <Alert severity="warning">
        <AlertTitle>Statistiques d'équilibrage indisponibles</AlertTitle>
        {error || 'Impossible de charger les données d\'équilibrage'}
      </Alert>
    );
  }

  const balancePercentage = stats.total_sentences > 0 
    ? (stats.distribution.at_target / stats.total_sentences) * 100 
    : 0;

  const getBalanceStatus = () => {
    if (balancePercentage >= 80) return { status: 'Excellent', color: 'success' as const };
    if (balancePercentage >= 60) return { status: 'Bon', color: 'warning' as const };
    if (balancePercentage >= 40) return { status: 'Moyen', color: 'warning' as const };
    return { status: 'À améliorer', color: 'error' as const };
  };

  const { status, color } = getBalanceStatus();

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Box display="flex" alignItems="center" gap={1}>
            <BalanceIcon color="primary" />
            <Typography variant="h6">Équilibrage de la Collecte</Typography>
          </Box>
          <Chip
            label={status}
            color={color}
            size="small"
          />
        </Box>

        <Grid container spacing={2} sx={{ mb: 2 }}>
          <Grid item xs={4}>
            <Box textAlign="center">
              <Typography variant="h5" color="error.main">
                {stats.distribution.under_target}
              </Typography>
              <Typography variant="caption" color="text.secondary" display="flex" alignItems="center" justifyContent="center" gap={0.5}>
                <TrendingDownIcon fontSize="small" />
                Sous-objectif
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={4}>
            <Box textAlign="center">
              <Typography variant="h5" color="success.main">
                {stats.distribution.at_target}
              </Typography>
              <Typography variant="caption" color="text.secondary" display="flex" alignItems="center" justifyContent="center" gap={0.5}>
                <CheckCircleIcon fontSize="small" />
                À l'objectif
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={4}>
            <Box textAlign="center">
              <Typography variant="h5" color="warning.main">
                {stats.distribution.over_target}
              </Typography>
              <Typography variant="caption" color="text.secondary" display="flex" alignItems="center" justifyContent="center" gap={0.5}>
                <TrendingUpIcon fontSize="small" />
                Sur-objectif
              </Typography>
            </Box>
          </Grid>
        </Grid>

        <Box sx={{ mb: 2 }}>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
            <Typography variant="body2" color="text.secondary">
              Progression globale
            </Typography>
            <Typography variant="body2" fontWeight="bold">
              {balancePercentage.toFixed(1)}%
            </Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={balancePercentage}
            color={color}
            sx={{ height: 8, borderRadius: 4 }}
          />
        </Box>

        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Box display="flex" alignItems="center" gap={1}>
            <InfoIcon fontSize="small" color="action" />
            <Typography variant="caption" color="text.secondary">
              Objectif: {stats.target_recordings_per_sentence} enregistrements/phrase
            </Typography>
          </Box>
          <Button 
            size="small" 
            variant="outlined"
            onClick={() => navigate('/balance')}
          >
            Voir détails
          </Button>
        </Box>
      </CardContent>
    </Card>
  );
};

export default BalanceSummaryCard;
