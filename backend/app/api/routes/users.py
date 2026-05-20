from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List
import os
import io
import json
import zipfile
import logging
from pathlib import Path
from app.db.database import get_db
from app.core.auth import get_current_active_user
from app.core.config import settings
from app.models import User, Recording, Sentence
from app.schemas import UserResponse, UserUpdate, UserStats, LeaderboardResponse, LeaderboardEntry

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user(current_user: User = Depends(get_current_active_user)):
    """Get current user profile"""
    return UserResponse.model_validate(current_user)

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update current user profile"""
    
    # Check if new username is taken (if changing username)
    if user_update.username and user_update.username != current_user.username:
        existing_user = db.query(User).filter(
            User.username == user_update.username,
            User.id != current_user.id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        current_user.username = user_update.username
    
    if user_update.is_active is not None:
        current_user.is_active = user_update.is_active
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse.model_validate(current_user)

@router.get("/me/stats", response_model=UserStats)
async def get_user_stats(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user recording statistics"""
    
    # Count recordings by status
    total_recordings = db.query(Recording).filter(Recording.user_id == current_user.id).count()
    
    validated_recordings = db.query(Recording).filter(
        Recording.user_id == current_user.id,
        Recording.status == "validated"
    ).count()
    
    rejected_recordings = db.query(Recording).filter(
        Recording.user_id == current_user.id,
        Recording.status == "rejected"
    ).count()
    
    pending_recordings = db.query(Recording).filter(
        Recording.user_id == current_user.id,
        Recording.status == "pending"
    ).count()
    
    # Calculate total duration
    total_duration_result = db.query(func.sum(Recording.duration)).filter(
        Recording.user_id == current_user.id,
        Recording.status == "validated"
    ).scalar()
    
    total_duration = total_duration_result if total_duration_result else 0.0
    
    return UserStats(
        total_recordings=total_recordings,
        validated_recordings=validated_recordings,
        rejected_recordings=rejected_recordings,
        pending_recordings=pending_recordings,
        total_duration=total_duration
    )

@router.delete("/me")
async def delete_current_user(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete current user account (GDPR compliance) — GDPR-001"""
    
    # Fetch recordings to delete audio files from disk
    recordings = db.query(Recording).filter(Recording.user_id == current_user.id).all()
    for recording in recordings:
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        if os.path.exists(filepath):
            try:
                os.remove(filepath)
            except OSError as e:
                logger.warning(f"Failed to delete audio file {filepath}: {e}")
    
    # Delete recordings from DB, then user
    db.query(Recording).filter(Recording.user_id == current_user.id).delete()
    db.delete(current_user)
    db.commit()
    
    return {"message": "User account deleted successfully"}

@router.get("/me/export")
async def export_user_data(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Export all user data as ZIP (GDPR compliance) — GDPR-002"""
    from fastapi.responses import StreamingResponse
    
    # Build user profile JSON
    profile = {
        "id": str(current_user.id),
        "username": current_user.username,
        "gender": current_user.gender,
        "age_range": current_user.age_range,
        "role": current_user.role,
        "is_active": current_user.is_active,
        "consent_given": current_user.consent_given,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        "updated_at": current_user.updated_at.isoformat() if current_user.updated_at else None,
    }
    
    # Fetch recordings with sentence text
    recordings = (
        db.query(Recording, Sentence.text)
        .join(Sentence, Recording.sentence_id == Sentence.id)
        .filter(Recording.user_id == current_user.id)
        .all()
    )
    
    recordings_data = []
    for recording, sentence_text in recordings:
        recordings_data.append({
            "id": str(recording.id),
            "sentence_text": sentence_text,
            "filepath": recording.filepath,
            "duration": recording.duration,
            "status": recording.status,
            "quality_score": recording.quality_score,
            "created_at": recording.created_at.isoformat() if recording.created_at else None,
        })
    
    # Create ZIP in memory
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("profile.json", json.dumps(profile, indent=2, ensure_ascii=False))
        zf.writestr("recordings.json", json.dumps(recordings_data, indent=2, ensure_ascii=False))
        
        # Add audio files
        for recording, _ in recordings:
            filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
            if os.path.exists(filepath):
                zf.write(filepath, f"audio/{os.path.basename(recording.filepath)}")
    
    buffer.seek(0)
    return StreamingResponse(
        buffer,
        media_type="application/zip",
        headers={"Content-Disposition": f"attachment; filename=user_data_{current_user.id}.zip"}
    )

@router.post("/me/revoke-consent")
async def revoke_consent(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Revoke GDPR consent and delete all data — GDPR-004"""
    
    # Delete audio files from disk
    recordings = db.query(Recording).filter(Recording.user_id == current_user.id).all()
    for recording in recordings:
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        if os.path.exists(filepath):
            try:
                os.remove(filepath)
            except OSError as e:
                logger.warning(f"Failed to delete audio file {filepath}: {e}")
    
    # Delete recordings, revoke consent, then delete user
    db.query(Recording).filter(Recording.user_id == current_user.id).delete()
    current_user.consent_given = False
    db.delete(current_user)
    db.commit()
    
    return {"message": "Consent revoked and all data deleted"}

@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user leaderboard based on validated recordings"""
    
    # Get users with their validated recordings count and total duration
    user_stats = db.query(
        User.id,
        User.username,
        func.count(Recording.id).label('validated_recordings'),
        func.coalesce(func.sum(Recording.duration), 0).label('total_duration')
    ).outerjoin(
        Recording, 
        (Recording.user_id == User.id) & (Recording.status == "validated")
    ).filter(
        User.is_active == True,
        User.role == "user"  # Only regular users, not admins/moderators
    ).group_by(
        User.id, User.username
    ).order_by(
        desc('validated_recordings'),
        desc('total_duration')
    ).limit(limit).all()
    
    # Create leaderboard entries with ranks
    entries = []
    current_user_rank = None
    
    for rank, user_stat in enumerate(user_stats, 1):
        is_current_user = user_stat.id == current_user.id
        if is_current_user:
            current_user_rank = rank
            
        entries.append(LeaderboardEntry(
            rank=rank,
            user_id=user_stat.id,
            username=user_stat.username,
            validated_recordings=user_stat.validated_recordings,
            total_duration=float(user_stat.total_duration),
            is_current_user=is_current_user
        ))
    
    # If current user is not in top results, calculate their rank separately
    if current_user_rank is None:
        # Simple rank calculation: count users with better stats
        current_user_validated = db.query(func.count(Recording.id)).filter(
            Recording.user_id == current_user.id,
            Recording.status == "validated"
        ).scalar() or 0
        
        current_user_duration = db.query(func.coalesce(func.sum(Recording.duration), 0)).filter(
            Recording.user_id == current_user.id,
            Recording.status == "validated"
        ).scalar() or 0
        
        # Count users with more validated recordings
        users_with_more_recordings = db.query(func.count(func.distinct(User.id))).select_from(
            User
        ).join(
            Recording,
            (Recording.user_id == User.id) & (Recording.status == "validated")
        ).filter(
            User.is_active == True,
            User.role == "user"
        ).group_by(
            User.id
        ).having(
            func.count(Recording.id) > current_user_validated
        ).count()
        
        # Count users with same recordings but more duration
        users_with_same_recordings_more_duration = db.query(func.count(func.distinct(User.id))).select_from(
            User
        ).join(
            Recording,
            (Recording.user_id == User.id) & (Recording.status == "validated")
        ).filter(
            User.is_active == True,
            User.role == "user"
        ).group_by(
            User.id
        ).having(
            func.count(Recording.id) == current_user_validated,
            func.coalesce(func.sum(Recording.duration), 0) > current_user_duration
        ).count()
        
        current_user_rank = users_with_more_recordings + users_with_same_recordings_more_duration + 1
    
    # Get total active users count
    total_users = db.query(User).filter(
        User.is_active == True,
        User.role == "user"
    ).count()
    
    return LeaderboardResponse(
        entries=entries,
        current_user_rank=current_user_rank,
        total_users=total_users
    )
