/// <reference types="vite/client" />

import axios, { AxiosInstance, AxiosResponse } from 'axios';
import {
  User,
  Recording,
  Sentence,
  DashboardMetrics,
  LoginCredentials,
  AuthResponse,
  PaginatedResponse,
  UsersPaginatedResponse,
  SentencesPaginatedResponse,
  RecordingFilters,
  UserFilters,
  ExportOptions,
  SystemHealth,
  SystemConfig,
  SystemLog,
  BalanceConfig,
  DetailedRecordingDistribution,
  RecordingDistributionStats,
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

class ApiService {
  private api: AxiosInstance;
  private token: string | null = null;

  constructor() {
    this.api = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add request interceptor to include auth token
    this.api.interceptors.request.use(
      (config) => {
        if (this.token) {
          config.headers.Authorization = `Bearer ${this.token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Add response interceptor to handle errors
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Token expired or invalid
          this.logout();
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );

    // Initialize token from sessionStorage
    // SEC-009: Use sessionStorage instead of localStorage to reduce XSS token theft window
    this.token = sessionStorage.getItem('admin_token');
  }

  // Auth methods
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    // Envoyer les credentials complètes (username + password)
    const response: AxiosResponse<AuthResponse> = await this.api.post('/auth/login', {
      username: credentials.username,
      password: credentials.password
    });
    this.token = response.data.access_token;
    sessionStorage.setItem('admin_token', this.token);
    return response.data;
  }

  logout(): void {
    this.token = null;
    sessionStorage.removeItem('admin_token');
  }

  async getCurrentUser(): Promise<User> {
    const response: AxiosResponse<User> = await this.api.get('/auth/me');
    return response.data;
  }

  // Dashboard methods
  async getDashboardMetrics(): Promise<DashboardMetrics> {
    const response: AxiosResponse<DashboardMetrics> = await this.api.get('/admin/stats');
    return response.data;
  }

  // User management methods
  async getUsers(filters?: UserFilters, page = 1, size = 50): Promise<UsersPaginatedResponse> {
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('size', size.toString());
    
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params.append(key, value.toString());
        }
      });
    }
    
    const response: AxiosResponse<UsersPaginatedResponse> = await this.api.get(`/admin/users?${params}`);
    return response.data;
  }

  async getUserById(userId: string): Promise<User> {
    const response: AxiosResponse<User> = await this.api.get(`/admin/users/${userId}`);
    return response.data;
  }

  async updateUser(userId: string, updates: Partial<User>): Promise<User> {
    const response: AxiosResponse<User> = await this.api.patch(`/admin/users/${userId}`, updates);
    return response.data;
  }

  async deleteUser(userId: string): Promise<void> {
    await this.api.delete(`/admin/users/${userId}`);
  }

  async activateUser(userId: string): Promise<User> {
    const response: AxiosResponse<User> = await this.api.post(`/admin/users/${userId}/activate`);
    return response.data;
  }

  async deactivateUser(userId: string): Promise<User> {
    const response: AxiosResponse<User> = await this.api.post(`/admin/users/${userId}/deactivate`);
    return response.data;
  }

  async createUser(userData: Omit<User, 'id' | 'created_at' | 'updated_at' | 'recording_count' | 'validated_recordings'>): Promise<User> {
    const response: AxiosResponse<User> = await this.api.post('/admin/users', userData);
    return response.data;
  }

  // Recording management methods
  async getRecordings(filters?: RecordingFilters, page = 1, size = 50): Promise<PaginatedResponse<Recording>> {
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('size', size.toString());
    
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params.append(key, value.toString());
        }
      });
    }
    
    const response: AxiosResponse<PaginatedResponse<Recording>> = await this.api.get(`/admin/recordings?${params}`);
    return response.data;
  }

  async getRecordingById(recordingId: string): Promise<Recording> {
    const response: AxiosResponse<Recording> = await this.api.get(`/admin/recordings/${recordingId}`);
    return response.data;
  }

  async moderateRecording(
    recordingId: string,
    status: Recording['status'],
    notes?: string
  ): Promise<Recording> {
    const response: AxiosResponse<Recording> = await this.api.put(`/admin/recordings/${recordingId}`, {
      status,
      admin_notes: notes,
    });
    return response.data;
  }

  async bulkModerateRecordings(
    recordingIds: string[],
    status: Recording['status'],
    notes?: string
  ): Promise<Recording[]> {
    const response: AxiosResponse<Recording[]> = await this.api.post('/admin/recordings/bulk-moderate', {
      recording_ids: recordingIds,
      status,
      notes,
    });
    return response.data;
  }

  async deleteRecording(recordingId: string): Promise<void> {
    await this.api.delete(`/admin/recordings/${recordingId}`);
  }

  async getRecordingAudioUrl(recordingId: string): Promise<string> {
    const response = await this.api.get(`/admin/recordings/${recordingId}/audio`, {
      responseType: 'blob',
    });
    return URL.createObjectURL(response.data);
  }

  // Sentence management methods
  async getSentences(page = 1, size = 50, statusFilter?: string, search?: string, difficulty?: string): Promise<SentencesPaginatedResponse> {
    const skip = (page - 1) * size;
    let url = `/admin/sentences?skip=${skip}&limit=${size}`;
    
    if (statusFilter) {
      url += `&status_filter=${statusFilter}`;
    }
    if (search) {
      url += `&search=${encodeURIComponent(search)}`;
    }
    if (difficulty) {
      url += `&difficulty=${encodeURIComponent(difficulty)}`;
    }
    
    const response: AxiosResponse<SentencesPaginatedResponse> = await this.api.get(url);
    return response.data;
  }

  async createSentence(sentence: Omit<Sentence, 'id' | 'created_at' | 'updated_at' | 'recording_count' | 'status'>): Promise<Sentence> {
    const response: AxiosResponse<Sentence> = await this.api.post('/admin/sentences', sentence);
    return response.data;
  }

  async createSentencesBulk(sentences: string[]): Promise<Sentence[]> {
    const response: AxiosResponse<Sentence[]> = await this.api.post('/admin/sentences/bulk', {
      sentences
    });
    return response.data;
  }

  async updateSentence(sentenceId: string, updates: Partial<Sentence>): Promise<Sentence> {
    const response: AxiosResponse<Sentence> = await this.api.put(`/admin/sentences/${sentenceId}`, updates);
    return response.data;
  }

  async deleteSentence(sentenceId: string): Promise<void> {
    await this.api.delete(`/admin/sentences/${sentenceId}`);
  }

  async importSentences(file: File): Promise<{ imported: number; errors: string[] }> {
    const formData = new FormData();
    formData.append('file', file);
    
    const response: AxiosResponse<{ imported: number; errors: string[] }> = await this.api.post(
      '/admin/sentences/import',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );
    return response.data;
  }

  // Export methods
  async exportRecordings(options: ExportOptions): Promise<Blob> {
    const response = await this.api.post('/admin/export/recordings', options, {
      responseType: 'blob',
    });
    return response.data;
  }

  async exportUsers(format: 'json' | 'csv' = 'csv'): Promise<Blob> {
    const response = await this.api.get(`/admin/export/users?format=${format}`, {
      responseType: 'blob',
    });
    return response.data;
  }

  // Analytics methods
  async getAnalytics(period?: string): Promise<DashboardMetrics> {
    const params = period ? { period } : {};
    const response = await this.api.get('/admin/stats', { params });
    return response.data;
  }

  // System methods
  async getSystemHealth(): Promise<SystemHealth> {
    const response = await this.api.get('/admin/system/health');
    return response.data;
  }

  async getSystemConfig(): Promise<SystemConfig> {
    const response = await this.api.get('/admin/system/config');
    return response.data;
  }

  async getSystemLogs(page = 1, size = 100, level?: string): Promise<PaginatedResponse<SystemLog>> {
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('size', size.toString());
    if (level) {
      params.append('level', level);
    }
    
    const response = await this.api.get(`/admin/system/logs?${params}`);
    return response.data;
  }

  // Balance and distribution methods
  async getBalanceConfig(): Promise<BalanceConfig> {
    const response = await this.api.get('/admin/balance-config');
    return response.data;
  }

  async getRecordingDistribution(): Promise<DetailedRecordingDistribution> {
    const response = await this.api.get('/admin/recording-distribution');
    return response.data;
  }

  async getRecordingDistributionStats(): Promise<RecordingDistributionStats> {
    const response = await this.api.get('/admin/sentences/distribution-stats');
    return response.data;
  }

  // Utility method to check if user is authenticated
  isAuthenticated(): boolean {
    return !!this.token;
  }
}

export const apiService = new ApiService();
export default apiService;
