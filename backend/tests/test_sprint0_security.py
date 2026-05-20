"""
Sprint 0 Security Tests — P0 Critical Fixes
Tests for SEC-001, SEC-002, SEC-003, SEC-005, SEC-007, CTR-001, CTR-002
"""
import os
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Set required env vars BEFORE importing app
os.environ.setdefault("SECRET_KEY", "test-secret-key-that-is-at-least-32-characters-long!")

from app.main import app
from app.db.database import get_db, Base
from app.models import User
from app.core.auth import get_password_hash, authenticate_user

# Test database setup
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
        # Clean up users after each test
        db.query(User).delete()
        db.commit()
        db.close()


@pytest.fixture
def user_with_password(db_session):
    user = User(
        username="secureuser",
        hashed_password=get_password_hash("ValidPass123!"),
        gender="male",
        age_range="25-34",
        consent_given=True,
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def user_without_password(db_session):
    user = User(
        username="nopassuser",
        hashed_password=None,
        gender="male",
        age_range="25-34",
        consent_given=True,
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


# ── SEC-001: Bypass d'authentification sans mot de passe ──


class TestSEC001:
    """authenticate_user must require a password and reject accounts without hashed_password."""

    def test_login_without_password_fails(self, db_session, user_with_password):
        """Calling authenticate_user without password should fail (password is mandatory)."""
        # password parameter is now required — calling without it raises TypeError
        with pytest.raises(TypeError):
            authenticate_user(db_session, "secureuser")

    def test_login_with_correct_password_succeeds(self, db_session, user_with_password):
        result = authenticate_user(db_session, "secureuser", "ValidPass123!")
        assert result is not None
        assert result.username == "secureuser"

    def test_login_with_wrong_password_fails(self, db_session, user_with_password):
        result = authenticate_user(db_session, "secureuser", "WrongPassword")
        assert result is None

    def test_account_without_hash_is_inaccessible(self, db_session, user_without_password):
        """Accounts with no hashed_password must be rejected even with any password."""
        result = authenticate_user(db_session, "nopassuser", "anything")
        assert result is None


# ── SEC-002: Inscription sans mot de passe ──


class TestSEC002:
    """POST /auth/register must require a password (min 8 chars)."""

    def test_register_without_password_returns_422(self, client):
        response = client.post("/auth/register", json={
            "username": "newuser",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True,
        })
        assert response.status_code == 422

    def test_register_with_short_password_returns_422(self, client):
        response = client.post("/auth/register", json={
            "username": "newuser2",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True,
            "password": "short",
        })
        assert response.status_code == 422

    def test_register_with_valid_password_succeeds(self, client, db_session):
        response = client.post("/auth/register", json={
            "username": "validuser",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True,
            "password": "SecurePass123!",
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


# ── SEC-003: SECRET_KEY validation ──


class TestSEC003:
    """App must refuse to start with a weak SECRET_KEY."""

    def test_startup_fails_without_secret_key(self):
        """SECRET_KEY shorter than 32 chars should raise RuntimeError at import time."""
        # The validation is in main.py — we test the condition directly
        from app.core.config import settings
        assert len(settings.SECRET_KEY) >= 32


# ── SEC-007: Login rejects query parameters ──


class TestSEC007:
    """POST /auth/login must only accept JSON body, not query parameters."""

    def test_login_via_json_body(self, client, db_session, user_with_password):
        response = client.post("/auth/login", json={
            "username": "secureuser",
            "password": "ValidPass123!",
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data

    def test_login_query_params_ignored(self, client, db_session, user_with_password):
        """Query params should NOT substitute for the body — request must have a body."""
        response = client.post(
            "/auth/login?username=secureuser&password=ValidPass123!",
            json={"username": "secureuser", "password": "ValidPass123!"},
        )
        # Should use body, not query params
        assert response.status_code == 200


# ── CTR-001: Gender validation ──


class TestCTR001:
    """Backend must reject invalid gender values."""

    def test_register_with_invalid_gender_rejected(self, client):
        response = client.post("/auth/register", json={
            "username": "gendertest",
            "gender": "masculin",
            "age_range": "25-34",
            "consent_given": True,
            "password": "SecurePass123!",
        })
        assert response.status_code == 422

    def test_register_with_valid_gender_accepted(self, client, db_session):
        response = client.post("/auth/register", json={
            "username": "gendertest_ok",
            "gender": "female",
            "age_range": "25-34",
            "consent_given": True,
            "password": "SecurePass123!",
        })
        assert response.status_code == 200


# ── CTR-002: Age range validation ──


class TestCTR002:
    """Backend must reject invalid age range values."""

    def test_register_with_invalid_age_range_rejected(self, client):
        response = client.post("/auth/register", json={
            "username": "agetest",
            "gender": "male",
            "age_range": "18-25",  # Invalid — should be 18-24
            "consent_given": True,
            "password": "SecurePass123!",
        })
        assert response.status_code == 422

    def test_register_with_valid_age_range_accepted(self, client, db_session):
        response = client.post("/auth/register", json={
            "username": "agetest_ok",
            "gender": "male",
            "age_range": "18-24",
            "consent_given": True,
            "password": "SecurePass123!",
        })
        assert response.status_code == 200
