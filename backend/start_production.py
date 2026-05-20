#!/usr/bin/env python3
"""
Script de démarrage pour la production sur Render
"""

import os
import sys
import asyncio
import logging
from pathlib import Path

# Configuration du logging pour la production
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def create_tables():
    """Créer les tables via Alembic migrations (préféré) ou SQLAlchemy comme fallback"""
    try:
        logger.info("Running Alembic migrations to manage database schema...")
        from alembic.config import Config
        from alembic import command
        
        alembic_cfg = Config("alembic.ini")
        command.upgrade(alembic_cfg, "head")
        logger.info("Database schema up to date via Alembic")
        
    except Exception as e:
        logger.warning(f"Alembic migration failed, falling back to create_all: {e}")
        try:
            from app.db.database import engine
            from app.models import Base
            Base.metadata.create_all(bind=engine)
            logger.info("Database tables created via SQLAlchemy fallback")
        except Exception as e2:
            logger.error(f"Error creating tables: {e2}")

async def run_migrations():
    """Exécuter les migrations de base de données au démarrage"""
    try:
        logger.info("Running database migrations...")
        # Import ici pour éviter les problèmes de dépendances circulaires
        from alembic.config import Config
        from alembic import command
        
        # Configuration d'Alembic
        alembic_cfg = Config("alembic.ini")
        
        # Exécuter les migrations
        command.upgrade(alembic_cfg, "head")
        logger.info("Database migrations completed successfully")
        
    except Exception as e:
        logger.error(f"Error running migrations: {e}")
        # En production, on peut choisir de continuer même si les migrations échouent
        # raise

async def setup_directories():
    """Créer les répertoires nécessaires"""
    directories = [
        "audio",
        "uploads/audio",
        "audio/validated"
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        logger.info(f"Created/verified directory: {directory}")

async def create_admin_user():
    """Créer ou mettre à jour l'utilisateur administrateur si besoin"""
    try:
        # Récupérer les informations d'identification depuis les variables d'environnement
        admin_username = os.getenv("ADMIN_USERNAME")
        admin_password = os.getenv("ADMIN_PASSWORD")
        
        if not admin_username or not admin_password:
            logger.warning("ADMIN_USERNAME or ADMIN_PASSWORD not set — skipping admin setup")
            return
        
        if len(admin_password) < 12:
            logger.error("ADMIN_PASSWORD must be at least 12 characters — skipping admin setup")
            return
        
        # Importer ici pour éviter les dépendances circulaires
        sys.path.append('.')
        from scripts.update_admin_password import update_admin_password
        
        logger.info(f"Setting up admin user: {admin_username}")
        update_admin_password(username=admin_username, password=admin_password)
        logger.info("Admin user setup completed")
        
    except Exception as e:
        logger.error(f"Error setting up admin user: {e}")
        # En production, on continue même si la création d'admin échoue
        # L'administrateur pourra être créé manuellement plus tard

async def initialize_app():
    """Initialiser l'application"""
    logger.info("Initializing Xelkoom backend for production...")
    
    # Créer les répertoires
    await setup_directories()
    
    # Créer les tables via SQLAlchemy
    await create_tables()
    
    # Exécuter les migrations (optionnel selon votre setup)
    if os.getenv("RUN_MIGRATIONS", "false").lower() == "true":
        await run_migrations()
    
    # Créer/mettre à jour l'utilisateur admin (optionnel selon le setup Docker)
    if os.getenv("SETUP_ADMIN", "true").lower() == "true":
        await create_admin_user()
    
    logger.info("Application initialization completed")

if __name__ == "__main__":
    # Initialiser l'application
    asyncio.run(initialize_app())
    
    # Démarrer le serveur
    import uvicorn
    from app.main import app
    
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    logger.info(f"Starting server on {host}:{port}")
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        workers=1,  # Render recommande 1 worker pour les plans starter
        log_level="info",
        access_log=True
    )
