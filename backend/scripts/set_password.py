#!/usr/bin/env python3
"""
Script pour définir ou mettre à jour le mot de passe d'un utilisateur
"""
import sys
import os
from pathlib import Path

# Ajouter le répertoire parent au PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent.parent.absolute()))

from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.models import User
from app.core.auth import get_password_hash
import argparse
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def set_password(username: str, password: str):
    """Définit le mot de passe pour un utilisateur existant"""
    db = SessionLocal()
    try:
        # Rechercher l'utilisateur
        user = db.query(User).filter(User.username == username).first()
        
        if not user:
            logger.error(f"Utilisateur '{username}' non trouvé")
            return False
        
        # Mettre à jour le mot de passe
        hashed_password = get_password_hash(password)
        user.hashed_password = hashed_password
        
        db.commit()
        logger.info(f"Mot de passe mis à jour pour l'utilisateur '{username}'")
        return True
    
    except Exception as e:
        db.rollback()
        logger.error(f"Erreur lors de la mise à jour du mot de passe: {str(e)}")
        return False
    
    finally:
        db.close()

def main():
    """Point d'entrée principal"""
    parser = argparse.ArgumentParser(description="Définir ou mettre à jour le mot de passe d'un utilisateur")
    parser.add_argument("--username", "-u", required=True, help="Nom d'utilisateur")
    parser.add_argument("--password", "-p", required=True, help="Nouveau mot de passe")
    
    args = parser.parse_args()
    
    if set_password(args.username, args.password):
        print(f"✅ Mot de passe mis à jour pour l'utilisateur '{args.username}'")
        sys.exit(0)
    else:
        print(f"❌ Échec de la mise à jour du mot de passe pour '{args.username}'")
        sys.exit(1)

if __name__ == "__main__":
    main()
