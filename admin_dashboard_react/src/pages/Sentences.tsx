import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Alert,
  CircularProgress,
  TablePagination,
  Checkbox,
  Toolbar,
  Tooltip,
  Grid,
  Card,
  CardContent,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Refresh as RefreshIcon,
  FileDownload as ExportIcon,
  Upload as ImportIcon,
  Visibility as ViewIcon,
  ToggleOn as ActiveIcon,
  ToggleOff as InactiveIcon,
} from '@mui/icons-material';
import { useSentences } from '../hooks/useSentences';
import { usePermissions } from '../hooks/usePermissions';
import { Sentence } from '../types';
import CreateSentenceDialog from '../components/CreateSentenceDialog';
import EditSentenceDialog from '../components/EditSentenceDialog';
import BulkCreateSentencesDialog from '../components/BulkCreateSentencesDialog';
import SentenceStatsCards from '../components/SentenceStatsCards';
import BalanceSummaryCard from '../components/BalanceSummaryCard';
import ConfirmDialog from '../components/ConfirmDialog';

const SentencesPage: React.FC = () => {
  const {
    sentences,
    loading,
    error,
    filters,
    setFilters,
    fetchSentences,
    createSentence,
    createSentencesBulk,
    updateSentence,
    deleteSentence,
    refreshSentences,
  } = useSentences();

  const { canEdit, canDelete } = usePermissions();

  // States pour les dialogues
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [bulkCreateDialogOpen, setBulkCreateDialogOpen] = useState(false);
  const [selectedSentence, setSelectedSentence] = useState<Sentence | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [sentenceToDelete, setSentenceToDelete] = useState<Sentence | null>(null);

  // States pour la table
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [selectedSentences, setSelectedSentences] = useState<string[]>([]);

  // States pour les filtres
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [difficultyFilter, setDifficultyFilter] = useState('');

  // Gestion des filtres
  const handleSearch = () => {
    setFilters({
      ...filters,
      search: searchTerm,
      status: statusFilter || undefined,
      difficulty: difficultyFilter || undefined,
    });
    setPage(0);
  };

  const clearFilters = () => {
    setSearchTerm('');
    setStatusFilter('');
    setDifficultyFilter('');
    setFilters({});
    setPage(0);
  };

  // Gestion de la pagination
  const handleChangePage = (_: unknown, newPage: number) => {
    setPage(newPage);
    fetchSentences(newPage + 1);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  // Gestion de la sélection
  const handleSelectAll = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.checked) {
      const newSelected = sentences?.items.map((sentence) => sentence.id) || [];
      setSelectedSentences(newSelected);
    } else {
      setSelectedSentences([]);
    }
  };

  const handleSelectSentence = (id: string) => {
    const selectedIndex = selectedSentences.indexOf(id);
    let newSelected: string[] = [];

    if (selectedIndex === -1) {
      newSelected = newSelected.concat(selectedSentences, id);
    } else if (selectedIndex === 0) {
      newSelected = newSelected.concat(selectedSentences.slice(1));
    } else if (selectedIndex === selectedSentences.length - 1) {
      newSelected = newSelected.concat(selectedSentences.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelected = newSelected.concat(
        selectedSentences.slice(0, selectedIndex),
        selectedSentences.slice(selectedIndex + 1),
      );
    }

    setSelectedSentences(newSelected);
  };

  // Actions sur les phrases
  const handleEditSentence = (sentence: Sentence) => {
    setSelectedSentence(sentence);
    setEditDialogOpen(true);
  };

  const handleDeleteSentence = (sentence: Sentence) => {
    setSentenceToDelete(sentence);
    setDeleteDialogOpen(true);
  };

  const handleToggleStatus = async (sentence: Sentence) => {
    try {
      await updateSentence(sentence.id.toString(), {
        status: sentence.status === 'available' ? 'completed' : 'available'
      } as Partial<Sentence>);
    } catch (error) {
      console.error('Erreur lors du changement de statut:', error);
    }
  };

  // Export des données
  const handleExport = () => {
    if (!sentences?.items) return;

    const exportData = sentences.items.map(sentence => ({
      id: sentence.id,
      text: sentence.text,
      language: sentence.language,
      difficulty_level: sentence.difficulty_level,
      status: sentence.status,
      recording_count: sentence.recording_count || 0,
      created_at: sentence.created_at,
      updated_at: sentence.updated_at,
    }));

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = `sentences_${new Date().toISOString().split('T')[0]}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
  };

  // Formatage des données
  const formatDifficulty = (difficulty: string) => {
    const colors = {
      easy: 'success',
      medium: 'warning',
      hard: 'error',
    } as const;
    
    const labels = {
      easy: 'Facile',
      medium: 'Moyen',
      hard: 'Difficile',
    };

    return (
      <Chip
        label={labels[difficulty as keyof typeof labels] || difficulty}
        color={colors[difficulty as keyof typeof colors] || 'default'}
        size="small"
      />
    );
  };

  const formatStatus = (status: string) => {
    const statusConfig: Record<string, { label: string; color: 'success' | 'warning' | 'error' | 'default' }> = {
      available: { label: 'Disponible', color: 'success' },
      assigned: { label: 'Assignée', color: 'warning' },
      completed: { label: 'Complétée', color: 'default' },
      disabled: { label: 'Désactivée', color: 'error' },
    };
    const config = statusConfig[status] || { label: status, color: 'default' };
    return (
      <Chip
        label={config.label}
        color={config.color}
        size="small"
        variant="outlined"
      />
    );
  };

  const isSelected = (id: string) => selectedSentences.indexOf(id) !== -1;

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
        <Button variant="contained" onClick={() => window.location.reload()}>
          Recharger la page
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Gestion des Phrases
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Actualiser">
            <IconButton onClick={refreshSentences} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="outlined"
            startIcon={<ExportIcon />}
            onClick={handleExport}
            disabled={!sentences?.items.length}
          >
            Exporter
          </Button>
          {canEdit && (
            <>
              <Button
                variant="outlined"
                startIcon={<ImportIcon />}
                onClick={() => setBulkCreateDialogOpen(true)}
              >
                Import Bulk
              </Button>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setCreateDialogOpen(true)}
              >
                Nouvelle phrase
              </Button>
            </>
          )}
        </Box>
      </Box>

      {/* Statistiques */}
      <SentenceStatsCards sentences={sentences} loading={loading} />

      {/* Équilibrage Summary */}
      <Box sx={{ mt: 3 }}>
        <BalanceSummaryCard />
      </Box>

      {/* Filtres */}
      <Card sx={{ mb: 3, mt: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Rechercher dans le texte"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                InputProps={{
                  endAdornment: (
                    <IconButton onClick={handleSearch} disabled={loading}>
                      <SearchIcon />
                    </IconButton>
                  ),
                }}
              />
            </Grid>
            <Grid item xs={12} md={2}>
              <FormControl fullWidth>
                <InputLabel>Statut</InputLabel>
                <Select
                  value={statusFilter}
                  label="Statut"
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <MenuItem value="">Tous</MenuItem>
                  <MenuItem value="active">Actives</MenuItem>
                  <MenuItem value="inactive">Inactives</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <FormControl fullWidth>
                <InputLabel>Difficulté</InputLabel>
                <Select
                  value={difficultyFilter}
                  label="Difficulté"
                  onChange={(e) => setDifficultyFilter(e.target.value)}
                >
                  <MenuItem value="">Toutes</MenuItem>
                  <MenuItem value="easy">Facile</MenuItem>
                  <MenuItem value="medium">Moyen</MenuItem>
                  <MenuItem value="hard">Difficile</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <Button
                  variant="contained"
                  onClick={handleSearch}
                  disabled={loading}
                  startIcon={<SearchIcon />}
                >
                  Filtrer
                </Button>
                <Button
                  variant="outlined"
                  onClick={clearFilters}
                  disabled={loading}
                >
                  Effacer
                </Button>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Toolbar de sélection */}
      {selectedSentences.length > 0 && (
        <Toolbar
          sx={{
            pl: { sm: 2 },
            pr: { xs: 1, sm: 1 },
            bgcolor: 'primary.light',
            color: 'primary.contrastText',
            mb: 2,
            borderRadius: 1,
          }}
        >
          <Typography sx={{ flex: '1 1 100%' }} variant="subtitle1" component="div">
            {selectedSentences.length} phrase{selectedSentences.length !== 1 ? 's' : ''} sélectionnée{selectedSentences.length !== 1 ? 's' : ''}
          </Typography>
          {canDelete && (
            <Tooltip title="Supprimer la sélection">
              <IconButton color="inherit" onClick={() => {/* TODO: Bulk delete */}}>
                <DeleteIcon />
              </IconButton>
            </Tooltip>
          )}
        </Toolbar>
      )}

      {/* Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Checkbox
                  color="primary"
                  indeterminate={selectedSentences.length > 0 && selectedSentences.length < (sentences?.items.length || 0)}
                  checked={sentences?.items.length !== undefined && sentences.items.length > 0 && selectedSentences.length === sentences.items.length}
                  onChange={handleSelectAll}
                />
              </TableCell>
              <TableCell>ID</TableCell>
              <TableCell>Texte</TableCell>
              <TableCell>Langue</TableCell>
              <TableCell>Difficulté</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Enregistrements</TableCell>
              <TableCell>Créée le</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={9} sx={{ textAlign: 'center', py: 5 }}>
                  <CircularProgress />
                  <Typography variant="body2" sx={{ mt: 2 }}>
                    Chargement des phrases...
                  </Typography>
                </TableCell>
              </TableRow>
            ) : sentences?.items.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} sx={{ textAlign: 'center', py: 5 }}>
                  <Typography variant="body1" color="textSecondary">
                    Aucune phrase trouvée
                  </Typography>
                  {Object.keys(filters).length > 0 && (
                    <Button
                      variant="outlined"
                      onClick={clearFilters}
                      sx={{ mt: 2 }}
                    >
                      Effacer les filtres
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ) : (
              sentences?.items
                .map((sentence) => {
                  const isItemSelected = isSelected(sentence.id);
                  return (
                    <TableRow
                      hover
                      key={sentence.id}
                      selected={isItemSelected}
                      onClick={() => handleSelectSentence(sentence.id)}
                      sx={{ cursor: 'pointer' }}
                    >
                      <TableCell padding="checkbox">
                        <Checkbox
                          color="primary"
                          checked={isItemSelected}
                          onClick={(e) => e.stopPropagation()}
                          onChange={() => handleSelectSentence(sentence.id)}
                        />
                      </TableCell>
                      <TableCell>{sentence.id}</TableCell>
                      <TableCell sx={{ maxWidth: 300 }}>
                        <Typography
                          variant="body2"
                          sx={{
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                          }}
                          title={sentence.text}
                        >
                          {sentence.text}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={sentence.language.toUpperCase()} size="small" />
                      </TableCell>
                      <TableCell>{formatDifficulty(sentence.difficulty_level)}</TableCell>
                      <TableCell>{formatStatus(sentence.status)}</TableCell>
                      <TableCell>{sentence.recording_count || 0}</TableCell>
                      <TableCell>
                        {new Date(sentence.created_at).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 0.5 }}>
                          <Tooltip title="Voir les détails">
                            <IconButton size="small" onClick={(e) => e.stopPropagation()}>
                              <ViewIcon />
                            </IconButton>
                          </Tooltip>
                          {canEdit && (
                            <Tooltip title={sentence.status === 'available' ? 'Désactiver' : 'Activer'}>
                              <IconButton
                                size="small"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleToggleStatus(sentence);
                                }}
                              >
                                {sentence.status === 'available' ? <InactiveIcon /> : <ActiveIcon />}
                              </IconButton>
                            </Tooltip>
                          )}
                          {canEdit && (
                            <Tooltip title="Modifier">
                              <IconButton
                                size="small"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleEditSentence(sentence);
                                }}
                              >
                                <EditIcon />
                              </IconButton>
                            </Tooltip>
                          )}
                          {canDelete && (
                            <Tooltip title="Supprimer">
                              <IconButton
                                size="small"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteSentence(sentence);
                                }}
                              >
                                <DeleteIcon />
                              </IconButton>
                            </Tooltip>
                          )}
                        </Box>
                      </TableCell>
                    </TableRow>
                  );
                })
            )}
          </TableBody>
        </Table>

        {/* Pagination */}
        {sentences && sentences.items.length > 0 && (
          <TablePagination
            rowsPerPageOptions={[10, 25, 50, 100]}
            component="div"
            count={sentences.total}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
            labelRowsPerPage="Lignes par page:"
            labelDisplayedRows={({ from, to, count }) =>
              `${from}-${to} sur ${count !== -1 ? count : `plus de ${to}`}`
            }
          />
        )}
      </TableContainer>

      {/* Dialogues */}
      <CreateSentenceDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSubmit={createSentence}
      />

      <EditSentenceDialog
        open={editDialogOpen}
        sentence={selectedSentence}
        onClose={() => {
          setEditDialogOpen(false);
          setSelectedSentence(null);
        }}
        onSubmit={updateSentence}
      />

      <BulkCreateSentencesDialog
        open={bulkCreateDialogOpen}
        onClose={() => setBulkCreateDialogOpen(false)}
        onSubmit={createSentencesBulk}
      />

      <ConfirmDialog
        open={deleteDialogOpen}
        title="Supprimer la phrase"
        message={`Êtes-vous sûr de vouloir supprimer la phrase "${sentenceToDelete?.text}" ? Cette action est irréversible.`}
        onConfirm={async () => {
          if (sentenceToDelete) {
            await deleteSentence(sentenceToDelete.id.toString());
            setDeleteDialogOpen(false);
            setSentenceToDelete(null);
          }
        }}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSentenceToDelete(null);
        }}
      />
    </Box>
  );
};

export default SentencesPage;
