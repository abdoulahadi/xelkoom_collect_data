import { useState, useEffect, useCallback } from 'react';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';
import { Sentence, SentencesPaginatedResponse } from '../types';
import toast from 'react-hot-toast';

interface UseSentencesFilters {
  status?: string;
  difficulty?: string;
  search?: string;
}

interface UseSentencesReturn {
  sentences: SentencesPaginatedResponse | null;
  loading: boolean;
  error: string | null;
  filters: UseSentencesFilters;
  setFilters: (filters: UseSentencesFilters) => void;
  fetchSentences: (page?: number) => Promise<void>;
  createSentence: (sentence: Omit<Sentence, 'id' | 'created_at' | 'updated_at' | 'recording_count' | 'status' | 'validated_recordings' | 'pending_recordings' | 'rejected_recordings'>) => Promise<void>;
  createSentencesBulk: (sentences: string[]) => Promise<void>;
  updateSentence: (id: string, updates: Partial<Sentence>) => Promise<void>;
  deleteSentence: (id: string) => Promise<void>;
  refreshSentences: () => Promise<void>;
}

export const useSentences = (): UseSentencesReturn => {
  const [sentences, setSentences] = useState<SentencesPaginatedResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<UseSentencesFilters>({});

  const fetchSentences = useCallback(async (page = 1) => {
    try {
      setError(null);
      if (page === 1) setLoading(true);
      
      const data = await apiService.getSentences(page, 50, filters.status, filters.search, filters.difficulty);
      
      setSentences(data);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors du chargement des phrases');
      setError(errorMessage);
      console.error('Sentences fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, [filters]);

  const createSentence = useCallback(async (sentenceData: Omit<Sentence, 'id' | 'created_at' | 'updated_at' | 'recording_count' | 'status' | 'validated_recordings' | 'pending_recordings' | 'rejected_recordings'>) => {
    try {
      await apiService.createSentence(sentenceData);
      toast.success('Phrase créée avec succès');
      await fetchSentences(1);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors de la création de la phrase');
      toast.error(errorMessage);
      throw err;
    }
  }, [fetchSentences]);

  const createSentencesBulk = useCallback(async (sentencesTexts: string[]) => {
    try {
      const result = await apiService.createSentencesBulk(sentencesTexts);
      toast.success(`${result.length} phrases créées avec succès`);
      await fetchSentences(1);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors de la création des phrases');
      toast.error(errorMessage);
      throw err;
    }
  }, [fetchSentences]);

  const updateSentence = useCallback(async (id: string, updates: Partial<Sentence>) => {
    try {
      await apiService.updateSentence(id, updates);
      toast.success('Phrase mise à jour avec succès');
      await fetchSentences(sentences?.page || 1);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors de la mise à jour de la phrase');
      toast.error(errorMessage);
      throw err;
    }
  }, [fetchSentences, sentences?.page]);

  const deleteSentence = useCallback(async (id: string) => {
    try {
      await apiService.deleteSentence(id);
      toast.success('Phrase supprimée avec succès');
      await fetchSentences(sentences?.page || 1);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors de la suppression de la phrase');
      toast.error(errorMessage);
      throw err;
    }
  }, [fetchSentences, sentences?.page]);

  const refreshSentences = useCallback(async () => {
    await fetchSentences(sentences?.page || 1);
  }, [fetchSentences, sentences?.page]);

  useEffect(() => {
    fetchSentences(1);
  }, [filters]);

  return {
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
  };
};
