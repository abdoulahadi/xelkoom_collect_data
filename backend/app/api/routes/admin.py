from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime, timedelta
import os
import uuid as uuid_mod
from pathlib import Path
from app.db.database import get_db
from app.core.auth import get_current_admin_user
from app.core.config import settings
from app.models import User, Sentence, Recording
from app.schemas import (
    AdminStats, SentenceCreate, SentenceResponse, SentenceUpdate,
    RecordingWithDetails, RecordingUpdate, BulkSentenceCreate,
    BulkModerationRequest, UsersPaginatedResponse, UserWithStats, AdminUserCreate,
    SentenceWithStats, SentencesPaginatedResponse
)

router = APIRouter()

@router.get("/stats", response_model=AdminStats)
async def get_admin_stats(
    period: Optional[str] = Query(default="30d", pattern="^(7d|30d|90d|all)$"),
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get platform statistics for admin dashboard"""
    
    # ADM-006: Compute period filter date
    period_days = {"7d": 7, "30d": 30, "90d": 90}
    period_start = None
    if period in period_days:
        period_start = datetime.now() - timedelta(days=period_days[period])
    
    # User statistics
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    
    # Sentence statistics
    total_sentences = db.query(Sentence).count()
    available_sentences = db.query(Sentence).filter(
        Sentence.status == "available"
    ).count()
    
    # Recording statistics — apply period filter
    rec_query = db.query(Recording)
    if period_start:
        rec_query = rec_query.filter(Recording.created_at >= period_start)
    
    total_recordings = rec_query.count()
    pending_recordings = rec_query.filter(
        Recording.status == "pending"
    ).count()
    validated_recordings = rec_query.filter(
        Recording.status == "validated"
    ).count()
    rejected_recordings = rec_query.filter(
        Recording.status == "rejected"
    ).count()
    
    # Total audio duration
    duration_query = db.query(func.sum(Recording.duration)).filter(
        Recording.status == "validated"
    )
    if period_start:
        duration_query = duration_query.filter(Recording.created_at >= period_start)
    total_duration_result = duration_query.scalar()
    total_audio_duration = total_duration_result if total_duration_result else 0.0
    
    # Daily recordings (use period filter)
    chart_start = period_start if period_start else datetime.now() - timedelta(days=30)
    daily_recordings = db.query(
        func.date(Recording.created_at).label('date'),
        func.count(Recording.id).label('count')
    ).filter(
        Recording.created_at >= chart_start
    ).group_by(
        func.date(Recording.created_at)
    ).all()
    
    daily_recordings_list = [
        {"date": str(record.date), "count": record.count}
        for record in daily_recordings
    ]
    
    return AdminStats(
        total_users=total_users,
        active_users=active_users,
        total_sentences=total_sentences,
        available_sentences=available_sentences,
        total_recordings=total_recordings,
        pending_recordings=pending_recordings,
        validated_recordings=validated_recordings,
        rejected_recordings=rejected_recordings,
        total_audio_duration=total_audio_duration,
        daily_recordings=daily_recordings_list
    )

@router.get("/recordings")
async def get_recordings_for_moderation(
    page: int = Query(default=1, ge=1),
    size: int = Query(default=50, ge=1, le=100),
    status: Optional[str] = Query(default=None),
    user_id: Optional[str] = Query(default=None),
    sentence_id: Optional[str] = Query(default=None),
    date_from: Optional[str] = Query(default=None),
    date_to: Optional[str] = Query(default=None),
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get recordings for moderation with pagination and filters"""
    
    query = db.query(Recording).options(
        joinedload(Recording.user),
        joinedload(Recording.sentence)
    )
    
    # Apply filters
    if status:
        query = query.filter(Recording.status == status)
    
    if user_id:
        query = query.filter(Recording.user_id == user_id)
    
    if sentence_id:
        query = query.filter(Recording.sentence_id == sentence_id)
    
    if date_from:
        try:
            from_date = datetime.fromisoformat(date_from)
            query = query.filter(Recording.created_at >= from_date)
        except ValueError:
            pass
    
    if date_to:
        try:
            to_date = datetime.fromisoformat(date_to)
            query = query.filter(Recording.created_at <= to_date)
        except ValueError:
            pass
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    skip = (page - 1) * size
    recordings = query.order_by(desc(Recording.created_at)).offset(skip).limit(size).all()
    
    # Calculate total pages
    pages = (total + size - 1) // size
    
    # Convert to response format with relations
    recording_items = []
    for recording in recordings:
        recording_dict = {
            "id": recording.id,
            "user_id": recording.user_id,
            "sentence_id": recording.sentence_id,
            "filepath": recording.filepath,
            "original_filename": recording.original_filename,
            "duration": recording.duration,
            "file_size": recording.file_size,
            "sample_rate": recording.sample_rate,
            "status": recording.status,
            "quality_score": recording.quality_score,
            "admin_notes": recording.admin_notes,
            "audio_metadata": recording.audio_metadata,
            "created_at": recording.created_at.isoformat() if recording.created_at else None,
            "updated_at": recording.updated_at.isoformat() if recording.updated_at else None,
        }
        
        # Add user info if available
        if recording.user:
            recording_dict["user"] = {
                "id": recording.user.id,
                "username": recording.user.username,
                "gender": recording.user.gender,
                "age_range": recording.user.age_range,
                "role": recording.user.role,
                "is_active": recording.user.is_active,
                "consent_given": recording.user.consent_given,
                "created_at": recording.user.created_at.isoformat() if recording.user.created_at else None,
                "updated_at": recording.user.updated_at.isoformat() if recording.user.updated_at else None,
                "recording_count": 0,  # Can be calculated if needed
                "validated_recordings": 0  # Can be calculated if needed
            }
        
        # Add sentence info if available
        if recording.sentence:
            recording_dict["sentence"] = {
                "id": recording.sentence.id,
                "text": recording.sentence.text,
                "language": recording.sentence.language,
                "category": getattr(recording.sentence, 'category', None),
                "difficulty_level": recording.sentence.difficulty_level,
                "created_at": recording.sentence.created_at.isoformat() if recording.sentence.created_at else None,
                "updated_at": recording.sentence.updated_at.isoformat() if recording.sentence.updated_at else None,
                "is_active": getattr(recording.sentence, 'is_active', True),
                "recording_count": 0,  # Can be calculated if needed
                "average_quality_score": None  # Can be calculated if needed
            }
        
        recording_items.append(recording_dict)
    
    return {
        "items": recording_items,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }

@router.put("/recordings/{recording_id}", response_model=RecordingWithDetails)
async def moderate_recording(
    recording_id: uuid_mod.UUID,
    update_data: RecordingUpdate,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Moderate a recording (validate/reject)"""
    
    recording = db.query(Recording).filter(Recording.id == recording_id).first()
    
    if not recording:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recording not found"
        )
    
    if update_data.status:
        # Convert enum to string for SQLite compatibility
        recording.status = update_data.status.value if hasattr(update_data.status, 'value') else str(update_data.status)
    
    if update_data.quality_score is not None:
        recording.quality_score = update_data.quality_score
    
    if update_data.admin_notes:
        recording.admin_notes = update_data.admin_notes
    
    db.commit()
    db.refresh(recording)
    
    return RecordingWithDetails.model_validate(recording)

@router.post("/recordings/bulk-moderate", response_model=List[RecordingWithDetails])
async def bulk_moderate_recordings(
    request: BulkModerationRequest,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Bulk moderate recordings (validate/reject multiple recordings)"""
    
    # Get all recordings by IDs
    recordings = db.query(Recording).filter(
        Recording.id.in_(request.recording_ids)
    ).options(
        joinedload(Recording.user),
        joinedload(Recording.sentence)
    ).all()
    
    if not recordings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No recordings found with the provided IDs"
        )
    
    if len(recordings) != len(request.recording_ids):
        found_ids = [str(r.id) for r in recordings]
        missing_ids = [str(rid) for rid in request.recording_ids if str(rid) not in found_ids]
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Some recordings not found: {', '.join(missing_ids)}"
        )
    
    # Update all recordings
    updated_recordings = []
    for recording in recordings:
        # Convert enum to string for SQLite compatibility
        recording.status = request.status.value if hasattr(request.status, 'value') else str(request.status)
        
        if request.notes:
            recording.admin_notes = request.notes
            
        updated_recordings.append(recording)
    
    db.commit()
    
    # Refresh and return updated recordings
    for recording in updated_recordings:
        db.refresh(recording)
    
    return [RecordingWithDetails.model_validate(recording) for recording in updated_recordings]

@router.post("/sentences", response_model=SentenceResponse)
async def create_sentence(
    sentence_data: SentenceCreate,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new sentence"""
    
    sentence = Sentence(
        text=sentence_data.text,
        language=sentence_data.language,
        difficulty_level=sentence_data.difficulty_level,
        status="available"
    )
    
    db.add(sentence)
    db.commit()
    db.refresh(sentence)
    
    return SentenceResponse.model_validate(sentence)

@router.post("/sentences/bulk", response_model=List[SentenceResponse])
async def create_sentences_bulk(
    bulk_data: BulkSentenceCreate,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Create multiple sentences at once"""
    
    sentences = []
    for text in bulk_data.sentences:
        sentence = Sentence(
            text=text,
            language="wo",  # Default to Wolof
            difficulty_level="easy",  # Default difficulty
            status="available"
        )
        sentences.append(sentence)
    
    db.add_all(sentences)
    db.commit()
    
    for sentence in sentences:
        db.refresh(sentence)
    
    return [SentenceResponse.model_validate(sentence) for sentence in sentences]

@router.get("/sentences", response_model=SentencesPaginatedResponse)
async def get_all_sentences(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[str] = None,
    difficulty: Optional[str] = Query(None, description="Filter by difficulty level"),
    search: Optional[str] = Query(None, description="Search by sentence text"),
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get all sentences for admin management with recording statistics"""
    
    # Build base query with recording counts
    query = db.query(
        Sentence,
        func.coalesce(func.count(Recording.id), 0).label('recording_count'),
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "validated"), 
            0
        ).label('validated_recordings'),
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "pending"), 
            0
        ).label('pending_recordings'),
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "rejected"), 
            0
        ).label('rejected_recordings')
    ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
     .group_by(Sentence.id)
    
    if status_filter:
        query = query.filter(Sentence.status == status_filter)
    if difficulty:
        query = query.filter(Sentence.difficulty_level == difficulty)
    if search:
        query = query.filter(Sentence.text.ilike(f"%{search}%"))
    
    # Get total count for pagination
    total_query = db.query(Sentence)
    if status_filter:
        total_query = total_query.filter(Sentence.status == status_filter)
    if difficulty:
        total_query = total_query.filter(Sentence.difficulty_level == difficulty)
    if search:
        total_query = total_query.filter(Sentence.text.ilike(f"%{search}%"))
    total = total_query.count()
    
    # Apply pagination
    results = query.offset(skip).limit(limit).all()
    
    # Build response with statistics
    sentences_with_stats = []
    for sentence, recording_count, validated_count, pending_count, rejected_count in results:
        sentence_dict = {
            "id": sentence.id,
            "text": sentence.text,
            "language": sentence.language,
            "difficulty_level": sentence.difficulty_level,
            "status": sentence.status,
            "created_at": sentence.created_at,
            "updated_at": sentence.updated_at,
            "recording_count": recording_count,
            "validated_recordings": validated_count,
            "pending_recordings": pending_count,
            "rejected_recordings": rejected_count
        }
        sentences_with_stats.append(SentenceWithStats(**sentence_dict))
    
    pages = (total + limit - 1) // limit
    page = (skip // limit) + 1
    
    return SentencesPaginatedResponse(
        items=sentences_with_stats,
        total=total,
        page=page,
        size=limit,
        pages=pages
    )

@router.put("/sentences/{sentence_id}", response_model=SentenceResponse)
async def update_sentence(
    sentence_id: uuid_mod.UUID,
    update_data: SentenceUpdate,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Update a sentence"""
    
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    
    if not sentence:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sentence not found"
        )
    
    if update_data.text:
        sentence.text = update_data.text
    
    if update_data.status:
        sentence.status = update_data.status
    
    if update_data.difficulty_level:
        sentence.difficulty_level = update_data.difficulty_level
    
    db.commit()
    db.refresh(sentence)
    
    return SentenceResponse.model_validate(sentence)

@router.delete("/sentences/{sentence_id}")
async def delete_sentence(
    sentence_id: uuid_mod.UUID,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a sentence (only if no recordings exist)"""
    
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    
    if not sentence:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sentence not found"
        )
    
    # Check if any recordings exist for this sentence
    recordings_count = db.query(Recording).filter(Recording.sentence_id == sentence_id).count()
    
    if recordings_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete sentence with existing recordings"
        )
    
    db.delete(sentence)
    db.commit()
    
    return {"message": "Sentence deleted successfully"}

@router.get("/export/metadata")
async def export_recordings_metadata(
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Export validated recordings metadata for TTS training"""
    
    recordings = db.query(Recording).filter(
        Recording.status == "validated"
    ).all()
    
    # Create LJSpeech format
    ljspeech_data = []
    for recording in recordings:
        ljspeech_data.append({
            "filename": recording.filepath,
            "text": recording.sentence.text,
            "duration": recording.duration,
            "user_id": str(recording.user_id),
            "quality_score": recording.quality_score
        })
    
    return {
        "format": "ljspeech",
        "total_recordings": len(ljspeech_data),
        "data": ljspeech_data
    }

# User management routes
@router.get("/users", response_model=UsersPaginatedResponse)
async def get_all_users(
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = Query(None),
    is_admin: Optional[bool] = Query(None),
    search: Optional[str] = Query(None, description="Search by username")
):
    """Get all users with pagination and filtering — DB-006: single aggregated query"""
    
    # Base filter query for counting total
    base_query = db.query(User)
    if is_active is not None:
        base_query = base_query.filter(User.is_active == is_active)
    if is_admin is not None:
        base_query = base_query.filter(User.is_admin == is_admin)
    if search:
        base_query = base_query.filter(User.username.ilike(f"%{search}%"))
    
    total = base_query.count()
    
    # DB-006: Single aggregated query with outerjoin instead of N+1 queries
    offset = (page - 1) * size
    
    # Subquery for recording counts
    from sqlalchemy import case
    users_with_stats = (
        db.query(
            User,
            func.count(Recording.id).label("recording_count"),
            func.count(case((Recording.status == "validated", Recording.id))).label("validated_recordings"),
        )
        .outerjoin(Recording, Recording.user_id == User.id)
    )
    
    # Apply same filters
    if is_active is not None:
        users_with_stats = users_with_stats.filter(User.is_active == is_active)
    if is_admin is not None:
        users_with_stats = users_with_stats.filter(User.is_admin == is_admin)
    if search:
        users_with_stats = users_with_stats.filter(User.username.ilike(f"%{search}%"))
    
    results = (
        users_with_stats
        .group_by(User.id)
        .offset(offset)
        .limit(size)
        .all()
    )
    
    users_data = []
    for user, recording_count, validated_count in results:
        users_data.append(UserWithStats(
            id=user.id,
            username=user.username,
            gender=user.gender,
            age_range=user.age_range,
            role=user.role,
            is_admin=user.is_admin,
            is_active=user.is_active,
            consent_given=user.consent_given,
            created_at=user.created_at,
            updated_at=user.updated_at,
            recording_count=recording_count,
            validated_recordings=validated_count
        ))
    
    return UsersPaginatedResponse(
        items=users_data,
        total=total,
        page=page,
        size=size,
        pages=(total + size - 1) // size,
        active_users=db.query(User).filter(User.is_active == True).count(),
        admin_users=db.query(User).filter(User.role == "admin").count(),
        inactive_users=db.query(User).filter(User.is_active == False).count()
    )

@router.post("/users", response_model=UserWithStats)
async def create_user(
    user_data: AdminUserCreate,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new user (admin only)"""
    
    # Check if username already exists
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists"
        )
    
    # Create new user
    new_user = User(
        username=user_data.username,
        gender=user_data.gender,
        age_range=user_data.age_range,
        is_admin=user_data.is_admin or False,
        role=user_data.role or 'user',
        is_active=user_data.is_active if user_data.is_active is not None else True,
        consent_given=user_data.consent_given
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Get user's stats (will be 0 for new user)
    recording_count = 0
    validated_count = 0
    
    return UserWithStats(
        id=new_user.id,
        username=new_user.username,
        gender=new_user.gender,
        age_range=new_user.age_range,
        is_admin=new_user.is_admin,
        is_active=new_user.is_active,
        consent_given=new_user.consent_given,
        created_at=new_user.created_at,
        updated_at=new_user.updated_at,
        recording_count=recording_count,
        validated_recordings=validated_count
    )

@router.get("/users/{user_id}")
async def get_user_by_id(
    user_id: uuid_mod.UUID,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get user details by ID"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get user's recording stats
    recording_count = db.query(Recording).filter(Recording.user_id == user.id).count()
    validated_count = db.query(Recording).filter(
        Recording.user_id == user.id,
        Recording.status == "validated"
    ).count()
    
    return {
        "id": str(user.id),
        "username": user.username,
        "gender": user.gender,
        "age_range": user.age_range,
        "is_admin": user.is_admin,
        "is_active": user.is_active,
        "consent_given": user.consent_given,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
        "recording_count": recording_count,
        "validated_recordings": validated_count
    }

@router.patch("/users/{user_id}")
async def update_user(
    user_id: uuid_mod.UUID,
    updates: dict,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Update user details"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update allowed fields
    allowed_fields = ['is_active', 'is_admin']
    for field, value in updates.items():
        if field in allowed_fields and hasattr(user, field):
            setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    return {
        "id": str(user.id),
        "username": user.username,
        "gender": user.gender,
        "age_range": user.age_range,
        "is_admin": user.is_admin,
        "is_active": user.is_active,
        "consent_given": user.consent_given,
        "created_at": user.created_at,
        "updated_at": user.updated_at
    }

@router.post("/users/{user_id}/activate")
async def activate_user(
    user_id: uuid_mod.UUID,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Activate a user"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = True
    db.commit()
    db.refresh(user)
    
    return {
        "id": str(user.id),
        "username": user.username,
        "is_active": user.is_active,
        "message": "User activated successfully"
    }

@router.post("/users/{user_id}/deactivate")
async def deactivate_user(
    user_id: uuid_mod.UUID,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Deactivate a user"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = False
    db.commit()
    db.refresh(user)
    
    return {
        "id": str(user.id),
        "username": user.username,
        "is_active": user.is_active,
        "message": "User deactivated successfully"
    }

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: uuid_mod.UUID,
    hard_delete: bool = Query(False, description="If true, permanently delete user data (GDPR)"),
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a user (soft delete by default, hard delete with anonymization for GDPR) — GDPR-003"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not hard_delete:
        # Soft delete - just deactivate the user
        user.is_active = False
        db.commit()
        return {"message": "User deactivated successfully"}
    
    # Hard delete: delete audio files, anonymize, then remove
    import logging
    _logger = logging.getLogger(__name__)
    
    recordings = db.query(Recording).filter(Recording.user_id == user.id).all()
    for recording in recordings:
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        if os.path.exists(filepath):
            try:
                os.remove(filepath)
            except OSError as e:
                _logger.warning(f"Failed to delete audio file {filepath}: {e}")
    
    # Delete recordings and user permanently
    db.query(Recording).filter(Recording.user_id == user.id).delete()
    db.delete(user)
    db.commit()
    
    return {"message": "User and all associated data permanently deleted"}

@router.get("/recordings/{recording_id}/audio")
async def get_recording_audio(
    recording_id: uuid_mod.UUID,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Serve audio file for a recording (auth via Authorization header)"""
    
    # Vérifier que l'enregistrement existe
    recording = db.query(Recording).filter(Recording.id == recording_id).first()
    if not recording:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recording not found"
        )
    
    # Construire le chemin complet du fichier audio avec protection path traversal
    storage_base = Path(settings.AUDIO_STORAGE_PATH).resolve()
    if os.path.isabs(recording.filepath):
        audio_path = Path(recording.filepath).resolve()
    else:
        audio_path = (storage_base / recording.filepath).resolve()
    
    # SEC-012: Vérifier que le chemin résolu est dans le répertoire de stockage
    if not str(audio_path).startswith(str(storage_base)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    # Vérifier que le fichier existe
    if not audio_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Audio file not found: {audio_path}"
        )
    
    # Déterminer le type MIME basé sur l'extension
    file_extension = audio_path.suffix.lower()
    if file_extension == '.wav':
        media_type = "audio/wav"
    elif file_extension == '.mp3':
        media_type = "audio/mpeg"
    elif file_extension == '.flac':
        media_type = "audio/flac"
    else:
        media_type = "application/octet-stream"
    
    # Retourner le fichier audio
    return FileResponse(
        path=str(audio_path),
        media_type=media_type,
        headers={
            "Content-Disposition": f"inline; filename={recording.original_filename or f'recording_{recording_id}.wav'}",
            "Accept-Ranges": "bytes"
        }
    )

# System endpoints for Settings page
@router.get("/system/health")
async def get_system_health(
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get system health information"""
    import psutil
    import sqlite3
    from pathlib import Path
    
    try:
        # Database health
        db_status = "healthy"
        db_size = 0
        try:
            db_path = Path("xelkoom.db")
            if db_path.exists():
                db_size = db_path.stat().st_size
            
            # Test database connection
            db.execute("SELECT 1").scalar()
        except Exception as e:
            db_status = f"error: {str(e)}"
        
        # Audio storage health
        audio_storage_path = Path(settings.AUDIO_STORAGE_PATH)
        audio_storage_size = 0
        audio_file_count = 0
        if audio_storage_path.exists():
            for file_path in audio_storage_path.rglob("*.wav"):
                audio_storage_size += file_path.stat().st_size
                audio_file_count += 1
        
        # System resources
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('.')
        
        return {
            "status": "healthy" if db_status == "healthy" else "degraded",
            "timestamp": datetime.now().isoformat(),
            "database": {
                "status": db_status,
                "size_bytes": db_size,
                "connection_pool": "N/A (SQLite)"
            },
            "storage": {
                "audio_files_count": audio_file_count,
                "audio_storage_size_bytes": audio_storage_size,
                "disk_total_bytes": disk.total,
                "disk_used_bytes": disk.used,
                "disk_free_bytes": disk.free,
                "disk_usage_percent": disk.percent
            },
            "system": {
                "memory_total_bytes": memory.total,
                "memory_used_bytes": memory.used,
                "memory_available_bytes": memory.available,
                "memory_usage_percent": memory.percent,
                "cpu_count": psutil.cpu_count()
            }
        }
    except Exception as e:
        return {
            "status": "error",
            "timestamp": datetime.now().isoformat(),
            "error": str(e)
        }

@router.get("/system/config")
async def get_system_config(
    admin_user: User = Depends(get_current_admin_user)
):
    """Get system configuration (safe values only)"""
    return {
        "audio": {
            "storage_path": settings.AUDIO_STORAGE_PATH,
            "max_size_mb": settings.MAX_AUDIO_SIZE_MB
        },
        "rate_limiting": {
            "enabled": settings.ENABLE_RATE_LIMITING,
            "default_limit": settings.DEFAULT_RATE_LIMIT
        },
        "features": {
            "whisper_validation": settings.ENABLE_WHISPER_VALIDATION,
            "whisper_model": settings.WHISPER_MODEL,
            "metrics_enabled": settings.ENABLE_METRICS
        },
        "environment": {
            "debug": settings.DEBUG,
            "environment": settings.ENVIRONMENT,
            "log_level": settings.LOG_LEVEL
        },
        "security": {
            "token_expire_minutes": settings.ACCESS_TOKEN_EXPIRE_MINUTES,
            "algorithm": settings.ALGORITHM
        }
    }

@router.get("/system/logs")
async def get_system_logs(
    page: int = Query(default=1, ge=1),
    size: int = Query(default=100, ge=1, le=500),
    level: Optional[str] = Query(default=None),
    admin_user: User = Depends(get_current_admin_user)
):
    """Get system logs from JSON log file"""
    from app.core.json_logger import read_logs
    return read_logs(page=page, size=size, level=level)

@router.get("/balance-config")
async def get_balance_configuration(
    admin_user: User = Depends(get_current_admin_user)
):
    """Get current balance configuration"""
    return {
        "target_recordings_per_sentence": settings.TARGET_RECORDINGS_PER_SENTENCE,
        "max_recordings_per_sentence": settings.MAX_RECORDINGS_PER_SENTENCE,
        "balanced_selection_enabled": settings.BALANCED_SELECTION_ENABLED
    }

@router.get("/recording-distribution")
async def get_detailed_recording_distribution(
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get detailed recording distribution analysis for admin"""
    
    # Get recording counts per sentence with more details
    distribution_data = db.query(
        Sentence.id,
        Sentence.text,
        Sentence.difficulty_level,
        Sentence.language,
        Sentence.created_at,
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "validated"), 
            0
        ).label('validated_count'),
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "pending"), 
            0
        ).label('pending_count'),
        func.coalesce(
            func.count(Recording.id).filter(Recording.status == "rejected"), 
            0
        ).label('rejected_count'),
        func.coalesce(
            func.count(Recording.id), 
            0
        ).label('total_count')
    ).outerjoin(Recording, Sentence.id == Recording.sentence_id)\
     .filter(Sentence.status == "available")\
     .group_by(Sentence.id)\
     .order_by(func.count(Recording.id).filter(Recording.status == "validated"))\
     .all()
    
    target = settings.TARGET_RECORDINGS_PER_SENTENCE
    max_recordings = settings.MAX_RECORDINGS_PER_SENTENCE
    
    # Categorize sentences
    under_target = []
    at_target = []
    over_target = []
    
    for data in distribution_data:
        sentence_info = {
            "id": data.id,
            "text": data.text,
            "difficulty_level": data.difficulty_level,
            "language": data.language,
            "validated_recordings": data.validated_count,
            "pending_recordings": data.pending_count,
            "rejected_recordings": data.rejected_count,
            "total_recordings": data.total_count,
            "created_at": data.created_at.isoformat() if data.created_at else None
        }
        
        if data.validated_count < target:
            under_target.append(sentence_info)
        elif data.validated_count < max_recordings:
            at_target.append(sentence_info)
        else:
            over_target.append(sentence_info)
    
    return {
        "configuration": {
            "target_recordings_per_sentence": target,
            "max_recordings_per_sentence": max_recordings,
            "balanced_selection_enabled": settings.BALANCED_SELECTION_ENABLED
        },
        "summary": {
            "total_sentences": len(distribution_data),
            "under_target_count": len(under_target),
            "at_target_count": len(at_target),
            "over_target_count": len(over_target)
        },
        "categories": {
            "under_target": under_target,
            "at_target": at_target,
            "over_target": over_target
        }
    }

@router.get("/sentences/distribution-stats")
async def get_sentences_distribution_stats_admin(
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get detailed statistics about recording distribution across sentences (Admin only)"""
    
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


@router.post("/data-retention")
async def run_data_retention(
    dry_run: bool = Query(True, description="If true, report what would be done without making changes"),
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """Run GDPR data retention tasks (admin only)."""
    from app.services.data_retention import run_all_retention_tasks

    upload_dir = getattr(settings, "UPLOAD_DIR", os.path.join(os.path.dirname(__file__), "..", "..", "..", "uploads", "audio"))
    return run_all_retention_tasks(db, upload_dir, dry_run=dry_run)
