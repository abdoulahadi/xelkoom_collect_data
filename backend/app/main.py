from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
import logging
from app.core.config import settings
from app.api.routes import auth, users, sentences, recordings, admin

# Import security middleware
try:
    from app.core.rate_limiting import limiter, SecurityMiddleware, rate_limit_exceeded_handler
    from slowapi import _rate_limit_exceeded_handler
    from slowapi.errors import RateLimitExceeded
    RATE_LIMITING_AVAILABLE = True
except ImportError:
    RATE_LIMITING_AVAILABLE = False
    logger = logging.getLogger(__name__)
    logger.warning("Rate limiting dependencies not available. Install slowapi and redis.")

# CQ-004: Use standard logging consistently
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# API-004: Setup JSON file logging for real log endpoint
from app.core.json_logger import setup_json_logging
setup_json_logging()

# Initialize Sentry for error tracking
if settings.SENTRY_DSN and settings.SENTRY_DSN != "https://your-sentry-dsn@sentry.io/project-id":
    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
        
        try:
            sentry_sdk.init(
                dsn=settings.SENTRY_DSN,
                integrations=[
                    FastApiIntegration(),
                    SqlalchemyIntegration(),
                ],
                traces_sample_rate=0.1,
                environment=settings.ENVIRONMENT
            )
            logger.info("Sentry error tracking initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Sentry: {e}")
    except ImportError:
        logger.warning("Sentry SDK not available. Install sentry-sdk for error tracking.")

# Warn if DEBUG is enabled in production
if settings.ENVIRONMENT == "production" and settings.DEBUG:
    logger.warning("DEBUG mode is enabled in production — this is a security risk")

# DB-001: Tables are managed by Alembic migrations.
# Run 'alembic upgrade head' before starting the application.

app = FastAPI(
    title="Xelkoom Audio Collection API",
    description="API for collecting Wolof audio data for TTS training",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add security middleware
app.add_middleware(SecurityMiddleware)

# Add rate limiting if available
if RATE_LIMITING_AVAILABLE and settings.ENABLE_RATE_LIMITING:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)
    logger.info("Rate limiting enabled")

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOW_ORIGINS,  # Utilise la propriété qui convertit la chaîne en liste
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# Create audio directory if it doesn't exist
os.makedirs(settings.AUDIO_STORAGE_PATH, exist_ok=True)

# Mount static files for audio
app.mount("/audio", StaticFiles(directory=settings.AUDIO_STORAGE_PATH), name="audio")

# Include routers — API-002: version prefix
API_V1_PREFIX = "/api/v1"
app.include_router(auth.router, prefix=f"{API_V1_PREFIX}/auth", tags=["Authentication"])
app.include_router(users.router, prefix=f"{API_V1_PREFIX}/users", tags=["Users"])
app.include_router(sentences.router, prefix=f"{API_V1_PREFIX}/sentences", tags=["Sentences"])
app.include_router(recordings.router, prefix=f"{API_V1_PREFIX}/recordings", tags=["Recordings"])
app.include_router(admin.router, prefix=f"{API_V1_PREFIX}/admin", tags=["Admin"])

# Backward compatibility: also mount at old paths for gradual migration
app.include_router(auth.router, prefix="/auth", tags=["Authentication (legacy)"], include_in_schema=False)
app.include_router(users.router, prefix="/users", tags=["Users (legacy)"], include_in_schema=False)
app.include_router(sentences.router, prefix="/sentences", tags=["Sentences (legacy)"], include_in_schema=False)
app.include_router(recordings.router, prefix="/recordings", tags=["Recordings (legacy)"], include_in_schema=False)
app.include_router(admin.router, prefix="/admin", tags=["Admin (legacy)"], include_in_schema=False)

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "Xelkoom Audio Collection API",
        "version": "1.0.0",
        "status": "active"
    }

@app.get("/health")
async def health_check():
    """Detailed health check — API-003"""
    from sqlalchemy import text
    from app.db.database import SessionLocal
    
    # Check database connectivity
    db_status = "connected"
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception:
        db_status = "disconnected"
    
    # Check audio storage accessibility
    storage_status = "accessible" if os.path.isdir(settings.AUDIO_STORAGE_PATH) else "inaccessible"
    
    overall = "healthy" if db_status == "connected" and storage_status == "accessible" else "unhealthy"
    
    return {
        "status": overall,
        "database": db_status,
        "audio_storage": storage_status
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )
