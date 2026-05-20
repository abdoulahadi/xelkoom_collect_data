import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Sentence } from '../types';

interface CreateSentenceDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (sentence: Omit<Sentence, 'id' | 'created_at' | 'updated_at' | 'recording_count' | 'is_active'>) => Promise<void>;
}

const CreateSentenceDialog: React.FC<CreateSentenceDialogProps> = ({
  open,
  onClose,
  onSubmit,
}) => {
  const [formData, setFormData] = useState({
    text: '',
    language: 'wo',
    difficulty_level: 'easy',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | { target: { value: string } }) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value
    }));
  };

  const handleSubmit = async () => {
    if (!formData.text.trim()) {
      setError('Le texte de la phrase est obligatoire');
      return;
    }

    try {
      setSubmitting(true);
      setError(null);
      
      await onSubmit({
        text: formData.text.trim(),
        language: formData.language,
        difficulty_level: formData.difficulty_level as 'easy' | 'medium' | 'hard',
        status: 'available',
      });
      
      // Reset form
      setFormData({
        text: '',
        language: 'wo',
        difficulty_level: 'easy',
      });
      onClose();
    } catch (err) {
      setError('Erreur lors de la création de la phrase');
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!submitting) {
      setFormData({
        text: '',
        language: 'wo',
        difficulty_level: 'easy',
      });
      setError(null);
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Créer une nouvelle phrase</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
          {error && (
            <Alert severity="error">{error}</Alert>
          )}

          <TextField
            label="Texte de la phrase"
            multiline
            rows={3}
            value={formData.text}
            onChange={handleChange('text')}
            placeholder="Entrez le texte de la phrase en wolof..."
            required
            disabled={submitting}
            error={!formData.text.trim() && formData.text !== ''}
            helperText={
              !formData.text.trim() && formData.text !== '' 
                ? 'Le texte de la phrase est obligatoire'
                : `${formData.text.length}/1000 caractères`
            }
            inputProps={{ maxLength: 1000 }}
          />

          <FormControl disabled={submitting}>
            <InputLabel>Langue</InputLabel>
            <Select
              value={formData.language}
              label="Langue"
              onChange={handleChange('language')}
            >
              <MenuItem value="wo">Wolof</MenuItem>
              <MenuItem value="fr">Français</MenuItem>
              <MenuItem value="en">Anglais</MenuItem>
            </Select>
          </FormControl>

          <FormControl disabled={submitting}>
            <InputLabel>Niveau de difficulté</InputLabel>
            <Select
              value={formData.difficulty_level}
              label="Niveau de difficulté"
              onChange={handleChange('difficulty_level')}
            >
              <MenuItem value="easy">Facile</MenuItem>
              <MenuItem value="medium">Moyen</MenuItem>
              <MenuItem value="hard">Difficile</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={submitting}>
          Annuler
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={submitting || !formData.text.trim()}
          startIcon={submitting ? <CircularProgress size={16} /> : null}
        >
          {submitting ? 'Création...' : 'Créer'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CreateSentenceDialog;
