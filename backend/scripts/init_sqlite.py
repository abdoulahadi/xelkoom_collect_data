#!/usr/bin/env python3
"""
Script pour initialiser la base de données SQLite et créer l'utilisateur admin par défaut
"""

import sys
import os
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules
sys.path.append(str(Path(__file__).parent.parent))

from sqlalchemy.orm import Session
from app.db.database import engine, SessionLocal, Base
from app.models.user import User
from app.models.sentence import Sentence
from app.models.recording import Recording
from app.core.auth import get_password_hash
from app.core.config import settings

def create_tables():
    """Créer toutes les tables"""
    print("Création des tables...")
    Base.metadata.create_all(bind=engine)
    print("✅ Tables créées avec succès")

def create_default_admin(db: Session):
    """Créer l'utilisateur admin par défaut"""
    print("Création de l'utilisateur admin par défaut...")
    
    # Vérifier si l'admin existe déjà
    existing_admin = db.query(User).filter(
        User.username == settings.DEFAULT_ADMIN_USERNAME
    ).first()
    
    if existing_admin:
        print(f"⚠️  L'utilisateur admin '{settings.DEFAULT_ADMIN_USERNAME}' existe déjà")
        return existing_admin
    
    # Créer le nouvel admin
    admin_user = User(
        username=settings.DEFAULT_ADMIN_USERNAME,
        hashed_password=get_password_hash(settings.DEFAULT_ADMIN_PASSWORD),
        gender="other",
        age_range="25-34",
        consent_given=True,
        is_active=True,
        is_admin=True
    )
    
    db.add(admin_user)
    db.commit()
    db.refresh(admin_user)
    
    print(f"✅ Utilisateur admin créé:")
    print(f"   Username: {settings.DEFAULT_ADMIN_USERNAME}")
    print(f"   Password: {settings.DEFAULT_ADMIN_PASSWORD}")
    print(f"   ID: {admin_user.id}")
    
    return admin_user

def create_sample_sentences(db: Session):
    """Créer quelques phrases d'exemple en wolof"""
    print("Création des phrases d'exemple...")
    
    sample_sentences = [
        "Jàngalekat dafay wax ci wolof.",
        "Mu ngi def dara ci biir kër ga.",
        "Sunu gox gi baax na lool.",
        "Man maa ngi wax ak sa wat wi.",
        "Ndax nga xam ni nga def?",
        "Bii baax na ci biir yàlla.",
        "Am nga seen ci biir kër gi?",
        "Mu ngi tudd ak sama mbokk mi.",
        "Sunu doom yi dañu yàg-yàg.",
        "Xale yi nañu dem ci sukaaŋ bi.",
        "Dafa wër ci boppam.",
        "Nit ku baax la.",
        "Jëf ji dafa neex.",
        "Dégg nga Wolof?",
        "Mangi dem ci gox gi.",
        "Keroog gi dafa tang.",
        "Ndox mi dafa sedd.",
        "Xale yi danga baax.",
        "Yàlla moo ko wax.",
        "Ndogou bi dafa neex na."
    ]
    
    # Vérifier combien de phrases existent déjà
    existing_count = db.query(Sentence).count()
    
    if existing_count >= len(sample_sentences):
        print(f"⚠️  {existing_count} phrases existent déjà dans la base")
        return
    
    # Ajouter les nouvelles phrases
    added_count = 0
    for text in sample_sentences:
        existing = db.query(Sentence).filter(Sentence.text == text).first()
        if not existing:
            sentence = Sentence(
                text=text,
                language="wo",  # Code ISO pour wolof
                status="available"
            )
            db.add(sentence)
            added_count += 1
    
    db.commit()
    print(f"✅ {added_count} nouvelles phrases ajoutées")

def create_audio_directory():
    """Créer le répertoire pour stocker les fichiers audio"""
    audio_path = Path(settings.AUDIO_STORAGE_PATH)
    audio_path.mkdir(exist_ok=True)
    print(f"✅ Répertoire audio créé: {audio_path.absolute()}")

def main():
    """Fonction principale d'initialisation"""
    print("🚀 Initialisation de la base de données Xelkoom SQLite")
    print("=" * 60)
    
    try:
        # Créer les tables
        create_tables()
        
        # Créer le répertoire audio
        create_audio_directory()
        
        # Ouvrir une session de base de données
        db = SessionLocal()
        
        try:
            # Créer l'admin par défaut
            admin_user = create_default_admin(db)
            
            # Créer des phrases d'exemple
            create_sample_sentences(db)
            
            print("\n" + "=" * 60)
            print("✅ Initialisation terminée avec succès!")
            print("\n📋 Informations de connexion admin:")
            print(f"   URL: http://localhost:8000")
            print(f"   Username: {settings.DEFAULT_ADMIN_USERNAME}")
            print(f"   Password: {settings.DEFAULT_ADMIN_PASSWORD}")
            print("\n📚 Documentation API: http://localhost:8000/docs")
            print("📱 Admin Dashboard: http://localhost:3000")
            print("\n🚀 Pour démarrer le serveur:")
            print("   cd backend")
            print("   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
            
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Erreur lors de l'initialisation: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
