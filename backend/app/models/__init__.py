from sqlalchemy import Column, String, Boolean, DateTime, Enum, ForeignKey, Float, Text, Integer, JSON, UniqueConstraint, Uuid, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
from app.core.config import settings
import uuid
import enum

# DB-002: Utiliser sqlalchemy.Uuid qui fonctionne sur SQLite et PostgreSQL
def get_id_column():
    return Column(Uuid, primary_key=True, default=uuid.uuid4)

def get_foreign_key_column(table_name, index=False):
    return Column(Uuid, ForeignKey(f"{table_name}.id"), index=index)

class GenderEnum(enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"

class AgeRangeEnum(enum.Enum):
    RANGE_18_24 = "18-24"
    RANGE_25_34 = "25-34"
    RANGE_35_44 = "35-44"
    RANGE_45_54 = "45-54"
    RANGE_55_PLUS = "55+"

class SentenceStatusEnum(enum.Enum):
    AVAILABLE = "available"
    ASSIGNED = "assigned"
    COMPLETED = "completed"

class RecordingStatusEnum(enum.Enum):
    PENDING = "pending"
    VALIDATED = "validated"
    REJECTED = "rejected"

class UserRoleEnum(enum.Enum):
    ADMIN = "admin"
    MODERATOR = "moderator"
    USER = "user"

class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint("gender IN ('male', 'female', 'other')", name='ck_user_gender'),
        CheckConstraint("age_range IN ('18-24', '25-34', '35-44', '45-54', '55+')", name='ck_user_age_range'),
        CheckConstraint("role IN ('admin', 'moderator', 'user')", name='ck_user_role'),
    )
    
    id = get_id_column()
    username = Column(String(50), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=True)  # Ajouté pour l'authentification
    gender = Column(String(20), nullable=False)  # Utiliser String au lieu d'Enum pour SQLite
    age_range = Column(String(20), nullable=False)  # Utiliser String au lieu d'Enum pour SQLite
    is_admin = Column(Boolean, default=False)
    role = Column(String(20), default="user")  # admin, moderator or user
    is_active = Column(Boolean, default=True)
    consent_given = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    recordings = relationship("Recording", back_populates="user")

class Sentence(Base):
    __tablename__ = "sentences"
    __table_args__ = (
        CheckConstraint("status IN ('available', 'assigned', 'completed')", name='ck_sentence_status'),
    )
    
    id = get_id_column()
    text = Column(Text, nullable=False)
    status = Column(String(20), default="available", index=True)  # DB-004: index
    language = Column(String(10), default="wo")  # Wolof language code
    difficulty_level = Column(String(20), default="easy")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    recordings = relationship("Recording", back_populates="sentence")

class Recording(Base):
    __tablename__ = "recordings"
    __table_args__ = (
        UniqueConstraint('user_id', 'sentence_id', name='uq_recording_user_sentence'),
        CheckConstraint("status IN ('pending', 'validated', 'rejected')", name='ck_recording_status'),
    )
    
    id = get_id_column()
    user_id = get_foreign_key_column("users", index=True)
    sentence_id = get_foreign_key_column("sentences", index=True)
    filepath = Column(String(255), nullable=False)
    original_filename = Column(String(255))
    duration = Column(Float)  # Duration in seconds
    file_size = Column(Float)  # File size in MB
    sample_rate = Column(Float)  # Audio sample rate
    status = Column(String(20), default="pending", index=True)  # DB-004: index
    quality_score = Column(Float)  # Audio quality score (0-1)
    admin_notes = Column(Text)  # Admin comments for moderation
    audio_metadata = Column(JSON)  # Audio metadata including Whisper validation
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="recordings")
    sentence = relationship("Sentence", back_populates="recordings")
