from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional, List, Union
from datetime import datetime
from app.models import SentenceStatusEnum, RecordingStatusEnum

# Base schemas
class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    gender: str = Field(..., description="Gender: male, female, or other")
    age_range: str = Field(..., description="Age range: 18-24, 25-34, 35-44, 45-54, 55+")
    consent_given: bool = Field(..., description="GDPR consent required")

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128, description="User password, required")

    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v: str) -> str:
        if v not in ('male', 'female', 'other'):
            raise ValueError('gender must be male, female, or other')
        return v

    @field_validator('age_range')
    @classmethod
    def validate_age_range(cls, v: str) -> str:
        if v not in ('18-24', '25-34', '35-44', '45-54', '55+'):
            raise ValueError('age_range must be one of: 18-24, 25-34, 35-44, 45-54, 55+')
        return v

class AdminUserCreate(UserBase):
    """Schema for creating users via admin interface"""
    role: Optional[str] = Field(default="user", description="User role: admin, moderator, or user")
    is_admin: Optional[bool] = Field(default=False, description="Whether user is admin")
    is_active: Optional[bool] = Field(default=True, description="Whether user account is active")

class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    is_active: Optional[bool] = None

class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    is_admin: bool
    role: str
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

class UserStats(BaseModel):
    total_recordings: int
    validated_recordings: int
    rejected_recordings: int
    pending_recordings: int
    total_duration: float

# Sentence schemas
class SentenceBase(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000)
    language: str = Field(default="wo", description="Language code")
    difficulty_level: str = Field(default="easy")

class SentenceCreate(SentenceBase):
    pass

class SentenceUpdate(BaseModel):
    text: Optional[str] = Field(None, min_length=1, max_length=1000)
    status: Optional[SentenceStatusEnum] = None
    difficulty_level: Optional[str] = None

class SentenceResponse(SentenceBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    status: SentenceStatusEnum
    created_at: datetime
    updated_at: Optional[datetime] = None
    recording_count: Optional[int] = Field(default=0, description="Number of recordings for this sentence")

class SentenceWithStats(SentenceResponse):
    """Sentence with detailed recording statistics"""
    validated_recordings: Optional[int] = Field(default=0, description="Number of validated recordings")
    pending_recordings: Optional[int] = Field(default=0, description="Number of pending recordings")
    rejected_recordings: Optional[int] = Field(default=0, description="Number of rejected recordings")

class SentencesPaginatedResponse(BaseModel):
    items: List[SentenceWithStats]
    total: int
    page: int
    size: int
    pages: int

# Recording schemas
class RecordingBase(BaseModel):
    sentence_id: str

class RecordingCreate(RecordingBase):
    pass

class RecordingUpdate(BaseModel):
    status: Optional[RecordingStatusEnum] = None
    quality_score: Optional[float] = Field(None, ge=0, le=1)
    admin_notes: Optional[str] = None
    audio_metadata: Optional[dict] = None

class RecordingResponse(RecordingBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    filepath: str
    original_filename: Optional[str] = None
    duration: Optional[float] = None
    file_size: Optional[float] = None
    sample_rate: Optional[float] = None
    status: RecordingStatusEnum
    quality_score: Optional[float] = None
    admin_notes: Optional[str] = None
    audio_metadata: Optional[dict] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

class RecordingWithDetails(RecordingResponse):
    user: UserResponse
    sentence: SentenceResponse

# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(default=1800, description="Token expiry in seconds")
    user: UserResponse

class TokenData(BaseModel):
    username: Optional[str] = None

# Auth schemas
class LoginRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=1)

# Admin schemas
class AdminStats(BaseModel):
    total_users: int
    active_users: int
    total_sentences: int
    available_sentences: int
    total_recordings: int
    pending_recordings: int
    validated_recordings: int
    rejected_recordings: int
    total_audio_duration: float
    daily_recordings: List[dict]

class BulkSentenceCreate(BaseModel):
    sentences: List[str] = Field(..., min_items=1, max_items=100)

class BulkModerationRequest(BaseModel):
    recording_ids: List[str] = Field(..., min_items=1, max_items=100)
    status: RecordingStatusEnum
    notes: Optional[str] = Field(None, max_length=500)

# Pagination schema
class PaginatedResponse(BaseModel):
    items: List[dict]
    total: int
    page: int
    size: int
    pages: int

# User with stats schema
class UserWithStats(BaseModel):
    id: str
    username: str
    gender: str
    age_range: str
    role: str
    is_admin: bool
    is_active: bool
    consent_given: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    recording_count: int
    validated_recordings: int

class UsersPaginatedResponse(BaseModel):
    items: List[UserWithStats]
    total: int
    page: int
    size: int
    pages: int
    active_users: int = 0
    admin_users: int = 0
    inactive_users: int = 0

# Leaderboard schemas
class LeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    username: str
    validated_recordings: int
    total_duration: float
    is_current_user: bool = False

class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry]
    current_user_rank: Optional[int] = None
    total_users: int
