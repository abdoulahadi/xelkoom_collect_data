export interface User {
  id: string;
  username: string;
  gender: 'male' | 'female' | 'other';
  age_range: string;
  is_admin: boolean;
  role: 'admin' | 'moderator' | 'user';
  is_active: boolean;
  consent_given: boolean;
  created_at: string;
  updated_at: string | null;
  recording_count: number;
  validated_recordings: number;
}

export interface Sentence {
  id: string;
  text: string;
  language: string;
  difficulty_level: 'easy' | 'medium' | 'hard';
  status: 'available' | 'assigned' | 'completed';
  created_at: string;
  updated_at: string | null;
  recording_count?: number;
  validated_recordings?: number;
  pending_recordings?: number;
  rejected_recordings?: number;
}

export interface Recording {
  id: string;
  user_id: string;
  sentence_id: string;
  filepath: string;
  original_filename?: string;
  duration?: number;
  file_size?: number;
  sample_rate?: number;
  status: 'pending' | 'validated' | 'rejected';
  quality_score?: number;
  admin_notes?: string;
  audio_metadata?: Record<string, string | number | boolean>;
  created_at: string;
  updated_at: string | null;
  // Relations
  user?: User;
  sentence?: Sentence;
}

export interface ModerationStats {
  total_recordings: number;
  pending_recordings: number;
  approved_recordings: number;
  rejected_recordings: number;
  needs_review_recordings: number;
  average_quality_score: number;
  moderation_rate: number;
}

export interface UserStats {
  total_users: number;
  active_users: number;
  new_users_today: number;
  new_users_this_week: number;
  new_users_this_month: number;
  users_by_gender: {
    male: number;
    female: number;
    other: number;
  };
  users_by_age_range: Record<string, number>;
}

export interface AudioStats {
  total_recordings: number;
  total_duration: number; // in seconds
  approved_recordings: number;
  average_quality_score: number;
  recordings_by_language: Record<string, number>;
  recordings_by_category: Record<string, number>;
  daily_recordings: Array<{
    date: string;
    count: number;
  }>;
}

export interface SystemStats {
  server_uptime: number;
  storage_used: number; // in bytes
  storage_available: number; // in bytes
  database_size: number; // in bytes
  active_sessions: number;
  api_requests_today: number;
  error_rate: number;
}

export interface DashboardMetrics {
  total_users: number;
  active_users: number;
  total_sentences: number;
  available_sentences: number;
  total_recordings: number;
  pending_recordings: number;
  validated_recordings: number;
  rejected_recordings: number;
  total_audio_duration: number;
  daily_recordings: Array<{
    date: string;
    count: number;
  }>;
}

export interface SystemHealth {
  status: 'healthy' | 'degraded' | 'error';
  timestamp: string;
  database?: {
    status: string;
    size_bytes: number;
    connection_pool: string;
  };
  storage?: {
    audio_files_count: number;
    audio_storage_size_bytes: number;
    disk_total_bytes: number;
    disk_used_bytes: number;
    disk_free_bytes: number;
    disk_usage_percent: number;
  };
  system?: {
    memory_total_bytes: number;
    memory_used_bytes: number;
    memory_available_bytes: number;
    memory_usage_percent: number;
    cpu_count: number;
  };
  error?: string;
}

export interface SystemConfig {
  audio: {
    storage_path: string;
    max_size_mb: number;
  };
  rate_limiting: {
    enabled: boolean;
    default_limit: string;
  };
  features: {
    whisper_validation: boolean;
    whisper_model: string;
    metrics_enabled: boolean;
  };
  environment: {
    debug: boolean;
    environment: string;
    log_level: string;
  };
  security: {
    token_expire_minutes: number;
    algorithm: string;
  };
}

export interface SystemLog {
  timestamp: string;
  level: 'INFO' | 'WARNING' | 'ERROR' | 'DEBUG';
  message: string;
  module: string;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  user: User;
}

export interface ApiError {
  detail: string;
  status_code: number;
}

// Pagination types
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
  pages: number;
}

export interface UsersPaginatedResponse extends PaginatedResponse<User> {\n  active_users: number;\n  admin_users: number;\n  inactive_users: number;\n}

export interface SentencesPaginatedResponse extends PaginatedResponse<Sentence> {}

export interface RecordingFilters {
  status?: Recording['status'];
  user_id?: string;
  sentence_id?: string;
  quality_score_min?: number;
  quality_score_max?: number;
  date_from?: string;
  date_to?: string;
  moderator_id?: string;
}

export interface UserFilters {
  is_admin?: boolean;
  gender?: User['gender'];
  age_range?: string;
  is_active?: boolean;
  date_from?: string;
  date_to?: string;
  search?: string;
}

export interface NotificationSettings {
  email_notifications: boolean;
  push_notifications: boolean;
  new_recordings: boolean;
  new_users: boolean;
  system_alerts: boolean;
}

export interface ExportOptions {
  format: 'json' | 'csv';
  include_audio: boolean;
  date_range?: {
    start: string;
    end: string;
  };
  filters?: RecordingFilters;
}

// Balance configuration types
export interface BalanceConfig {
  target_recordings_per_sentence: number;
  max_recordings_per_sentence: number;
  balanced_selection_enabled: boolean;
}

export interface RecordingDistributionStats {
  total_sentences: number;
  target_recordings_per_sentence: number;
  max_recordings_per_sentence: number;
  distribution: {
    under_target: number;
    at_target: number;
    over_target: number;
  };
  statistics: {
    min_recordings: number;
    max_recordings: number;
    avg_recordings: number;
    total_validated_recordings: number;
  };
  sentences_by_count: Array<{
    id: string;
    text: string;
    difficulty_level: string;
    validated_recordings: number;
    total_recordings: number;
  }>;
}

export interface DetailedRecordingDistribution {
  configuration: BalanceConfig;
  summary: {
    total_sentences: number;
    under_target_count: number;
    at_target_count: number;
    over_target_count: number;
  };
  categories: {
    under_target: Array<{
      id: string;
      text: string;
      difficulty_level: string;
      language: string;
      validated_recordings: number;
      pending_recordings: number;
      rejected_recordings: number;
      total_recordings: number;
      created_at: string | null;
    }>;
    at_target: Array<{
      id: string;
      text: string;
      difficulty_level: string;
      language: string;
      validated_recordings: number;
      pending_recordings: number;
      rejected_recordings: number;
      total_recordings: number;
      created_at: string | null;
    }>;
    over_target: Array<{
      id: string;
      text: string;
      difficulty_level: string;
      language: string;
      validated_recordings: number;
      pending_recordings: number;
      rejected_recordings: number;
      total_recordings: number;
      created_at: string | null;
    }>;
  };
}
