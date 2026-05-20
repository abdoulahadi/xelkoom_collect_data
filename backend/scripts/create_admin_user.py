#!/usr/bin/env python3
"""
Script to create admin user if it doesn't exist
"""
import os
import sys
from pathlib import Path

# Add the parent directory (backend) to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.database import SessionLocal
from app.models import User
from app.core.config import settings
from sqlalchemy.orm import Session

def create_admin_user():
    """Create admin user if it doesn't exist"""
    db = SessionLocal()
    
    try:
        # Check if admin user exists
        admin_user = db.query(User).filter(User.username == settings.DEFAULT_ADMIN_USERNAME).first()
        
        if admin_user:
            print(f"Admin user '{settings.DEFAULT_ADMIN_USERNAME}' already exists")
            print(f"  - ID: {admin_user.id}")
            print(f"  - Is Admin: {admin_user.is_admin}")
            print(f"  - Is Active: {admin_user.is_active}")
            return
        
        # Create admin user
        admin_user = User(
            username=settings.DEFAULT_ADMIN_USERNAME,
            gender="OTHER",  # Not relevant for admin
            age_range="35-44",  # Not relevant for admin
            is_admin=True,
            is_active=True,
            consent_given=True
        )
        
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        
        print(f"✅ Admin user '{settings.DEFAULT_ADMIN_USERNAME}' created successfully!")
        print(f"  - ID: {admin_user.id}")
        print(f"  - Username: {admin_user.username}")
        print(f"  - Is Admin: {admin_user.is_admin}")
        print(f"  - Is Active: {admin_user.is_active}")
            
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_admin_user()
