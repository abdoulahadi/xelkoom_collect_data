#!/usr/bin/env python3
"""
Script to populate the database with sample sentences
"""
import os
import sys
from pathlib import Path

# Add the parent directory (backend) to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.database import SessionLocal
from app.models import Sentence
from sqlalchemy.orm import Session

def add_sample_sentences():
    """Add sample sentences to the database"""
    db = SessionLocal()
    
    try:
        # Check if we already have sentences
        existing_count = db.query(Sentence).count()
        if existing_count > 0:
            print(f"Database already has {existing_count} sentences. Skipping...")
            return
        
        # Sample Wolof sentences
        sample_sentences = [
            "Asalaa maalekum, naka ngon?",
            "Man ngi tudd Abdul.",
            "Daara bi amul dara bu baax.",
            "Xaalis yi dafa gëna.",
            "Ndogg mi dafa sedd.",
            "Keroog gi dafa rafet.",
            "Jàngale bi dafa gëna.",
            "Mburu gi dafa soxna.",
            "Takusaan la.",
            "Bëgg naa dem ci kaay.",
            "Ceeb bu neex la.",
            "Wax ma ci wolof.",
            "Sama mbay dafa deg.",
            "Li nee la?",
            "Damaa bëgg jàng.",
            "Góor gi dafa reer.",
            "Jigéen ji dafa booloo.",
            "Xale yi ngi tuuti.",
            "Mag mi dafa mag.",
            "Kersa bu baax la.",
        ]
        
        sentences = []
        for i, text in enumerate(sample_sentences):
            sentence = Sentence(
                text=text,
                language="wo",
                difficulty_level="easy" if i < 10 else "medium",
                status="available"
            )
            sentences.append(sentence)
        
        db.add_all(sentences)
        db.commit()
        
        print(f"Successfully added {len(sentences)} sample sentences to the database!")
        
        # Display the sentences
        print("\nAdded sentences:")
        for i, sentence in enumerate(sentences, 1):
            print(f"{i:2d}. {sentence.text}")
            
    except Exception as e:
        print(f"Error adding sentences: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_sample_sentences()
