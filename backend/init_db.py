#!/usr/bin/env python3
"""
Script to initialize the database with all tables
"""
import os
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent))

from app.db.database import engine, Base
from app.models import User, Sentence, Recording  # Import all models to register them
from app.core.config import settings

def init_database():
    """Initialize the database by creating all tables"""
    print("Creating database tables...")
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    print(f"Database initialized successfully at: {settings.DATABASE_URL}")
    print("Tables created:")
    for table_name in Base.metadata.tables.keys():
        print(f"  - {table_name}")

if __name__ == "__main__":
    init_database()
