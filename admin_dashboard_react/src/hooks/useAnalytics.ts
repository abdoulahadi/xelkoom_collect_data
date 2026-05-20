import { useState, useEffect, useCallback, useRef } from 'react';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';
import { DashboardMetrics } from '../types';
import toast from 'react-hot-toast';

interface UseAnalyticsReturn {
  metrics: DashboardMetrics | null;
  loading: boolean;
  error: string | null;
  refreshing: boolean;
  lastUpdated: Date | null;
  fetchMetrics: (showToast?: boolean) => Promise<void>;
  refresh: () => void;
}

/**
 * Custom hook for managing analytics data
 * Handles fetching, caching, error states, and refresh functionality
 */
export const useAnalytics = (period?: string): UseAnalyticsReturn => {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const hasInitialized = useRef(false);
  const periodRef = useRef(period);
  periodRef.current = period;

  const fetchMetrics = useCallback(async (showToast = false) => {
    try {
      setError(null);
      
      // Only set loading to true on initial load
      if (!hasInitialized.current) {
        setLoading(true);
      } else {
        setRefreshing(true);
      }
      
      const data = await apiService.getAnalytics(periodRef.current);
      setMetrics(data);
      setLastUpdated(new Date());
      hasInitialized.current = true;
      
      if (showToast) {
        toast.success('Données mises à jour avec succès');
      }
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors du chargement des analytics');
      setError(errorMessage);
      
      if (showToast) {
        toast.error(errorMessage);
      }
      
      console.error('Analytics fetch error:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []); // Pas de dépendances pour éviter les re-renders en boucle

  const refresh = useCallback(() => {
    fetchMetrics(true);
  }, [fetchMetrics]);

  // Initial fetch on mount - seulement une fois au montage
  useEffect(() => {
    fetchMetrics();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ADM-006: Re-fetch when period changes
  useEffect(() => {
    if (hasInitialized.current) {
      fetchMetrics();
    }
  }, [period]); // eslint-disable-line react-hooks/exhaustive-deps

  return {
    metrics,
    loading,
    error,
    refreshing,
    lastUpdated,
    fetchMetrics,
    refresh,
  };
};
