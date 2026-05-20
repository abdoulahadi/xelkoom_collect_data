import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Grid,
  Box,
  CircularProgress,
  Alert,
  Chip,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Tabs,
  Tab,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  Balance as BalanceIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';
import { DetailedRecordingDistribution, RecordingDistributionStats, Sentence } from '../types';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`balance-tabpanel-${index}`}
      aria-labelledby={`balance-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const BalanceDashboard: React.FC = () => {
  const [distributionData, setDistributionData] = useState<DetailedRecordingDistribution | null>(null);
  const [statsData, setStatsData] = useState<RecordingDistributionStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState(0);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const [distribution, stats] = await Promise.all([
        apiService.getRecordingDistribution(),
        apiService.getRecordingDistributionStats()
      ]);
      
      setDistributionData(distribution);
      setStatsData(stats);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors du chargement des données d\'\u00e9quilibrage'));
      console.error('Error fetching balance data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={300}>
        <CircularProgress size={60} />
        <Typography variant="h6" sx={{ ml: 2 }}>
          Chargement des données d'équilibrage...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  if (!distributionData || !statsData) {
    return (
      <Alert severity="warning">
        Aucune donnée d'équilibrage disponible
      </Alert>
    );
  }

  const getProgressColor = (percentage: number) => {
    if (percentage >= 80) return 'success';
    if (percentage >= 60) return 'warning';
    return 'error';
  };

  const balancePercentage = distributionData.summary.total_sentences > 0 
    ? (distributionData.summary.at_target_count / distributionData.summary.total_sentences) * 100 
    : 0;

  return (
    <Box>
      {/* Header avec configuration */}
      <Card sx={{ mb: 3 }}>
        <CardHeader
          title={
            <Box display="flex" alignItems="center" gap={1}>
              <BalanceIcon color="primary" />
              <Typography variant="h6">
                Équilibrage de la Collecte
              </Typography>
            </Box>
          }
          subheader="Analyse de la distribution des enregistrements par phrase"
        />
        <CardContent>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <Box textAlign="center">
                <Typography variant="h4" color="primary">
                  {distributionData.configuration.target_recordings_per_sentence}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Objectif par phrase
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={4}>
              <Box textAlign="center">
                <Typography variant="h4" color="warning.main">
                  {distributionData.configuration.max_recordings_per_sentence}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Maximum par phrase
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={4}>
              <Box textAlign="center">
                <Chip
                  label={distributionData.configuration.balanced_selection_enabled ? 'Activé' : 'Désactivé'}
                  color={distributionData.configuration.balanced_selection_enabled ? 'success' : 'default'}
                  icon={distributionData.configuration.balanced_selection_enabled ? <CheckCircleIcon /> : <CancelIcon />}
                />
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  Sélection équilibrée
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Statistiques générales */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="h4" color="error.main">
                    {distributionData.summary.under_target_count}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Sous-enregistrées
                  </Typography>
                </Box>
                <TrendingDownIcon color="error" fontSize="large" />
              </Box>
              <LinearProgress
                variant="determinate"
                value={(distributionData.summary.under_target_count / distributionData.summary.total_sentences) * 100}
                color="error"
                sx={{ mt: 1 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="h4" color="success.main">
                    {distributionData.summary.at_target_count}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    À l'objectif
                  </Typography>
                </Box>
                <CheckCircleIcon color="success" fontSize="large" />
              </Box>
              <LinearProgress
                variant="determinate"
                value={(distributionData.summary.at_target_count / distributionData.summary.total_sentences) * 100}
                color="success"
                sx={{ mt: 1 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="h4" color="warning.main">
                    {distributionData.summary.over_target_count}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Sur-enregistrées
                  </Typography>
                </Box>
                <TrendingUpIcon color="warning" fontSize="large" />
              </Box>
              <LinearProgress
                variant="determinate"
                value={(distributionData.summary.over_target_count / distributionData.summary.total_sentences) * 100}
                color="warning"
                sx={{ mt: 1 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box textAlign="center">
                <Typography variant="h4" color="primary">
                  {balancePercentage.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Équilibrage global
                </Typography>
                <LinearProgress
                  variant="determinate"
                  value={balancePercentage}
                  color={getProgressColor(balancePercentage)}
                  sx={{ mt: 1 }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Onglets détaillés */}
      <Card>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={activeTab} onChange={handleTabChange}>
            <Tab 
              label={`Sous-enregistrées (${distributionData.summary.under_target_count})`} 
              icon={<TrendingDownIcon />}
            />
            <Tab 
              label={`À l'objectif (${distributionData.summary.at_target_count})`} 
              icon={<CheckCircleIcon />}
            />
            <Tab 
              label={`Sur-enregistrées (${distributionData.summary.over_target_count})`} 
              icon={<TrendingUpIcon />}
            />
          </Tabs>
        </Box>

        <TabPanel value={activeTab} index={0}>
          <SentencesCategoryTable
            sentences={distributionData.categories.under_target}
            title="Phrases nécessitant plus d'enregistrements"
            emptyMessage="Aucune phrase sous-enregistrée ! 🎉"
            priorityLevel="high"
          />
        </TabPanel>

        <TabPanel value={activeTab} index={1}>
          <SentencesCategoryTable
            sentences={distributionData.categories.at_target}
            title="Phrases ayant atteint l'objectif"
            emptyMessage="Aucune phrase n'a encore atteint l'objectif"
            priorityLevel="medium"
          />
        </TabPanel>

        <TabPanel value={activeTab} index={2}>
          <SentencesCategoryTable
            sentences={distributionData.categories.over_target}
            title="Phrases sur-enregistrées"
            emptyMessage="Aucune phrase sur-enregistrée"
            priorityLevel="low"
          />
        </TabPanel>
      </Card>

      {/* Statistiques détaillées */}
      <Accordion sx={{ mt: 3 }}>
        <AccordionSummary expandIcon={<ExpandMoreIcon />}>
          <Typography variant="h6">Statistiques détaillées</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Grid container spacing={2}>
            <Grid item xs={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h5">{statsData.statistics.min_recordings}</Typography>
                <Typography variant="body2" color="text.secondary">Min enregistrements</Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h5">{statsData.statistics.max_recordings}</Typography>
                <Typography variant="body2" color="text.secondary">Max enregistrements</Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h5">{statsData.statistics.avg_recordings.toFixed(1)}</Typography>
                <Typography variant="body2" color="text.secondary">Moyenne par phrase</Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h5">{statsData.statistics.total_validated_recordings}</Typography>
                <Typography variant="body2" color="text.secondary">Total validés</Typography>
              </Box>
            </Grid>
          </Grid>
        </AccordionDetails>
      </Accordion>
    </Box>
  );
};

interface SentencesCategoryTableProps {
  sentences: Sentence[];
  title: string;
  emptyMessage: string;
  priorityLevel: 'high' | 'medium' | 'low';
}

const SentencesCategoryTable: React.FC<SentencesCategoryTableProps> = ({
  sentences,
  title,
  emptyMessage,
  priorityLevel
}) => {
  const getPriorityColor = (level: string) => {
    switch (level) {
      case 'high': return 'error';
      case 'medium': return 'success';
      case 'low': return 'warning';
      default: return 'default';
    }
  };

  if (sentences.length === 0) {
    return (
      <Box textAlign="center" py={4}>
        <Typography variant="h6" color="text.secondary">
          {emptyMessage}
        </Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        {title}
      </Typography>
      
      <TableContainer component={Paper} variant="outlined">
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Phrase</TableCell>
              <TableCell>Difficulté</TableCell>
              <TableCell align="center">Validés</TableCell>
              <TableCell align="center">En attente</TableCell>
              <TableCell align="center">Rejetés</TableCell>
              <TableCell align="center">Total</TableCell>
              <TableCell align="center">Priorité</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sentences.slice(0, 10).map((sentence) => (
              <TableRow key={sentence.id} hover>
                <TableCell>
                  <Typography variant="body2" sx={{ maxWidth: 300 }}>
                    {sentence.text.length > 60 
                      ? `${sentence.text.substring(0, 60)}...` 
                      : sentence.text
                    }
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={sentence.difficulty_level} 
                    size="small"
                    color={sentence.difficulty_level === 'easy' ? 'success' : 
                           sentence.difficulty_level === 'medium' ? 'warning' : 'error'}
                  />
                </TableCell>
                <TableCell align="center">
                  <Typography variant="body2" fontWeight="bold" color="success.main">
                    {sentence.validated_recordings}
                  </Typography>
                </TableCell>
                <TableCell align="center">
                  <Typography variant="body2" color="warning.main">
                    {sentence.pending_recordings}
                  </Typography>
                </TableCell>
                <TableCell align="center">
                  <Typography variant="body2" color="error.main">
                    {sentence.rejected_recordings}
                  </Typography>
                </TableCell>
                <TableCell align="center">
                  <Typography variant="body2" fontWeight="bold">
                    {sentence.total_recordings}
                  </Typography>
                </TableCell>
                <TableCell align="center">
                  <Chip 
                    label={priorityLevel === 'high' ? 'Élevée' : 
                           priorityLevel === 'medium' ? 'Normale' : 'Faible'} 
                    size="small"
                    color={getPriorityColor(priorityLevel) as 'error' | 'success' | 'warning' | 'default'}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      
      {sentences.length > 10 && (
        <Box textAlign="center" mt={2}>
          <Typography variant="body2" color="text.secondary">
            ... et {sentences.length - 10} autres phrases
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default BalanceDashboard;
