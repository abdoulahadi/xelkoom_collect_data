#!/usr/bin/env python3
"""
Script pour créer ou mettre à jour un utilisateur administrateur avec un mot de passe
"""
import sys
import os
from pathlib import Path

# Ajouter le répertoire parent au PYTHONPATH
parent_dir = Path(__file__).parent.parent.absolute()
sys.path.insert(0, str(parent_dir))

from app.db.database import SessionLocal
from app.models import User, UserRoleEnum
from app.core.auth import get_password_hash
from sqlalchemy.orm import Session

def update_admin_password(username="admin", password="admin123"):
    """Créer ou mettre à jour un utilisateur administrateur avec un mot de passe"""
    print(f"Mise à jour du mot de passe pour l'utilisateur '{username}'...")
    
    db = SessionLocal()
    
    try:
        # Vérifier si l'utilisateur existe
        user = db.query(User).filter(User.username == username).first()
        
        if user:
            # Mettre à jour le mot de passe et les rôles
            user.hashed_password = get_password_hash(password)
            user.is_admin = True
            user.role = UserRoleEnum.ADMIN.value
            user.is_active = True
            db.commit()
            print(f"✅ Mot de passe mis à jour pour l'utilisateur '{username}'")
        else:
            # Créer un nouvel utilisateur admin
            new_admin = User(
                username=username,
                hashed_password=get_password_hash(password),
                gender="other",  # Valeur par défaut
                age_range="25-34",  # Valeur par défaut
                is_admin=True,
                role=UserRoleEnum.ADMIN.value,
                is_active=True,
                consent_given=True
            )
            db.add(new_admin)
            db.commit()
            print(f"✅ Nouvel utilisateur admin '{username}' créé avec succès")
            
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur: {str(e)}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) > 2:
        update_admin_password(username=sys.argv[1], password=sys.argv[2])
    elif len(sys.argv) > 1:
        update_admin_password(username=sys.argv[1])
    else:
        update_admin_password()
    
    print("\nPour vous connecter:")
    print("1. Accédez à l'interface d'administration")
    print("2. Utilisez les identifiants suivants:")
    if len(sys.argv) > 2:
        print(f"   - Nom d'utilisateur: {sys.argv[1]}")
        print(f"   - Mot de passe: {sys.argv[2]}")
    elif len(sys.argv) > 1:
        print(f"   - Nom d'utilisateur: {sys.argv[1]}")
        print("   - Mot de passe: admin123")
    else:
        print("   - Nom d'utilisateur: admin")
        print("   - Mot de passe: admin123")
