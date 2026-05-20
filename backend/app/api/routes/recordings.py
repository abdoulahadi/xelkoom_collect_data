from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import os
import uuid as uuid_mod
from app.db.database import get_db, SessionLocal
from app.core.auth import get_current_active_user
from app.core.config import settings
from app.models import User, Recording, Sentence
from app.schemas import RecordingResponse, RecordingCreate, RecordingWithDetails
from app.services.audio_processing import audio_processor
from app.services.storage_service import storage_service
from app.services.whisper_validation import whisper_validator
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


def _process_audio_background(recording_id: str, file_path: str, sentence_text: str):
    """Background task to process audio after upload — API-001"""
    import asyncio
    db = SessionLocal()
    try:
        recording = db.query(Recording).filter(Recording.id == recording_id).first()
        if not recording:
            logger.error(f"Recording {recording_id} not found for background processing")
            return
        
        try:
            # Run async Whisper validation from sync context
            if os.path.exists(file_path):
                loop = asyncio.new_event_loop()
                try:
                    whisper_validation = loop.run_until_complete(
                        whisper_validator.validate_audio_text_match(file_path, sentence_text)
                    )
                finally:
                    loop.close()
                
                if whisper_validation:
                    recording.audio_metadata = {
                        **(recording.audio_metadata or {}),
                        "whisper_validation": whisper_validation
                    }
            
            db.commit()
            logger.info(f"Background processing completed for recording {recording_id}")
        except Exception as e:
            logger.error(f"Background processing failed for recording {recording_id}: {e}")
            db.commit()
    finally:
        db.close()

@router.post("/", response_model=RecordingResponse)
async def create_recording(
    sentence_id: uuid_mod.UUID,
    audio_file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """Upload and process audio recording"""
    
    # Verify sentence exists
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    if not sentence:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sentence not found"
        )
    
    # Check if user already recorded this sentence
    existing_recording = db.query(Recording).filter(
        Recording.user_id == current_user.id,
        Recording.sentence_id == sentence_id
    ).first()
    
    if existing_recording:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already recorded this sentence"
        )
    
    try:
        # Process audio file
        filename, metadata = await audio_processor.process_audio_upload(
            audio_file, str(current_user.id)
        )
        
        # The audio file is already saved locally by the processor
        # No need to call storage_service.upload_audio_file again
        storage_url = filename  # Use the processed filename as the path
        
        # Convert NumPy types to Python types for database compatibility
        duration = metadata.get("duration")
        file_size = metadata.get("file_size_mb")
        sample_rate = metadata.get("sample_rate")
        quality_score = metadata.get("quality_score")
        
        # Ensure all numeric values are Python types, not NumPy types
        if duration is not None:
            duration = float(duration)
        if file_size is not None:
            file_size = float(file_size)
        if sample_rate is not None:
            sample_rate = int(sample_rate)
        if quality_score is not None:
            quality_score = float(quality_score)
        
        # Create recording record
        recording = Recording(
            user_id=current_user.id,
            sentence_id=sentence_id,
            filepath=storage_url or filename,
            original_filename=metadata.get("original_filename"),
            duration=duration,
            file_size=file_size,
            sample_rate=sample_rate,
            quality_score=quality_score,
            status="pending"
        )
        
        db.add(recording)
        db.commit()
        db.refresh(recording)
        
        # API-001: Run Whisper validation in background instead of blocking
        processed_file_path = os.path.join(settings.AUDIO_STORAGE_PATH, filename)
        background_tasks.add_task(
            _process_audio_background,
            str(recording.id),
            processed_file_path,
            sentence.text
        )
        
        logger.info(f"Recording created: {recording.id} by user {current_user.username}")
        
        return RecordingResponse.model_validate(recording)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Recording creation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process recording"
        )

@router.get("/", response_model=List[RecordingResponse])
async def get_my_recordings(
    skip: int = 0,
    limit: int = 100,
    status_filter: str = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's recordings"""
    
    query = db.query(Recording).filter(Recording.user_id == current_user.id)
    
    if status_filter:
        query = query.filter(Recording.status == status_filter)
    
    recordings = query.offset(skip).limit(limit).all()
    
    return [RecordingResponse.model_validate(recording) for recording in recordings]

@router.get("/{recording_id}", response_model=RecordingWithDetails)
async def get_recording(
    recording_id: uuid_mod.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get specific recording by ID"""
    
    recording = db.query(Recording).filter(
        Recording.id == recording_id,
        Recording.user_id == current_user.id
    ).first()
    
    if not recording:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recording not found"
        )
    
    return RecordingWithDetails.model_validate(recording)

@router.delete("/{recording_id}")
async def delete_recording(
    recording_id: uuid_mod.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a recording (only if pending)"""
    
    recording = db.query(Recording).filter(
        Recording.id == recording_id,
        Recording.user_id == current_user.id
    ).first()
    
    if not recording:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recording not found"
        )
    
    if recording.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only delete pending recordings"
        )
    
    # Delete audio file
    import os
    from app.core.config import settings
    
    filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
    if os.path.exists(filepath):
        os.remove(filepath)
    
    # Delete database record
    db.delete(recording)
    db.commit()
    
    return {"message": "Recording deleted successfully"}
