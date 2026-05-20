from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, select
from typing import List, Optional
import random
import uuid as uuid_mod
from app.db.database import get_db
from app.core.auth import get_current_active_user
from app.core.config import settings
from app.models import User, Sentence, Recording
from app.schemas import SentenceResponse

router = APIRouter()

@router.get("/next", response_model=SentenceResponse)
async def get_next_sentence(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    difficulty: Optional[str] = None
):
    """Get next available sentence for recording with balanced selection"""
    
    # Get sentences that haven't been recorded by this user
    recorded_sentence_ids = select(Recording.sentence_id).filter(
        Recording.user_id == current_user.id
    )
    
    base_query = db.query(Sentence).filter(
        Sentence.status == "available",
        ~Sentence.id.in_(recorded_sentence_ids)
    )
    
    # Filter by difficulty if specified
    if difficulty:
        base_query = base_query.filter(Sentence.difficulty_level == difficulty)
    
    # Get sentences with their recording counts (validated recordings only)
    sentences_with_counts = db.query(
        Sentence,
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "validated"), 
            0
        ).label('recording_count')
    ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
     .filter(
        Sentence.status == "available",
        ~Sentence.id.in_(recorded_sentence_ids)
    ).group_by(Sentence.id)
    
    # Apply difficulty filter if specified
    if difficulty:
        sentences_with_counts = sentences_with_counts.filter(Sentence.difficulty_level == difficulty)
    
    sentences_data = sentences_with_counts.all()
    
    if not sentences_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No available sentences to record"
        )
    
    # Configuration: nombre cible d'enregistrements par phrase
    TARGET_RECORDINGS = settings.TARGET_RECORDINGS_PER_SENTENCE
    MAX_RECORDINGS = settings.MAX_RECORDINGS_PER_SENTENCE
    
    # Si la sélection équilibrée est désactivée, utiliser l'ancienne méthode
    if not settings.BALANCED_SELECTION_ENABLED:
        sentence = random.choice([s for s, _ in sentences_data])
        return SentenceResponse.model_validate(sentence)
    
    # Sélection pondérée basée sur le nombre d'enregistrements
    # Les phrases avec moins d'enregistrements ont plus de chances d'être sélectionnées
    weights = []
    for sentence, count in sentences_data:
        if count < TARGET_RECORDINGS:
            # Poids plus élevé pour les phrases sous-enregistrées
            weight = TARGET_RECORDINGS - count + 1
        elif count < MAX_RECORDINGS:
            # Poids réduit mais pas nul pour les phrases entre target et max
            weight = 0.5
        else:
            # Poids très faible pour les phrases sur-enregistrées
            weight = 0.1
        weights.append(weight)
    
    # Sélection pondérée
    if sum(weights) == 0:
        # Si tous les poids sont à 0, sélection aléatoire simple
        selected_sentence = random.choice([s for s, _ in sentences_data])
    else:
        # Sélection pondérée
        selected_sentence = random.choices(
            [s for s, _ in sentences_data], 
            weights=weights, 
            k=1
        )[0]
    
    return SentenceResponse.model_validate(selected_sentence)

@router.get("/", response_model=List[SentenceResponse])
async def get_sentences(
    skip: int = 0,
    limit: int = 100,
    difficulty: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of sentences (for admin/development purposes)"""
    
    query = db.query(Sentence)
    
    if difficulty:
        query = query.filter(Sentence.difficulty_level == difficulty)
    
    sentences = query.offset(skip).limit(limit).all()
    
    return [SentenceResponse.model_validate(sentence) for sentence in sentences]

@router.get("/distribution-stats")
async def get_recording_distribution_stats(
    db: Session = Depends(get_db)
):
    """Get statistics about recording distribution across sentences (public stats)"""
    
    # Get recording counts per sentence (validated recordings only)
    recording_stats = db.query(
        Sentence.id,
        Sentence.text,
        Sentence.difficulty_level,
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "validated"), 
            0
        ).label('validated_count'),
        func.coalesce(
            func.count(Recording.id), 
            0
        ).label('total_count')
    ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
     .filter(Sentence.status == "available")\
     .group_by(Sentence.id)\
     .all()
    
    # Calculate distribution statistics
    validated_counts = [stat.validated_count for stat in recording_stats]
    total_counts = [stat.total_count for stat in recording_stats]
    
    target = settings.TARGET_RECORDINGS_PER_SENTENCE
    max_recordings = settings.MAX_RECORDINGS_PER_SENTENCE
    
    under_target = len([c for c in validated_counts if c < target])
    at_target = len([c for c in validated_counts if target <= c < max_recordings])
    over_target = len([c for c in validated_counts if c >= max_recordings])
    
    return {
        "total_sentences": len(recording_stats),
        "target_recordings_per_sentence": target,
        "max_recordings_per_sentence": max_recordings,
        "distribution": {
            "under_target": under_target,
            "at_target": at_target,
            "over_target": over_target
        },
        "statistics": {
            "min_recordings": min(validated_counts) if validated_counts else 0,
            "max_recordings": max(validated_counts) if validated_counts else 0,
            "avg_recordings": sum(validated_counts) / len(validated_counts) if validated_counts else 0,
            "total_validated_recordings": sum(validated_counts)
        },
        "sentences_by_count": [
            {
                "id": stat.id,
                "text": stat.text[:50] + "..." if len(stat.text) > 50 else stat.text,
                "difficulty_level": stat.difficulty_level,
                "validated_recordings": stat.validated_count,
                "total_recordings": stat.total_count
            }
            for stat in recording_stats
        ]
    }

@router.get("/{sentence_id}", response_model=SentenceResponse)
async def get_sentence(sentence_id: uuid_mod.UUID, db: Session = Depends(get_db)):
    """Get specific sentence by ID"""
    
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    
    if not sentence:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sentence not found"
        )
    
    return SentenceResponse.model_validate(sentence)
