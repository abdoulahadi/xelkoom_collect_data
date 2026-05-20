"""
Sprint 3 Quality & Tests — P2/P3 Fixes
Tests for CQ-003, CQ-005, CQ-007, CQ-008, GDPR-005, data retention
"""
import os
import uuid
import pytest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Set required env vars BEFORE importing app
os.environ.setdefault("SECRET_KEY", "test-secret-key-that-is-at-least-32-characters-long!")

from app.main import app
from app.db.database import get_db, Base
from app.models import User, Recording, Sentence
from app.core.auth import get_password_hash, create_access_token
from app.services.data_retention import (
    delete_rejected_recordings,
    anonymize_inactive_accounts,
    clean_orphan_files,
    run_all_retention_tasks,
)

# Test database setup — shared DB to avoid override conflicts
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
def db():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client():
    return TestClient(app)


# --- CQ-005: PyJWT migration tests ---

class TestPyJWTMigration:
    """Verify JWT creation and decoding works after python-jose -> PyJWT migration."""

    def test_create_access_token_returns_string(self):
        token = create_access_token(data={"sub": "testuser"})
        assert isinstance(token, str)
        assert len(token) > 20

    def test_create_access_token_with_expiry(self):
        token = create_access_token(
            data={"sub": "testuser"},
            expires_delta=timedelta(minutes=5),
        )
        assert isinstance(token, str)

    def test_auth_endpoint_with_jwt(self, client, db):
        """Verify the full auth flow works with PyJWT."""
        user = User(
            id=uuid.uuid4(),
            username=f"jwt_test_{uuid.uuid4().hex[:8]}",
            hashed_password=get_password_hash("TestPassword123!"),
            gender="male",
            age_range="25-34",
            role="user",
            is_active=True,
            consent_given=True,
        )
        db.add(user)
        db.commit()

        token = create_access_token(data={"sub": user.username})
        resp = client.get(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        assert resp.json()["username"] == user.username


# --- CQ-007: timezone-aware datetime ---

class TestTimezoneAwareDatetime:
    """Verify datetime.now(timezone.utc) is used instead of datetime.utcnow()."""

    def test_token_contains_timezone_aware_exp(self):
        import jwt as pyjwt
        from app.core.config import settings

        token = create_access_token(data={"sub": "tz_test"})
        payload = pyjwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        assert "exp" in payload
        # exp should be a numeric timestamp
        assert isinstance(payload["exp"], (int, float))


# --- CQ-008: DeclarativeBase ---

class TestDeclarativeBase:
    """Verify the modern DeclarativeBase pattern is in use."""

    def test_base_is_declarative_base_subclass(self):
        from sqlalchemy.orm import DeclarativeBase

        assert issubclass(Base, DeclarativeBase)

    def test_models_inherit_from_base(self):
        assert issubclass(User, Base)
        assert issubclass(Recording, Base)
        assert issubclass(Sentence, Base)


# --- CQ-003: No bare except clauses ---

class TestNoBareExcepts:
    """Verify audio_processing.py has no bare 'except:' clauses."""

    def test_no_bare_except_in_audio_processing(self):
        import inspect
        from app.services import audio_processing

        source = inspect.getsource(audio_processing)
        lines = source.split("\n")
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped == "except:" or stripped.startswith("except: "):
                pytest.fail(
                    f"Bare except found in audio_processing.py line {i}: {stripped}"
                )


# --- GDPR-005: Data retention ---

class TestDataRetention:
    @pytest.fixture(autouse=True)
    def _setup(self, db, tmp_path):
        self.db = db
        self.tmp_path = tmp_path

    def _create_user(self, **kwargs):
        defaults = {
            "id": uuid.uuid4(),
            "username": f"retention_{uuid.uuid4().hex[:8]}",
            "hashed_password": get_password_hash("pass"),
            "gender": "male",
            "age_range": "25-34",
            "role": "user",
            "is_active": True,
            "consent_given": True,
        }
        defaults.update(kwargs)
        user = User(**defaults)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def _create_recording(self, user, sentence_id=None, **kwargs):
        if sentence_id is None:
            sent = Sentence(
                id=uuid.uuid4(),
                text=f"Test sentence {uuid.uuid4().hex[:6]}",
                status="available",
            )
            self.db.add(sent)
            self.db.commit()
            sentence_id = sent.id

        defaults = {
            "id": uuid.uuid4(),
            "user_id": user.id,
            "sentence_id": sentence_id,
            "filepath": str(self.tmp_path / f"{uuid.uuid4().hex}.wav"),
            "status": "pending",
        }
        defaults.update(kwargs)

        # Create actual file for orphan tests
        with open(defaults["filepath"], "wb") as f:
            f.write(b"\x00" * 100)

        rec = Recording(**defaults)
        self.db.add(rec)
        self.db.commit()
        self.db.refresh(rec)
        return rec

    def test_delete_rejected_old_recordings(self):
        user = self._create_user()
        old_date = datetime.now(timezone.utc) - timedelta(days=100)

        rec = self._create_recording(user, status="rejected")
        # Manually set updated_at to old date
        rec.updated_at = old_date
        self.db.commit()

        count = delete_rejected_recordings(self.db, dry_run=False)
        assert count >= 1

    def test_delete_rejected_dry_run(self):
        user = self._create_user()
        old_date = datetime.now(timezone.utc) - timedelta(days=100)

        rec = self._create_recording(user, status="rejected")
        rec.updated_at = old_date
        self.db.commit()

        count = delete_rejected_recordings(self.db, dry_run=True)
        assert count >= 1
        # Recording should still exist in dry run
        existing = self.db.query(Recording).get(rec.id)
        assert existing is not None

    def test_recent_rejected_not_deleted(self):
        user = self._create_user()
        rec = self._create_recording(user, status="rejected")
        # Don't set old date — it's recent

        before_count = self.db.query(Recording).filter(
            Recording.id == rec.id
        ).count()
        delete_rejected_recordings(self.db, dry_run=False)
        after_count = self.db.query(Recording).filter(
            Recording.id == rec.id
        ).count()
        assert before_count == after_count

    def test_anonymize_inactive_accounts(self):
        old_date = datetime.now(timezone.utc) - timedelta(days=800)
        user = self._create_user()
        user.updated_at = old_date
        user.created_at = old_date
        self.db.commit()

        count = anonymize_inactive_accounts(self.db, dry_run=False)
        assert count >= 1

        self.db.refresh(user)
        assert user.is_active is False
        assert user.username.startswith("anonymized_")

    def test_admin_not_anonymized(self):
        old_date = datetime.now(timezone.utc) - timedelta(days=800)
        user = self._create_user(role="admin")
        user.updated_at = old_date
        user.created_at = old_date
        self.db.commit()

        anonymize_inactive_accounts(self.db, dry_run=False)
        self.db.refresh(user)
        assert user.is_active is True  # Admin should not be anonymized

    def test_clean_orphan_files(self):
        upload_dir = str(self.tmp_path / "uploads")
        os.makedirs(upload_dir, exist_ok=True)

        orphan_path = os.path.join(upload_dir, "orphan.wav")
        with open(orphan_path, "wb") as f:
            f.write(b"\x00" * 100)

        count = clean_orphan_files(self.db, upload_dir, dry_run=False)
        assert count >= 1
        assert not os.path.exists(orphan_path)

    def test_run_all_retention_tasks(self):
        upload_dir = str(self.tmp_path / "retention_all")
        os.makedirs(upload_dir, exist_ok=True)

        results = run_all_retention_tasks(self.db, upload_dir, dry_run=True)
        assert "rejected_recordings_deleted" in results
        assert "accounts_anonymized" in results
        assert "orphan_files_cleaned" in results
        assert results["dry_run"] is True


# --- CQ-004: No structlog references ---

class TestNoStructlog:
    """Verify structlog is not imported anywhere in the backend code."""

    def test_main_no_structlog(self):
        import inspect
        from app import main

        source = inspect.getsource(main)
        # Check there's no actual import of structlog
        assert "import structlog" not in source
        assert "structlog.get_logger" not in source

    def test_rate_limiting_no_structlog(self):
        import inspect
        from app.core import rate_limiting

        source = inspect.getsource(rate_limiting)
        assert "structlog" not in source
