#!/usr/bin/env python3
"""
Script pour tester si le nombre d'enregistrements d'une phrase est bien incrémenté
lors de la création d'un enregistrement.
"""

import asyncio
import sys
import os
from pathlib import Path

# Ajouter le répertoire backend au path Python
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

from sqlalchemy.orm import Session
from sqlalchemy import func
from app.db.database import get_db
from app.models import User, Sentence, Recording

def test_recording_count_increment():
    """Test si le comptage des enregistrements fonctionne correctement"""
    
    # Obtenir une session de base de données
    db = next(get_db())
    
    try:
        print("=== Test du comptage des enregistrements ===\n")
        
        # 1. Vérifier qu'il y a des phrases et des utilisateurs
        total_sentences = db.query(Sentence).count()
        total_users = db.query(User).count()
        total_recordings = db.query(Recording).count()
        
        print(f"Données actuelles:")
        print(f"- Phrases: {total_sentences}")
        print(f"- Utilisateurs: {total_users}")
        print(f"- Enregistrements: {total_recordings}")
        print()
        
        if total_sentences == 0:
            print("❌ Aucune phrase trouvée. Ajoutez des phrases d'abord.")
            return
            
        if total_users == 0:
            print("❌ Aucun utilisateur trouvé. Créez des utilisateurs d'abord.")
            return
        
        # 2. Obtenir les statistiques par phrase
        print("=== Statistiques par phrase ===")
        recording_stats = db.query(
            Sentence.id,
            Sentence.text,
            func.count(Recording.id).label('total_recordings'),
            func.count(Recording.id).filter(Recording.status == "validated").label('validated_recordings'),
            func.count(Recording.id).filter(Recording.status == "pending").label('pending_recordings'),
            func.count(Recording.id).filter(Recording.status == "rejected").label('rejected_recordings')
        ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
         .group_by(Sentence.id)\
         .limit(10)\
         .all()
        
        for stat in recording_stats:
            text_preview = stat.text[:50] + "..." if len(stat.text) > 50 else stat.text
            print(f"Phrase {stat.id}: '{text_preview}'")
            print(f"  - Total: {stat.total_recordings}")
            print(f"  - Validés: {stat.validated_recordings}")
            print(f"  - En attente: {stat.pending_recordings}")
            print(f"  - Rejetés: {stat.rejected_recordings}")
            print()
        
        # 3. Vérifier les enregistrements par utilisateur pour quelques phrases
        print("=== Vérification d'unicité par utilisateur ===")
        
        # Prendre les 3 premières phrases avec des enregistrements
        sentences_with_recordings = db.query(Sentence.id, Sentence.text)\
            .join(Recording)\
            .distinct()\
            .limit(3)\
            .all()
        
        for sentence_id, sentence_text in sentences_with_recordings:
            text_preview = sentence_text[:30] + "..." if len(sentence_text) > 30 else sentence_text
            print(f"Phrase {sentence_id}: '{text_preview}'")
            
            # Compter les enregistrements par utilisateur pour cette phrase
            user_recordings = db.query(
                User.username,
                func.count(Recording.id).label('recording_count')
            ).join(Recording)\
             .filter(Recording.sentence_id == sentence_id)\
             .group_by(User.id, User.username)\
             .all()
            
            for username, count in user_recordings:
                print(f"  - {username}: {count} enregistrement(s)")
                if count > 1:
                    print(f"    ⚠️ ATTENTION: L'utilisateur {username} a {count} enregistrements pour cette phrase!")
            print()
        
        # 4. Tester la logique de sélection équilibrée
        print("=== Test de la logique de sélection équilibrée ===")
        
        # Simuler la requête de sélection équilibrée
        sentences_with_counts = db.query(
            Sentence,
            func.coalesce(
                func.count(Recording.id).filter(Recording.status == "validated"), 
                0
            ).label('validated_count')
        ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
         .filter(Sentence.status == "available")\
         .group_by(Sentence.id)\
         .limit(5)\
         .all()
        
        print("Phrases avec leur nombre d'enregistrements validés:")
        for sentence, count in sentences_with_counts:
            text_preview = sentence.text[:40] + "..." if len(sentence.text) > 40 else sentence.text
            print(f"  - Phrase {sentence.id}: {count} validés - '{text_preview}'")
        
        print("\n✅ Test terminé avec succès!")
        
    except Exception as e:
        print(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()

def check_database_integrity():
    """Vérifier l'intégrité de la base de données"""
    
    db = next(get_db())
    
    try:
        print("=== Vérification de l'intégrité de la base de données ===\n")
        
        # Vérifier les relations
        orphaned_recordings = db.query(Recording).filter(
            ~Recording.user_id.in_(db.query(User.id)) |
            ~Recording.sentence_id.in_(db.query(Sentence.id))
        ).count()
        
        print(f"Enregistrements orphelins: {orphaned_recordings}")
        
        # Vérifier les enregistrements en double (même utilisateur, même phrase)
        duplicate_recordings = db.query(
            Recording.user_id,
            Recording.sentence_id,
            func.count(Recording.id).label('count')
        ).group_by(Recording.user_id, Recording.sentence_id)\
         .having(func.count(Recording.id) > 1)\
         .all()
        
        if duplicate_recordings:
            print(f"⚠️ {len(duplicate_recordings)} paires utilisateur-phrase avec des enregistrements en double:")
            for user_id, sentence_id, count in duplicate_recordings:
                print(f"  - Utilisateur {user_id}, Phrase {sentence_id}: {count} enregistrements")
        else:
            print("✅ Aucun enregistrement en double trouvé")
        
        print()
        
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {str(e)}")
    
    finally:
        db.close()

if __name__ == "__main__":
    print("Test du comptage des enregistrements\n")
    
    # Vérifier l'intégrité de la base
    check_database_integrity()
    
    # Tester le comptage
    test_recording_count_increment()
