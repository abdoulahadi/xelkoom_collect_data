import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Box,
  Alert,
  CircularProgress,
  Typography,
  Divider,
} from '@mui/material';

interface BulkCreateSentencesDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (sentences: string[]) => Promise<void>;
}

const BulkCreateSentencesDialog: React.FC<BulkCreateSentencesDialogProps> = ({
  open,
  onClose,
  onSubmit,
}) => {
  const [text, setText] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!text.trim()) {
      setError('Veuillez entrer au moins une phrase');
      return;
    }

    const sentences = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0);

    if (sentences.length === 0) {
      setError('Aucune phrase valide trouvée');
      return;
    }

    try {
      setSubmitting(true);
      setError(null);
      
      await onSubmit(sentences);
      
      // Reset form
      setText('');
      onClose();
    } catch (err) {
      setError('Erreur lors de la création des phrases');
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!submitting) {
      setText('');
      setError(null);
      onClose();
    }
  };

  const sentenceCount = text
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 0).length;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Créer plusieurs phrases</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
          {error && (
            <Alert severity="error">{error}</Alert>
          )}

          <Alert severity="info">
            <Typography variant="body2">
              Entrez une phrase par ligne. Toutes les phrases seront créées avec les paramètres par défaut :
            </Typography>
            <ul style={{ marginTop: 8, marginBottom: 0 }}>
              <li>Langue : Wolof</li>
              <li>Difficulté : Facile</li>
              <li>Statut : Actif</li>
            </ul>
          </Alert>

          <TextField
            label="Phrases (une par ligne)"
            multiline
            rows={10}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Première phrase&#10;Deuxième phrase&#10;Troisième phrase&#10;..."
            required
            disabled={submitting}
            fullWidth
          />

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="body2" color="textSecondary">
              {sentenceCount} phrase{sentenceCount !== 1 ? 's' : ''} à créer
            </Typography>
            <Typography variant="body2" color="textSecondary">
              {text.length} caractères
            </Typography>
          </Box>

          <Divider />

          <Box>
            <Typography variant="subtitle2" gutterBottom>
              Format d'importation supporté :
            </Typography>
            <Typography variant="body2" color="textSecondary">
              • Texte brut (une phrase par ligne)
            </Typography>
            <Typography variant="body2" color="textSecondary">
              • Les lignes vides seront ignorées
            </Typography>
            <Typography variant="body2" color="textSecondary">
              • Maximum 1000 caractères par phrase
            </Typography>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={submitting}>
          Annuler
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={submitting || sentenceCount === 0}
          startIcon={submitting ? <CircularProgress size={16} /> : null}
        >
          {submitting ? 'Création...' : `Créer ${sentenceCount} phrase${sentenceCount !== 1 ? 's' : ''}`}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default BulkCreateSentencesDialog;
