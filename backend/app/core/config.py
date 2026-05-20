from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import Optional, List
import os

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite:///./xelkoom.db"
    
    # JWT
    SECRET_KEY: str  # No default — MUST be set via environment variable

    @field_validator('SECRET_KEY')
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError('SECRET_KEY must be at least 32 characters long')
        return v
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Audio storage
    AUDIO_STORAGE_PATH: str = "./audio/"
    MAX_AUDIO_SIZE_MB: int = 10
    
    # External services
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_BUCKET_NAME: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    
    # Redis for rate limiting
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    
    # Security & Rate Limiting
    ENABLE_RATE_LIMITING: bool = True
    DEFAULT_RATE_LIMIT: str = "100/minute"
    
    # Monitoring & Logging
    SENTRY_DSN: Optional[str] = None
    LOG_LEVEL: str = "INFO"
    ENABLE_METRICS: bool = True
    
    # Whisper validation
    ENABLE_WHISPER_VALIDATION: bool = False
    WHISPER_MODEL: str = "base"
    
    # Development
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    
    # CORS settings
    # On utilise str pour éviter que Pydantic n'essaie de parser en JSON
    ALLOW_ORIGINS_STR: str = "http://localhost:3000,http://localhost:5173,https://xelkoom-collect-data.netlify.app,capacitor://localhost,http://localhost,https://backend-xelkoom-collect.onrender.com,file://,app://*,flutter-webview://*"
    
    @property
    def ALLOW_ORIGINS(self) -> List[str]:
        """Convertit la chaîne ALLOW_ORIGINS_STR en liste de domaines autorisés"""
        return self.ALLOW_ORIGINS_STR.split(",") if self.ALLOW_ORIGINS_STR else []
    
    # Default admin user
    DEFAULT_ADMIN_USERNAME: Optional[str] = None
    DEFAULT_ADMIN_PASSWORD: Optional[str] = None
    
    # Data collection balance
    TARGET_RECORDINGS_PER_SENTENCE: int = 5
    MAX_RECORDINGS_PER_SENTENCE: int = 10
    BALANCED_SELECTION_ENABLED: bool = True
    
    class Config:
        env_file = ".env"

settings = Settings()
