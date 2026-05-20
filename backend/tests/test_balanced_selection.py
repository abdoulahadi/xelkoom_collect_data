#!/usr/bin/env python3
"""
Script to test the balanced sentence selection logic
"""
import os
import sys
from pathlib import Path
import asyncio
from collections import defaultdict

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent))

from app.db.database import SessionLocal
from app.models import User, Sentence, Recording
from app.core.config import settings
from sqlalchemy.orm import Session
from sqlalchemy import func, select

def test_balanced_selection(db: Session, test_user_id: int, num_tests: int = 100):
    """Test the balanced selection logic"""
    
    print("🧪 Testing Balanced Sentence Selection Logic")
    print("=" * 50)
    
    # Get current recording distribution
    sentences_with_counts = db.query(
        Sentence,
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "validated"), 
            0
        ).label('recording_count')
    ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
     .filter(Sentence.status == "available")\
     .group_by(Sentence.id)\
     .all()
    
    print(f"📊 Current Distribution:")
    print(f"Target recordings per sentence: {settings.TARGET_RECORDINGS_PER_SENTENCE}")
    print(f"Max recordings per sentence: {settings.MAX_RECORDINGS_PER_SENTENCE}")
    print(f"Balanced selection enabled: {settings.BALANCED_SELECTION_ENABLED}")
    print()
    
    # Show current state
    for sentence, count in sentences_with_counts[:10]:  # Show first 10
        status = "✅ Complete" if count >= settings.TARGET_RECORDINGS_PER_SENTENCE else "⏳ Needs more"
        if count >= settings.MAX_RECORDINGS_PER_SENTENCE:
            status = "🔴 Over-recorded"
        print(f"Sentence {sentence.id}: {count} recordings - {status}")
        print(f"  Text: {sentence.text[:50]}...")
    
    print(f"\n... and {len(sentences_with_counts) - 10} more sentences")
    
    # Simulate selection logic
    print(f"\n🎯 Simulating {num_tests} sentence selections...")
    
    # Get sentences available for the test user (exclude already recorded)
    recorded_sentence_ids = select(Recording.sentence_id).filter(
        Recording.user_id == test_user_id
    )
    
    available_sentences = [
        (sentence, count) for sentence, count in sentences_with_counts
        if sentence.id not in [r.sentence_id for r in db.query(Recording).filter(
            Recording.user_id == test_user_id
        ).all()]
    ]
    
    if not available_sentences:
        print("❌ No available sentences for test user")
        return
    
    print(f"📝 Available sentences for user {test_user_id}: {len(available_sentences)}")
    
    # Simulate the weighted selection
    selection_counts = defaultdict(int)
    
    import random
    for _ in range(num_tests):
        # Calculate weights (same logic as in the endpoint)
        weights = []
        for sentence, count in available_sentences:
            if count < settings.TARGET_RECORDINGS_PER_SENTENCE:
                weight = settings.TARGET_RECORDINGS_PER_SENTENCE - count + 1
            elif count < settings.MAX_RECORDINGS_PER_SENTENCE:
                weight = 0.5
            else:
                weight = 0.1
            weights.append(weight)
        
        # Select based on weights
        if sum(weights) == 0:
            selected = random.choice(available_sentences)
        else:
            selected = random.choices(available_sentences, weights=weights, k=1)[0]
        
        selection_counts[selected[0].id] += 1
    
    # Show results
    print(f"\n📈 Selection Results (out of {num_tests} selections):")
    print("-" * 60)
    
    sorted_results = sorted(
        [(sentence_id, count) for sentence_id, count in selection_counts.items()],
        key=lambda x: x[1],
        reverse=True
    )
    
    for sentence_id, selection_count in sorted_results[:15]:  # Show top 15
        # Find the sentence info
        sentence_info = next(
            (s, c) for s, c in available_sentences if s.id == sentence_id
        )
        sentence, current_recordings = sentence_info
        
        percentage = (selection_count / num_tests) * 100
        
        print(f"Sentence {sentence_id}: {selection_count:3d} selections ({percentage:5.1f}%) "
              f"- Currently has {current_recordings} recordings")
        print(f"  Text: {sentence.text[:50]}...")
    
    # Summary statistics
    under_target_selections = sum(
        count for (s, current_count), count in 
        zip(available_sentences, [selection_counts[s.id] for s, _ in available_sentences])
        if current_count < settings.TARGET_RECORDINGS_PER_SENTENCE
    )
    
    print(f"\n📊 Summary:")
    print(f"Selections for under-target sentences: {under_target_selections}/{num_tests} "
          f"({(under_target_selections/num_tests)*100:.1f}%)")
    
    # Check balance effectiveness
    under_target_count = len([
        1 for _, count in available_sentences 
        if count < settings.TARGET_RECORDINGS_PER_SENTENCE
    ])
    at_target_count = len([
        1 for _, count in available_sentences 
        if settings.TARGET_RECORDINGS_PER_SENTENCE <= count < settings.MAX_RECORDINGS_PER_SENTENCE
    ])
    over_target_count = len([
        1 for _, count in available_sentences 
        if count >= settings.MAX_RECORDINGS_PER_SENTENCE
    ])
    
    print(f"\nSentence Distribution:")
    print(f"  Under target ({settings.TARGET_RECORDINGS_PER_SENTENCE}): {under_target_count}")
    print(f"  At target: {at_target_count}")
    print(f"  Over target: {over_target_count}")

def main():
    """Main function"""
    db = SessionLocal()
    
    try:
        # Get a test user
        test_user = db.query(User).filter(User.is_active == True).first()
        if not test_user:
            print("❌ No active user found for testing")
            return
        
        print(f"🧪 Testing with user: {test_user.username} (ID: {test_user.id})")
        test_balanced_selection(db, test_user.id)
        
    except Exception as e:
        print(f"❌ Error during testing: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
