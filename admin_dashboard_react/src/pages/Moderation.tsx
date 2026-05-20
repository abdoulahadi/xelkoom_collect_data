import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
  Card,
  CardContent,
  CardActions,
  Grid,
  Chip,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Pagination,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  PlayArrow,
  Pause,
  CheckCircle,
  Cancel,
  VolumeUp,
  Person,
  Schedule,
  GraphicEq,
  FileUpload,
  FilterList,
  Refresh,
  Info,
} from '@mui/icons-material';
import { Recording, PaginatedResponse, RecordingFilters } from '../types';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';

const Moderation: React.FC = () => {
  const [recordings, setRecordings] = useState<Recording[]>([]);
  const [loading, setLoading] = useState(true);
  const [totalRecordings, setTotalRecordings] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize] = useState(10);
  const [filters, setFilters] = useState<RecordingFilters>({ status: 'pending' });
  const [selectedRecording, setSelectedRecording] = useState<Recording | null>(null);
  const [moderationDialog, setModerationDialog] = useState(false);
  const [moderationNotes, setModerationNotes] = useState('');
  const [playingRecording, setPlayingRecording] = useState<string | null>(null);
  const [audioProgress, setAudioProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [selectedRecordings, setSelectedRecordings] = useState<Set<string>>(new Set());
  const [bulkAction, setBulkAction] = useState<Recording['status'] | ''>('');
  const [stats, setStats] = useState({ pending: 0, validated: 0, rejected: 0 });
  
  const audioRef = useRef<HTMLAudioElement>(null);
  const progressInterval = useRef<number | null>(null);

  useEffect(() => {
    setCurrentPage(1); // Reset to first page when filters change
  }, [filters]);

  useEffect(() => {
    fetchRecordings();
    fetchStats();
  }, [currentPage, filters]);

  // Cleanup function
  useEffect(() => {
    return () => {
      if (progressInterval.current) {
        clearInterval(progressInterval.current);
      }
      if (audioRef.current) {
        audioRef.current.pause();
      }
    };
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyPress = (event: KeyboardEvent) => {
      if (event.ctrlKey || event.metaKey) {
        switch (event.key) {
          case 'r':
            event.preventDefault();
            fetchRecordings();
            break;
        }
      }
      
      // Space bar to play/pause audio
      if (event.code === 'Space' && playingRecording && 
          event.target && 
          (event.target as HTMLElement).tagName !== 'INPUT' && 
          (event.target as HTMLElement).tagName !== 'TEXTAREA') {
        event.preventDefault();
        if (audioRef.current) {
          if (audioRef.current.paused) {
            audioRef.current.play();
          } else {
            audioRef.current.pause();
          }
        }
      }
    };

    document.addEventListener('keydown', handleKeyPress);
    return () => document.removeEventListener('keydown', handleKeyPress);
  }, [playingRecording]);

  const fetchRecordings = async () => {
    try {
      setLoading(true);
      setError(null);
      const response: PaginatedResponse<Recording> = await apiService.getRecordings(
        filters,
        currentPage,
        pageSize
      );
      setRecordings(response.items || []);
      setTotalRecordings(response.total || 0);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors du chargement des enregistrements'));
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      // Fetch stats for each status
      const [pendingRes, validatedRes, rejectedRes] = await Promise.all([
        apiService.getRecordings({ status: 'pending' }, 1, 1),
        apiService.getRecordings({ status: 'validated' }, 1, 1),
        apiService.getRecordings({ status: 'rejected' }, 1, 1)
      ]);
      
      setStats({
        pending: pendingRes?.total || 0,
        validated: validatedRes?.total || 0,
        rejected: rejectedRes?.total || 0
      });
    } catch (err) {
      console.error('Error fetching stats:', err);
      // Set default values on error
      setStats({
        pending: 0,
        validated: 0,
        rejected: 0
      });
    }
  };

  const handlePlayAudio = async (recording: Recording) => {
    try {
      if (playingRecording === recording.id.toString()) {
        // Pause current audio
        if (audioRef.current) {
          if (audioRef.current.paused) {
            audioRef.current.play();
          } else {
            audioRef.current.pause();
          }
        }
        return;
      }

      // Stop any currently playing audio
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.currentTime = 0;
      }

      // Load and play new audio
      const audioUrl = await apiService.getRecordingAudioUrl(recording.id.toString());
      if (audioRef.current) {
        audioRef.current.src = audioUrl;
        audioRef.current.load();
        
        const playPromise = audioRef.current.play();
        if (playPromise !== undefined) {
          playPromise.then(() => {
            setPlayingRecording(recording.id.toString());
          }).catch(error => {
            console.error('Error playing audio:', error);
            setError('Erreur lors de la lecture audio');
          });
        }
        
        // Update progress
        if (progressInterval.current) {
          clearInterval(progressInterval.current);
        }
        
        progressInterval.current = window.setInterval(() => {
          if (audioRef.current && audioRef.current.duration) {
            const progress = (audioRef.current.currentTime / audioRef.current.duration) * 100;
            setAudioProgress(progress || 0);
          }
        }, 100);
      }
    } catch (err) {
      console.error('Error in handlePlayAudio:', err);
      setError('Erreur lors de la lecture audio');
    }
  };

  const handleAudioEnded = () => {
    setPlayingRecording(null);
    setAudioProgress(0);
    if (progressInterval.current) {
      clearInterval(progressInterval.current);
    }
  };

  const handleModerateRecording = async (recording: Recording, status: Recording['status']) => {
    setSelectedRecording(recording);
    if (status === 'rejected') {
      setModerationDialog(true);
    } else {
      await submitModeration(recording, status, '');
    }
  };

  const submitModeration = async (recording: Recording, status: Recording['status'], notes: string) => {
    try {
      await apiService.moderateRecording(recording.id.toString(), status, notes);
      setSuccess(`Enregistrement ${status === 'validated' ? 'validé' : 'rejeté'} avec succès`);
      setModerationDialog(false);
      setModerationNotes('');
      setSelectedRecording(null);
      fetchRecordings();
      fetchStats(); // Refresh stats after moderation
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors de la modération'));
    }
  };

  const handleBulkModeration = async () => {
    if (selectedRecordings.size === 0 || !bulkAction) return;
    
    try {
      await apiService.bulkModerateRecordings(
        Array.from(selectedRecordings),
        bulkAction as Recording['status'],
        ''
      );
      setSuccess(`${selectedRecordings.size} enregistrement(s) ${bulkAction === 'validated' ? 'validé(s)' : 'rejeté(s)'} avec succès`);
      setSelectedRecordings(new Set());
      setBulkAction('');
      fetchRecordings();
      fetchStats(); // Refresh stats after bulk moderation
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors de la modération en lot'));
    }
  };

  const toggleRecordingSelection = (recordingId: string) => {
    const newSelection = new Set(selectedRecordings);
    if (newSelection.has(recordingId)) {
      newSelection.delete(recordingId);
    } else {
      newSelection.add(recordingId);
    }
    setSelectedRecordings(newSelection);
  };

  const formatDuration = (duration?: number) => {
    if (!duration) return 'N/A';
    const minutes = Math.floor(duration / 60);
    const seconds = Math.floor(duration % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  const formatFileSize = (size?: number) => {
    if (!size) return 'N/A';
    if (size < 1024) return `${size} B`;
    if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
    return `${(size / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getStatusColor = (status: Recording['status']) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'validated': return 'success';
      case 'rejected': return 'error';
      default: return 'default';
    }
  };

  const getStatusLabel = (status: Recording['status']) => {
    switch (status) {
      case 'pending': return 'En attente';
      case 'validated': return 'Validé';
      case 'rejected': return 'Rejeté';
      default: return status;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <audio ref={audioRef} onEnded={handleAudioEnded} />
      
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={700} gutterBottom>
          Modération des enregistrements
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
          Validez ou rejetez les enregistrements audio soumis par les utilisateurs
        </Typography>
        
        {/* Quick Stats */}
        <Grid container spacing={2} sx={{ mt: 2 }}>
          <Grid item xs={12} sm={4}>
            <Paper sx={{ p: 2, textAlign: 'center', cursor: 'pointer' }} onClick={() => setFilters({ ...filters, status: 'pending' })}>
              <Typography variant="h4" color="warning.main" fontWeight="bold">
                {stats.pending}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                En attente
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Paper sx={{ p: 2, textAlign: 'center', cursor: 'pointer' }} onClick={() => setFilters({ ...filters, status: 'validated' })}>
              <Typography variant="h4" color="success.main" fontWeight="bold">
                {stats.validated}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Validés
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Paper sx={{ p: 2, textAlign: 'center', cursor: 'pointer' }} onClick={() => setFilters({ ...filters, status: 'rejected' })}>
              <Typography variant="h4" color="error.main" fontWeight="bold">
                {stats.rejected}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Rejetés
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <FilterList sx={{ mr: 1 }} />
          <Typography variant="h6">Filtres</Typography>
        </Box>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Statut</InputLabel>
              <Select
                value={filters.status || ''}
                onChange={(e) => setFilters({ ...filters, status: e.target.value as Recording['status'] || undefined })}
                label="Statut"
              >
                <MenuItem value="">Tous</MenuItem>
                <MenuItem value="pending">En attente</MenuItem>
                <MenuItem value="validated">Validé</MenuItem>
                <MenuItem value="rejected">Rejeté</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              fullWidth
              size="small"
              label="Date de début"
              type="date"
              value={filters.date_from || ''}
              onChange={(e) => setFilters({ ...filters, date_from: e.target.value || undefined })}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              fullWidth
              size="small"
              label="Date de fin"
              type="date"
              value={filters.date_to || ''}
              onChange={(e) => setFilters({ ...filters, date_to: e.target.value || undefined })}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Button
              variant="outlined"
              startIcon={<Refresh />}
              onClick={fetchRecordings}
              fullWidth
            >
              Actualiser
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Bulk Actions */}
      {selectedRecordings.size > 0 && (
        <Paper sx={{ p: 2, mb: 3, backgroundColor: 'action.hover' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Typography variant="body2">
              {selectedRecordings.size} enregistrement(s) sélectionné(s)
            </Typography>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <Select
                value={bulkAction}
                onChange={(e) => setBulkAction(e.target.value as Recording['status'])}
                displayEmpty
              >
                <MenuItem value="">Action en lot</MenuItem>
                <MenuItem value="validated">Valider</MenuItem>
                <MenuItem value="rejected">Rejeter</MenuItem>
              </Select>
            </FormControl>
            <Button
              variant="contained"
              size="small"
              onClick={handleBulkModeration}
              disabled={!bulkAction}
            >
              Appliquer
            </Button>
            <Button
              variant="text"
              size="small"
              onClick={() => setSelectedRecordings(new Set())}
            >
              Annuler
            </Button>
          </Box>
        </Paper>
      )}

      {/* Alerts */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}
      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      {/* Recordings List */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : !recordings || recordings.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="text.secondary">
            Aucun enregistrement trouvé
          </Typography>
        </Paper>
      ) : (
        <Grid container spacing={2}>
          {recordings.map((recording) => (
            <Grid item xs={12} key={recording.id}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', mb: 2 }}>
                    <Box sx={{ flexGrow: 1 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <Typography variant="h6" sx={{ mr: 2 }}>
                          Enregistrement #{recording.id}
                        </Typography>
                        <Chip
                          label={getStatusLabel(recording.status)}
                          color={getStatusColor(recording.status)}
                          size="small"
                        />
                        <Box sx={{ ml: 'auto' }}>
                          <input
                            type="checkbox"
                            checked={selectedRecordings.has(recording.id.toString())}
                            onChange={() => toggleRecordingSelection(recording.id.toString())}
                          />
                        </Box>
                      </Box>
                      
                      {recording.sentence?.text && (
                        <Typography variant="body1" sx={{ mb: 2, p: 2, backgroundColor: 'action.hover', borderRadius: 1 }}>
                          "{recording.sentence.text}"
                        </Typography>
                      )}

                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mb: 2 }}>
                        {recording.user?.username && (
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Person sx={{ mr: 0.5, fontSize: 16 }} />
                            <Typography variant="body2">
                              {recording.user.username}
                            </Typography>
                          </Box>
                        )}
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Schedule sx={{ mr: 0.5, fontSize: 16 }} />
                          <Typography variant="body2">
                            {formatDuration(recording.duration)}
                          </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <FileUpload sx={{ mr: 0.5, fontSize: 16 }} />
                          <Typography variant="body2">
                            {formatFileSize(recording.file_size)}
                          </Typography>
                        </Box>
                        {recording.sample_rate && (
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <GraphicEq sx={{ mr: 0.5, fontSize: 16 }} />
                            <Typography variant="body2">
                              {recording.sample_rate} Hz
                            </Typography>
                          </Box>
                        )}
                      </Box>

                      {recording.audio_metadata && 
                       typeof recording.audio_metadata === 'object' && 
                       recording.audio_metadata !== null && 
                       Object.keys(recording.audio_metadata).length > 0 && (
                        <Box sx={{ mb: 2 }}>
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            Métadonnées audio:
                          </Typography>
                          <Box sx={{ p: 1, backgroundColor: 'grey.100', borderRadius: 1, maxHeight: 120, overflow: 'auto' }}>
                            <Typography variant="caption" component="pre" sx={{ fontSize: '0.75rem' }}>
                              {JSON.stringify(recording.audio_metadata, null, 2)}
                            </Typography>
                          </Box>
                        </Box>
                      )}

                      {recording.admin_notes && (
                        <Box sx={{ mb: 2 }}>
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            Notes de modération:
                          </Typography>
                          <Typography variant="body2" sx={{ p: 1, backgroundColor: 'warning.light', borderRadius: 1 }}>
                            {recording.admin_notes}
                          </Typography>
                        </Box>
                      )}
                    </Box>
                  </Box>

                  {/* Audio Player */}
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2, p: 2, backgroundColor: 'action.hover', borderRadius: 1 }}>
                    <IconButton
                      onClick={() => handlePlayAudio(recording)}
                      color="primary"
                      size="large"
                    >
                      {playingRecording === recording.id.toString() ? <Pause /> : <PlayArrow />}
                    </IconButton>
                    <VolumeUp sx={{ mr: 1 }} />
                    <Box sx={{ flexGrow: 1, mx: 2 }}>
                      <Box
                        sx={{
                          height: 4,
                          backgroundColor: 'grey.300',
                          borderRadius: 2,
                          overflow: 'hidden',
                        }}
                      >
                        <Box
                          sx={{
                            height: '100%',
                            backgroundColor: 'primary.main',
                            width: `${playingRecording === recording.id.toString() ? audioProgress : 0}%`,
                            transition: 'width 0.1s',
                          }}
                        />
                      </Box>
                    </Box>
                    <Typography variant="caption" color="text.secondary">
                      {new Date(recording.created_at).toLocaleDateString()}
                    </Typography>
                  </Box>
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    {recording.status === 'pending' && (
                      <>
                        <Button
                          variant="contained"
                          color="success"
                          startIcon={<CheckCircle />}
                          onClick={() => handleModerateRecording(recording, 'validated')}
                          sx={{ mr: 1 }}
                        >
                          Valider
                        </Button>
                        <Button
                          variant="contained"
                          color="error"
                          startIcon={<Cancel />}
                          onClick={() => handleModerateRecording(recording, 'rejected')}
                        >
                          Rejeter
                        </Button>
                      </>
                    )}
                  </Box>
                  <Tooltip title="Informations détaillées">
                    <IconButton size="small">
                      <Info />
                    </IconButton>
                  </Tooltip>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Pagination */}
      {totalRecordings > pageSize && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={Math.ceil(totalRecordings / pageSize)}
            page={currentPage}
            onChange={(_, page) => setCurrentPage(page)}
            color="primary"
          />
        </Box>
      )}

      {/* Moderation Dialog */}
      <Dialog open={moderationDialog} onClose={() => setModerationDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          Rejeter l'enregistrement
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Veuillez indiquer la raison du rejet de cet enregistrement.
          </Typography>
          <TextField
            autoFocus
            margin="dense"
            label="Notes de modération"
            multiline
            rows={4}
            fullWidth
            variant="outlined"
            value={moderationNotes}
            onChange={(e) => setModerationNotes(e.target.value)}
            placeholder="Ex: Qualité audio insuffisante, bruit de fond, mauvaise prononciation..."
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setModerationDialog(false)}>
            Annuler
          </Button>
          <Button
            onClick={() => selectedRecording && submitModeration(selectedRecording, 'rejected', moderationNotes)}
            color="error"
            variant="contained"
          >
            Rejeter
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Moderation;
