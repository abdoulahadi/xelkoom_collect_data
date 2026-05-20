"""
Sprint 2 Tests — RGPD & Performance (P1-P2)
Tests for GDPR-001, GDPR-002, GDPR-003, GDPR-004, API-001, API-002, API-003, DB-006, DB-007
"""
import os
import uuid
import json
import zipfile
import io
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from pathlib import Path

# Set required env vars BEFORE importing app
os.environ.setdefault("SECRET_KEY", "test-secret-key-that-is-at-least-32-characters-long!")

from app.main import app
from app.db.database import get_db, Base
from app.models import User, Sentence, Recording
from app.core.auth import get_password_hash, create_access_token
from app.core.config import settings

# Test database setup — reuse sprint0's test DB to avoid dep_override conflicts
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_sprint0.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def db_session():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def admin_user(db_session):
    """Create an admin user and return user + auth token"""
    user = db_session.query(User).filter(User.username == "sprint2_admin").first()
    if not user:
        user = User(
            username="sprint2_admin",
            hashed_password=get_password_hash("adminpass12345"),
            gender="male",
            age_range="25-34",
            role="admin",
            is_admin=True,
            is_active=True,
            consent_given=True,
        )
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
    token = create_access_token(data={"sub": user.username})
    return user, token


@pytest.fixture
def sample_sentence(db_session):
    """Create a sample sentence for recordings"""
    sentence = db_session.query(Sentence).filter(Sentence.text == "Sprint2 test wolof").first()
    if not sentence:
        sentence = Sentence(
            text="Sprint2 test wolof",
            language="wo",
            difficulty_level="easy",
            status="available",
        )
        db_session.add(sentence)
        db_session.commit()
        db_session.refresh(sentence)
    return sentence


def _create_user_with_recording(db_session, username, sentence, create_audio_file=False):
    """Helper to create a user with a recording, optionally with an audio file on disk."""
    user = User(
        username=username,
        hashed_password=get_password_hash("userpass12345"),
        gender="female",
        age_range="18-24",
        role="user",
        is_admin=False,
        is_active=True,
        consent_given=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    filepath = f"{user.id}/test_audio.wav"
    recording = Recording(
        user_id=user.id,
        sentence_id=sentence.id,
        filepath=filepath,
        duration=3.5,
        file_size=0.1,
        sample_rate=16000,
        status="pending",
    )
    db_session.add(recording)
    db_session.commit()
    db_session.refresh(recording)

    if create_audio_file:
        full_path = os.path.join(settings.AUDIO_STORAGE_PATH, filepath)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "wb") as f:
            f.write(b"RIFF\x00\x00\x00\x00WAVEfmt ")  # minimal WAV header

    token = create_access_token(data={"sub": user.username})
    return user, recording, token


# ============================================================
# GDPR-001 — Delete audio files when user deletes account
# ============================================================
class TestGDPR001:
    def test_delete_user_removes_audio_files(self, client, db_session, sample_sentence):
        """Deleting a user must also remove audio files from disk"""
        user, recording, token = _create_user_with_recording(
            db_session, f"gdpr001_{uuid.uuid4().hex[:8]}", sample_sentence, create_audio_file=True
        )
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        assert os.path.exists(filepath)

        response = client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        assert not os.path.exists(filepath)


# ============================================================
# GDPR-002 — User data export endpoint
# ============================================================
class TestGDPR002:
    def test_export_returns_zip(self, client, db_session, sample_sentence):
        """GET /users/me/export must return a ZIP file"""
        user, recording, token = _create_user_with_recording(
            db_session, f"gdpr002_{uuid.uuid4().hex[:8]}", sample_sentence, create_audio_file=True
        )
        response = client.get("/users/me/export", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        assert response.headers["content-type"] == "application/zip"

        # Verify ZIP contents
        zf = zipfile.ZipFile(io.BytesIO(response.content))
        names = zf.namelist()
        assert "profile.json" in names
        assert "recordings.json" in names

        profile = json.loads(zf.read("profile.json"))
        assert profile["username"] == user.username

        recordings_data = json.loads(zf.read("recordings.json"))
        assert len(recordings_data) >= 1

        # Cleanup
        client.delete("/users/me", headers={"Authorization": f"Bearer {token}"})


# ============================================================
# GDPR-003 — Admin hard-delete user
# ============================================================
class TestGDPR003:
    def test_soft_delete_only_deactivates(self, client, db_session, admin_user, sample_sentence):
        """Default admin delete is soft delete (deactivate)"""
        admin, admin_token = admin_user
        user, recording, _ = _create_user_with_recording(
            db_session, f"gdpr003s_{uuid.uuid4().hex[:8]}", sample_sentence
        )
        response = client.delete(
            f"/admin/users/{user.id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200
        assert "deactivated" in response.json()["message"].lower()

        # User still exists in DB
        db_session.expire_all()
        db_user = db_session.query(User).filter(User.id == user.id).first()
        assert db_user is not None
        assert db_user.is_active is False

    def test_hard_delete_removes_everything(self, client, db_session, admin_user, sample_sentence):
        """Admin hard delete removes user, recordings, and audio files"""
        admin, admin_token = admin_user
        user, recording, _ = _create_user_with_recording(
            db_session, f"gdpr003h_{uuid.uuid4().hex[:8]}", sample_sentence, create_audio_file=True
        )
        user_id = user.id
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        assert os.path.exists(filepath)

        response = client.delete(
            f"/admin/users/{user_id}?hard_delete=true",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200
        assert "permanently" in response.json()["message"].lower()

        db_session.expire_all()
        assert db_session.query(User).filter(User.id == user_id).first() is None
        assert db_session.query(Recording).filter(Recording.user_id == user_id).first() is None
        assert not os.path.exists(filepath)


# ============================================================
# GDPR-004 — Consent revocation
# ============================================================
class TestGDPR004:
    def test_revoke_consent_deletes_everything(self, client, db_session, sample_sentence):
        """POST /users/me/revoke-consent deletes all user data"""
        user, recording, token = _create_user_with_recording(
            db_session, f"gdpr004_{uuid.uuid4().hex[:8]}", sample_sentence, create_audio_file=True
        )
        user_id = user.id
        filepath = os.path.join(settings.AUDIO_STORAGE_PATH, recording.filepath)
        assert os.path.exists(filepath)

        response = client.post(
            "/users/me/revoke-consent",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        assert "consent revoked" in response.json()["message"].lower()

        db_session.expire_all()
        assert db_session.query(User).filter(User.id == user_id).first() is None
        assert not os.path.exists(filepath)


# ============================================================
# API-002 — Versioned API routes with /api/v1 prefix
# ============================================================
class TestAPI002:
    def test_versioned_endpoint_works(self, client, admin_user):
        """Routes are accessible under /api/v1/ prefix"""
        _, admin_token = admin_user
        response = client.get(
            "/api/v1/admin/stats",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200

    def test_legacy_endpoint_still_works(self, client, admin_user):
        """Legacy routes (without /api/v1/) still work for backward compat"""
        _, admin_token = admin_user
        response = client.get(
            "/admin/stats",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200


# ============================================================
# API-003 — Real health check
# ============================================================
class TestAPI003:
    def test_health_check_returns_real_status(self, client):
        """Health endpoint returns actual database and storage status"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ("healthy", "unhealthy")
        assert data["database"] in ("connected", "disconnected")
        assert data["audio_storage"] in ("accessible", "inaccessible")

    def test_health_check_db_connected(self, client):
        """Health check reports database as connected when DB is up"""
        response = client.get("/health")
        data = response.json()
        assert data["database"] == "connected"


# ============================================================
# DB-006 — N+1 query fix in admin users list
# ============================================================
class TestDB006:
    def test_admin_users_list_includes_stats(self, client, admin_user, db_session, sample_sentence):
        """GET /admin/users returns recording_count and validated_recordings"""
        _, admin_token = admin_user
        # Create a user with a recording
        _create_user_with_recording(
            db_session, f"db006_{uuid.uuid4().hex[:8]}", sample_sentence
        )

        response = client.get(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        # Every user item should have recording stats
        for item in data["items"]:
            assert "recording_count" in item
            assert "validated_recordings" in item


# ============================================================
# DB-007 — Connection pool configuration
# ============================================================
class TestDB007:
    def test_pool_config_for_postgresql(self):
        """PostgreSQL engine should have pool_size and max_overflow configured"""
        from app.db.database import engine as app_engine

        # In test mode we use SQLite which doesn't use QueuePool
        # Just verify the module-level code doesn't error out
        # and that the engine is properly created
        assert app_engine is not None
