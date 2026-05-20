#!/usr/bin/env python3
"""
Script to create moderator users for the admin dashboard
"""
import os
import sys
from pathlib import Path

# Add the parent directory (backend) to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.database import SessionLocal
from app.models import User
from app.core.auth import get_password_hash
from sqlalchemy.orm import Session

def create_moderator_user():
    """Create a moderator user for the admin dashboard"""
    db = SessionLocal()
    
    try:
        username = input("Nom d'utilisateur du modérateur: ")
        
        # Check if user already exists
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            print(f"L'utilisateur '{username}' existe déjà.")
            return
        
        # Create moderator user
        moderator = User(
            username=username,
            gender="other",
            age_range="25-34",
            is_admin=False,
            role="moderator",
            is_active=True,
            consent_given=True
        )
        
        db.add(moderator)
        db.commit()
        db.refresh(moderator)
        
        print(f"Modérateur '{username}' créé avec succès!")
        print(f"ID: {moderator.id}")
        print(f"Rôle: {moderator.role}")
        
    except Exception as e:
        print(f"Erreur lors de la création du modérateur: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("=== Création d'un utilisateur modérateur ===")
    create_moderator_user()
