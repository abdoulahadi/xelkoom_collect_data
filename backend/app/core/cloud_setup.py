from app.core.config import settings
import logging
import asyncio
import os
from google.cloud import storage

# CQ-001: Fixed import — app.core.logger doesn't exist
logger = logging.getLogger(__name__)

async def setup_cloud_storage():
    """
    Configure et initialise le bucket Cloud Storage si nécessaire.
    Crée les dossiers requis dans le bucket.
    """
    if settings.AUDIO_STORAGE_TYPE != "cloud":
        logger.info("Storage type n'est pas cloud, ignorant la configuration Cloud Storage")
        return
    
    if not settings.AUDIO_BUCKET_NAME:
        logger.error("AUDIO_BUCKET_NAME non défini pour le stockage cloud")
        return
    
    try:
        # Créer un client Storage
        storage_client = storage.Client()
        
        # Vérifier si le bucket existe, sinon le créer
        bucket_name = settings.AUDIO_BUCKET_NAME
        try:
            bucket = storage_client.get_bucket(bucket_name)
            logger.info(f"Bucket {bucket_name} existe déjà")
        except Exception:
            logger.info(f"Création du bucket {bucket_name}")
            bucket = storage_client.create_bucket(bucket_name, location=settings.CLOUD_STORAGE_LOCATION)
        
        # Créer les dossiers requis (en créant un fichier vide comme placeholder)
        required_folders = ['uploads/audio/', 'audio/validated/']
        for folder in required_folders:
            blob = bucket.blob(f"{folder}.keep")
            if not blob.exists():
                blob.upload_from_string('')
                logger.info(f"Dossier {folder} créé dans Cloud Storage")
        
        logger.info("Configuration Cloud Storage terminée avec succès")
    except Exception as e:
        logger.error(f"Erreur lors de la configuration Cloud Storage: {str(e)}")
        # Ne pas faire échouer le démarrage si Cloud Storage n'est pas disponible
        # en environnement de développement avec émulation

async def main():
    """
    Point d'entrée pour la configuration de l'environnement Google Cloud.
    """
    await setup_cloud_storage()

if __name__ == "__main__":
    # Exécuter la configuration Cloud
    asyncio.run(main())
