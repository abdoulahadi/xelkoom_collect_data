"""
Sprint 1 Tests — Cohérence & Stabilité (P1)
Tests for CTR-005, CTR-006, SEC-008, SEC-012, ADM-005, DB-002
"""
import os
import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from pathlib import Path
from unittest.mock import patch

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
    user = db_session.query(User).filter(User.username == "sprint1_admin").first()
    if not user:
        user = User(
            username="sprint1_admin",
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
def regular_user(db_session):
    """Create a regular user"""
    user = db_session.query(User).filter(User.username == "sprint1_regular").first()
    if not user:
        user = User(
            username="sprint1_regular",
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
    return user


@pytest.fixture
def sample_sentence(db_session):
    """Create a sample sentence"""
    sentence = db_session.query(Sentence).filter(Sentence.text == "Test sprint1 phrase").first()
    if not sentence:
        sentence = Sentence(
            text="Test sprint1 phrase",
            language="wo",
            difficulty_level="easy",
            status="available",
        )
        db_session.add(sentence)
        db_session.commit()
        db_session.refresh(sentence)
    return sentence


# ============================================================
# CTR-005 — Token includes expires_in field
# ============================================================
class TestCTR005:
    def test_login_token_contains_expires_in(self, client, admin_user):
        """Token response from login must include expires_in field"""
        response = client.post("/auth/login", json={
            "username": "sprint1_admin",
            "password": "adminpass12345",
        })
        assert response.status_code == 200
        data = response.json()
        assert "expires_in" in data
        assert isinstance(data["expires_in"], int)
        assert data["expires_in"] > 0

    def test_register_token_contains_expires_in(self, client):
        """Token response from registration must include expires_in field"""
        response = client.post("/auth/register", json={
            "username": f"test_ctr005_{uuid.uuid4().hex[:8]}",
            "password": "securepass123",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True,
        })
        assert response.status_code == 200
        data = response.json()
        assert "expires_in" in data
        assert isinstance(data["expires_in"], int)


# ============================================================
# CTR-006 — UserWithStats includes role field
# ============================================================
class TestCTR006:
    def test_user_list_contains_role(self, client, admin_user):
        """Admin user list endpoint must return role field for each user"""
        _, token = admin_user
        response = client.get(
            "/admin/users?page=1&size=10",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        if data["items"]:
            user_item = data["items"][0]
            assert "role" in user_item


# ============================================================
# SEC-008 — Audio endpoint uses Authorization header, not query token
# ============================================================
class TestSEC008:
    def test_audio_endpoint_requires_auth_header(self, client, admin_user, db_session, sample_sentence):
        """Audio endpoint must reject requests without Authorization header"""
        _, token = admin_user
        # Create a recording to have a valid ID
        recording = db_session.query(Recording).first()
        if not recording:
            recording = Recording(
                user_id=admin_user[0].id,
                sentence_id=sample_sentence.id,
                filepath="nonexistent.wav",
                status="pending",
            )
            db_session.add(recording)
            db_session.commit()
            db_session.refresh(recording)

        # Request without any auth should fail
        response = client.get(f"/admin/recordings/{recording.id}/audio")
        assert response.status_code in (401, 403)

    def test_audio_endpoint_accepts_auth_header(self, client, admin_user, db_session, sample_sentence):
        """Audio endpoint must accept Authorization header"""
        user, token = admin_user
        recording = db_session.query(Recording).first()
        if not recording:
            recording = Recording(
                user_id=user.id,
                sentence_id=sample_sentence.id,
                filepath="nonexistent.wav",
                status="pending",
            )
            db_session.add(recording)
            db_session.commit()
            db_session.refresh(recording)

        # Request with auth header — may 404 (file doesn't exist) but should NOT 401/403
        response = client.get(
            f"/admin/recordings/{recording.id}/audio",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Should be 404 (file not found) not 401/403  
        assert response.status_code != 401
        assert response.status_code != 403


# ============================================================
# SEC-012 — Path traversal protection on audio endpoint
# ============================================================
class TestSEC012:
    def test_path_traversal_blocked(self, client, admin_user, db_session):
        """Audio endpoint must block path traversal in recording filepath"""
        user, token = admin_user
        # Create a dedicated sentence for this test to avoid unique constraint
        traversal_sentence = Sentence(
            text="Path traversal test sentence",
            language="wo",
            difficulty_level="easy",
            status="available",
        )
        db_session.add(traversal_sentence)
        db_session.commit()
        db_session.refresh(traversal_sentence)

        # Create a recording with a path traversal filepath
        recording = Recording(
            user_id=user.id,
            sentence_id=traversal_sentence.id,
            filepath="../../../etc/passwd",
            status="pending",
        )
        db_session.add(recording)
        db_session.commit()
        db_session.refresh(recording)

        response = client.get(
            f"/admin/recordings/{recording.id}/audio",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Should be 403 (access denied) — not serving the file
        assert response.status_code == 403

        # Cleanup
        db_session.delete(recording)
        db_session.delete(traversal_sentence)
        db_session.commit()


# ============================================================
# ADM-005 — Server-side search on users endpoint
# ============================================================
class TestADM005:
    def test_users_search_by_username(self, client, admin_user, regular_user):
        """Admin can search users by username via query parameter"""
        _, token = admin_user
        response = client.get(
            "/admin/users?page=1&size=10&search=sprint1_regular",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert any(u["username"] == "sprint1_regular" for u in data["items"])

    def test_users_search_no_match(self, client, admin_user):
        """Search with no match returns empty list"""
        _, token = admin_user
        response = client.get(
            "/admin/users?page=1&size=10&search=nonexistent_user_xyz",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert len(data["items"]) == 0

    def test_sentences_search_by_text(self, client, admin_user, sample_sentence):
        """Admin can search sentences by text via query parameter"""
        _, token = admin_user
        response = client.get(
            "/admin/sentences?search=sprint1",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1


# ============================================================
# DB-002 — UUID type consistency (sqlalchemy.Uuid)
# ============================================================
class TestDB002:
    def test_user_id_is_uuid(self, admin_user):
        """User IDs should be UUID type"""
        user, _ = admin_user
        # The id should be a uuid.UUID instance (from sqlalchemy.Uuid)
        assert isinstance(user.id, uuid.UUID)

    def test_sentence_id_is_uuid(self, sample_sentence):
        """Sentence IDs should be UUID type"""
        assert isinstance(sample_sentence.id, uuid.UUID)
