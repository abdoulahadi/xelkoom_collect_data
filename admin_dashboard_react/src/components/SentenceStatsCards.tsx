import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Grid,
  Box,
  Chip,
} from '@mui/material';
import {
  TextFields as TextFieldsIcon,
  RecordVoiceOver as RecordIcon,
  CheckCircle as ActiveIcon,
  Cancel as InactiveIcon,
} from '@mui/icons-material';
import { PaginatedResponse, Sentence } from '../types';

interface SentenceStatsCardsProps {
  sentences: PaginatedResponse<Sentence> | null;
  loading: boolean;
}

const SentenceStatsCards: React.FC<SentenceStatsCardsProps> = ({
  sentences,
  loading,
}) => {
  const totalSentences = sentences?.total || 0;
  
  const activeSentences = sentences?.items.filter(s => s.is_active !== false).length || 0;
  const inactiveSentences = sentences?.items.filter(s => s.is_active === false).length || 0;
  
  const totalRecordings = sentences?.items.reduce((sum, s) => sum + (s.recording_count || 0), 0) || 0;
  const avgRecordings = totalSentences > 0 ? Math.round((totalRecordings / totalSentences) * 10) / 10 : 0;

  const difficultyStats = {
    easy: sentences?.items.filter(s => s.difficulty_level === 'easy').length || 0,
    medium: sentences?.items.filter(s => s.difficulty_level === 'medium').length || 0,
    hard: sentences?.items.filter(s => s.difficulty_level === 'hard').length || 0,
  };

  const languageStats = sentences?.items.reduce((acc, s) => {
    acc[s.language] = (acc[s.language] || 0) + 1;
    return acc;
  }, {} as Record<string, number>) || {};

  const statsCards = [
    {
      title: 'Total des phrases',
      value: totalSentences,
      icon: TextFieldsIcon,
      color: '#1976d2',
      subtitle: `${activeSentences} actives, ${inactiveSentences} inactives`,
    },
    {
      title: 'Enregistrements',
      value: totalRecordings,
      icon: RecordIcon,
      color: '#2e7d32',
      subtitle: `${avgRecordings} en moyenne par phrase`,
    },
    {
      title: 'Phrases actives',
      value: activeSentences,
      icon: ActiveIcon,
      color: '#388e3c',
      subtitle: `${totalSentences > 0 ? Math.round((activeSentences / totalSentences) * 100) : 0}% du total`,
    },
    {
      title: 'Phrases inactives',
      value: inactiveSentences,
      icon: InactiveIcon,
      color: '#d32f2f',
      subtitle: `${totalSentences > 0 ? Math.round((inactiveSentences / totalSentences) * 100) : 0}% du total`,
    },
  ];

  if (loading) {
    return (
      <Grid container spacing={3}>
        {statsCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <card.icon sx={{ color: card.color, mr: 1 }} />
                  <Typography variant="h6" component="div">
                    {card.title}
                  </Typography>
                </Box>
                <Typography variant="h4" component="div" sx={{ mb: 1 }}>
                  -
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Chargement...
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Box>
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {statsCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <card.icon sx={{ color: card.color, mr: 1 }} />
                  <Typography variant="h6" component="div">
                    {card.title}
                  </Typography>
                </Box>
                <Typography variant="h4" component="div" sx={{ mb: 1 }}>
                  {card.value.toLocaleString()}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {card.subtitle}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Statistiques détaillées */}
      <Grid container spacing={3}>
        {/* Répartition par difficulté */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Répartition par difficulté
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                <Chip
                  label={`Facile: ${difficultyStats.easy}`}
                  color="success"
                  variant="outlined"
                />
                <Chip
                  label={`Moyen: ${difficultyStats.medium}`}
                  color="warning"
                  variant="outlined"
                />
                <Chip
                  label={`Difficile: ${difficultyStats.hard}`}
                  color="error"
                  variant="outlined"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Répartition par langue */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Répartition par langue
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                {Object.entries(languageStats).map(([language, count]) => (
                  <Chip
                    key={language}
                    label={`${language.toUpperCase()}: ${count}`}
                    color="primary"
                    variant="outlined"
                  />
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default SentenceStatsCards;
