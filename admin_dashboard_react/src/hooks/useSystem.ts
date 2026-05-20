import { useState, useEffect, useCallback } from 'react';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';
import { SystemHealth, SystemConfig, SystemLog, PaginatedResponse } from '../types';

interface UseSystemReturn {
  health: SystemHealth | null;
  config: SystemConfig | null;
  logs: PaginatedResponse<SystemLog> | null;
  loading: boolean;
  error: string | null;
  refreshHealth: () => Promise<void>;
  refreshConfig: () => Promise<void>;
  fetchLogs: (page?: number, level?: string) => Promise<void>;
}

export const useSystem = (): UseSystemReturn => {
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [config, setConfig] = useState<SystemConfig | null>(null);
  const [logs, setLogs] = useState<PaginatedResponse<SystemLog> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshHealth = useCallback(async () => {
    try {
      setError(null);
      const data = await apiService.getSystemHealth();
      setHealth(data);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors du chargement de l\'état système');
      setError(errorMessage);
      console.error('System health error:', err);
    }
  }, []);

  const refreshConfig = useCallback(async () => {
    try {
      setError(null);
      const data = await apiService.getSystemConfig();
      setConfig(data);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors du chargement de la configuration');
      setError(errorMessage);
      console.error('System config error:', err);
    }
  }, []);

  const fetchLogs = useCallback(async (page = 1, level?: string) => {
    try {
      setError(null);
      const data = await apiService.getSystemLogs(page, 50, level);
      setLogs(data);
    } catch (err: unknown) {
      const errorMessage = getErrorMessage(err, 'Erreur lors du chargement des logs');
      setError(errorMessage);
      console.error('System logs error:', err);
    }
  }, []);

  const initializeData = useCallback(async () => {
    setLoading(true);
    try {
      await Promise.all([
        refreshHealth(),
        refreshConfig(),
        fetchLogs(1)
      ]);
    } catch (err) {
      console.error('Failed to initialize system data:', err);
    } finally {
      setLoading(false);
    }
  }, [refreshHealth, refreshConfig, fetchLogs]);

  useEffect(() => {
    initializeData();
  }, [initializeData]);

  return {
    health,
    config,
    logs,
    loading,
    error,
    refreshHealth,
    refreshConfig,
    fetchLogs,
  };
};
