#!/usr/bin/env python3
"""
Script pour initialiser la base de données et créer l'utilisateur admin par défaut
"""

import asyncio
import sys
import os
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules
sys.path.append(str(Path(__file__).parent.parent))
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from sqlalchemy.orm import Session
from app.db.database import engine, SessionLocal, Base
from app.models import User, Sentence, Recording, GenderEnum, AgeRangeEnum, SentenceStatusEnum
from app.core.auth import get_password_hash
from app.core.config import settings

# Sample Wolof sentences for TTS training
SAMPLE_SENTENCES = [
    "Jàngalekat dafay wax ci wolof.",  # The student speaks in Wolof
    "Dafa wër ci boppam.",  # He/she is fast in his/her mind
    "Nit ku baax la.",  # He/she is a good person
    "Jëf ji dafa neex.",  # The work is good
    "Dégg nga Wolof?",  # Do you understand Wolof?
    "Mangi dem ci gox gi.",  # I am going to the village
    "Keroog gi dafa tang.",  # The school is hot
    "Ndox mi dafa sedd.",  # The water is cold
    "Xale yi danga baax.",  # The children are good
    "Yàlla moo ko wax.",  # God said it
    "Ndogou bi dafa neex na.",  # The lunch is delicious
    "Sama doom dafa gën.",  # My child is better
    "Ndaw ji dafa rafet.",  # The girl is beautiful
    "Góor gi dafa baax.",  # The man is good
    "Jigéen ji dafa gën.",  # The woman is better
    "Wax ma ci Wolof.",  # Tell me in Wolof
    "Suma tuuti la.",  # I am young
    "Dama ngi fi jóge.",  # I am here standing
    "Ngeen ngi dem?",  # Where are you going?
    "Bu ma génn ak mooy?",  # When I am better than what?
    "Kerr ga dafa rafet.",  # The house is beautiful
    "Weer gi dafa genn.",  # The moon is bright
    "Suba si dafa neex.",  # This morning is good
    "Angel bi dafa tang.",  # The sun is hot
    "Ndox mi dafa sedd.",  # The water is cold
    "Ceeb u jën la.",  # It's white rice
    "Yàgg bi dafa neex.",  # The sauce is good
    "Attaaya bi dafa neex.",  # The tea is good
    "Liggéey bi dafa gëna.",  # The work is difficult
    "Xam nga Wolof?",  # Do you know Wolof?
]

def create_admin_user(db: Session):
    """Create an admin user"""
    
    # Vérifier si l'admin existe déjà
    existing_admin = db.query(User).filter(User.username == "admin").first()
    if existing_admin:
        print("⚠️  L'utilisateur admin 'admin' existe déjà")
        return existing_admin
    
    admin = User(
        username="admin",
        hashed_password=get_password_hash("admin123"),
        gender="other",
        age_range="25-34",
        role="admin",
        is_admin=True,
        is_active=True,
        consent_given=True
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    print("✅ Admin user created: admin (password: admin123)")
    return admin

def create_sample_sentences(db: Session):
    """Create sample sentences"""
    
    # Vérifier combien de phrases existent déjà
    existing_count = db.query(Sentence).count()
    if existing_count >= len(SAMPLE_SENTENCES):
        print(f"⚠️  {existing_count} phrases existent déjà dans la base")
        return
    
    sentences = []
    for i, text in enumerate(SAMPLE_SENTENCES):
        # Vérifier si la phrase existe déjà
        existing = db.query(Sentence).filter(Sentence.text == text).first()
        if not existing:
            sentence = Sentence(
                text=text,
                language="wo",  # Wolof language code
                difficulty_level="easy" if i < 15 else "medium",
                status="available"
            )
            sentences.append(sentence)
    
    if sentences:
        db.add_all(sentences)
        db.commit()
        print(f"✅ Created {len(sentences)} sample sentences")
    return sentences

def create_sample_users(db: Session):
    """Create sample users for testing"""
    users = [
        User(
            username="fatou_diop",
            hashed_password=get_password_hash("password123"),
            gender="female",
            age_range="25-34",
            is_admin=False,
            is_active=True,
            consent_given=True
        ),
        User(
            username="moussa_fall",
            hashed_password=get_password_hash("password123"),
            gender="male",
            age_range="18-24",
            is_admin=False,
            is_active=True,
            consent_given=True
        ),
        User(
            username="awa_ndiaye",
            hashed_password=get_password_hash("password123"),
            gender="female",
            age_range="35-44",
            is_admin=False,
            is_active=True,
            consent_given=True
        )
    ]
    
    # Vérifier si les utilisateurs existent déjà
    added_users = []
    for user_data in users:
        existing = db.query(User).filter(User.username == user_data.username).first()
        if not existing:
            added_users.append(user_data)
    
    if added_users:
        db.add_all(added_users)
        db.commit()
        print(f"✅ Created {len(added_users)} sample users")
    return added_users

def main():
    """Initialize database with sample data"""
    print("🚀 Initialisation de la base de données SQLite Xelkoom...")
    print("=" * 60)
    
    try:
        # Create tables
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created")
        
        # Créer le répertoire audio
        from pathlib import Path
        audio_path = Path(settings.AUDIO_STORAGE_PATH)
        audio_path.mkdir(exist_ok=True)
        print(f"✅ Répertoire audio créé: {audio_path.absolute()}")
        
        # Create session
        db = SessionLocal()
        
        try:
            # Create admin user
            admin_user = create_admin_user(db)
            
            # Create sample sentences
            sentences = create_sample_sentences(db)
            
            # Create sample users
            users = create_sample_users(db)
            
            print("\n" + "=" * 60)
            print("🎉 Database initialization completed!")
            print("\n📋 Summary:")
            print(f"   • Admin user: admin")
            print(f"   • Sample sentences: {len(SAMPLE_SENTENCES)}")
            print(f"   • Sample users: 3")
            print("\n📋 Informations de connexion admin:")
            print(f"   Username: admin")
            print(f"   Password: admin123")
            print("\n🔗 Next steps:")
            print("   1. Start the API server: uvicorn app.main:app --reload")
            print("   2. Visit http://localhost:8000/docs for API documentation")
            print("   3. Admin Dashboard: http://localhost:3000")
            print("   4. Login with username 'admin' to access admin features")
            
        except Exception as e:
            print(f"❌ Error initializing database: {e}")
            import traceback
            traceback.print_exc()
            db.rollback()
            raise
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Erreur lors de l'initialisation: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(main())
