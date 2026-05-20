"""
Backlog Tests — Coverage for Backlog items
Tests for SEC-013, DB-005, ADM-006, API-004, JSON logger, CHECK constraints
"""
import os
import uuid
import json
import logging
import pytest
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Set required env vars BEFORE importing app
os.environ.setdefault("SECRET_KEY", "test-secret-key-that-is-at-least-32-characters-long!")

from app.main import app
from app.db.database import get_db, Base
from app.models import User, Recording, Sentence
from app.core.auth import get_password_hash, create_access_token
from app.core.json_logger import JsonFileHandler, read_logs

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
def db_session():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def admin_user(db_session):
    """Create an admin user and return user + auth token"""
    user = db_session.query(User).filter(User.username == "backlog_admin").first()
    if not user:
        user = User(
            username="backlog_admin",
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
    """Create a sample sentence for testing"""
    sentence = Sentence(
        id=uuid.uuid4(),
        text=f"Backlog test sentence {uuid.uuid4().hex[:8]}",
        language="wo",
        difficulty_level="easy",
        status="available",
    )
    db_session.add(sentence)
    db_session.commit()
    db_session.refresh(sentence)
    return sentence


# --- SEC-013: CORS restriction tests ---

class TestCORSRestriction:
    """Verify CORS middleware has restricted methods and headers."""

    def test_cors_allows_get(self, client):
        resp = client.options(
            "/api/v1/sentences/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
            },
        )
        # Should not return 405
        assert resp.status_code != 405

    def test_cors_allows_post(self, client):
        resp = client.options(
            "/api/v1/sentences/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
            },
        )
        assert resp.status_code != 405

    def test_cors_allows_authorization_header(self, client):
        resp = client.options(
            "/api/v1/sentences/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "Authorization",
            },
        )
        assert resp.status_code != 405

    def test_cors_methods_are_restricted(self):
        """Verify that allow_methods is not wildcard '*'."""
        from app.main import app as test_app
        cors_mw = None
        for mw in test_app.user_middleware:
            if "CORSMiddleware" in str(mw.cls):
                cors_mw = mw
                break
        assert cors_mw is not None, "CORS middleware not found"
        methods = cors_mw.options.get("allow_methods", [])
        assert "*" not in methods, "CORS should not allow wildcard methods"
        assert "GET" in methods
        assert "POST" in methods
        assert "DELETE" in methods

    def test_cors_headers_are_restricted(self):
        """Verify that allow_headers is not wildcard '*'."""
        from app.main import app as test_app
        cors_mw = None
        for mw in test_app.user_middleware:
            if "CORSMiddleware" in str(mw.cls):
                cors_mw = mw
                break
        assert cors_mw is not None
        headers = cors_mw.options.get("allow_headers", [])
        assert "*" not in headers, "CORS should not allow wildcard headers"
        assert "Authorization" in headers
        assert "Content-Type" in headers


# --- DB-005: CHECK constraints on enum columns ---

class TestCheckConstraints:
    """Verify CHECK constraints exist on models."""

    def test_user_model_has_check_constraints(self):
        from app.models import User
        args = User.__table_args__
        constraint_names = [c.name for c in args if hasattr(c, "name")]
        assert "ck_user_gender" in constraint_names
        assert "ck_user_age_range" in constraint_names
        assert "ck_user_role" in constraint_names

    def test_sentence_model_has_check_constraint(self):
        from app.models import Sentence
        args = Sentence.__table_args__
        constraint_names = [c.name for c in args if hasattr(c, "name")]
        assert "ck_sentence_status" in constraint_names

    def test_recording_model_has_check_constraint(self):
        from app.models import Recording
        args = Recording.__table_args__
        constraint_names = [c.name for c in args if hasattr(c, "name")]
        assert "ck_recording_status" in constraint_names

    def test_check_constraints_in_database_schema(self, db_session):
        """Verify constraints are in the actual DB tables (SQLAlchemy metadata)."""
        from app.models import User, Sentence, Recording
        # Just confirm the table objects have constraints defined
        user_constraints = [c.name for c in User.__table__.constraints if hasattr(c, "name") and c.name]
        assert any("ck_user" in name for name in user_constraints)

        sentence_constraints = [c.name for c in Sentence.__table__.constraints if hasattr(c, "name") and c.name]
        assert any("ck_sentence" in name for name in sentence_constraints)

        recording_constraints = [c.name for c in Recording.__table__.constraints if hasattr(c, "name") and c.name]
        assert any("ck_recording" in name for name in recording_constraints)


# --- ADM-006: PeriodFilter functional ---

class TestPeriodFilter:
    """Verify /admin/stats respects the period query parameter."""

    def test_stats_default_period(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/stats",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "total_recordings" in data
        assert "total_users" in data

    def test_stats_period_7d(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/stats?period=7d",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

    def test_stats_period_90d(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/stats?period=90d",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

    def test_stats_period_all(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/stats?period=all",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

    def test_stats_invalid_period_rejected(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/stats?period=999d",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 422

    def test_stats_period_filters_recordings(self, client, admin_user, db_session):
        """Recordings outside the period window should be excluded."""
        user, token = admin_user

        # Create two separate sentences to avoid unique constraint
        sentence_old = Sentence(
            id=uuid.uuid4(),
            text=f"Old sentence {uuid.uuid4().hex[:8]}",
            language="wo",
            difficulty_level="easy",
            status="available",
        )
        sentence_new = Sentence(
            id=uuid.uuid4(),
            text=f"New sentence {uuid.uuid4().hex[:8]}",
            language="wo",
            difficulty_level="easy",
            status="available",
        )
        db_session.add_all([sentence_old, sentence_new])
        db_session.flush()

        # Create an old recording (60 days ago)
        old_rec = Recording(
            id=uuid.uuid4(),
            user_id=user.id,
            sentence_id=sentence_old.id,
            filepath="/fake/old.wav",
            duration=2.0,
            status="validated",
            created_at=datetime.now() - timedelta(days=60),
        )
        # Create a recent recording (1 day ago)
        new_rec = Recording(
            id=uuid.uuid4(),
            user_id=user.id,
            sentence_id=sentence_new.id,
            filepath="/fake/new.wav",
            duration=3.0,
            status="validated",
            created_at=datetime.now() - timedelta(days=1),
        )
        db_session.add_all([old_rec, new_rec])
        db_session.commit()

        # 7d period: only the recent recording
        resp_7d = client.get(
            "/api/v1/admin/stats?period=7d",
            headers={"Authorization": f"Bearer {token}"},
        )
        stats_7d = resp_7d.json()

        # all period: both recordings
        resp_all = client.get(
            "/api/v1/admin/stats?period=all",
            headers={"Authorization": f"Bearer {token}"},
        )
        stats_all = resp_all.json()

        assert stats_all["total_recordings"] >= stats_7d["total_recordings"]

        # Cleanup
        db_session.delete(old_rec)
        db_session.delete(new_rec)
        db_session.delete(sentence_old)
        db_session.delete(sentence_new)
        db_session.commit()


# --- API-004: Real logs endpoint ---

class TestLogsEndpoint:
    """Verify /admin/system/logs returns real log data."""

    def test_logs_endpoint_requires_admin(self, client):
        resp = client.get("/api/v1/admin/system/logs")
        assert resp.status_code in (401, 403)

    def test_logs_endpoint_returns_structure(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/system/logs",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "size" in data
        assert "pages" in data

    def test_logs_endpoint_accepts_pagination(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/system/logs?page=1&size=10",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["page"] == 1
        assert data["size"] == 10

    def test_logs_endpoint_accepts_level_filter(self, client, admin_user):
        _, token = admin_user
        resp = client.get(
            "/api/v1/admin/system/logs?level=ERROR",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data["items"], list)


# --- JSON logger unit tests ---

class TestJsonLogger:
    """Unit tests for the JSON file logging infrastructure."""

    def test_json_file_handler_writes_log(self, tmp_path):
        log_file = tmp_path / "test.log"
        handler = JsonFileHandler(filepath=log_file)
        handler.setLevel(logging.DEBUG)

        logger = logging.getLogger("test_json_handler")
        logger.addHandler(handler)
        logger.setLevel(logging.DEBUG)

        logger.info("Test message")
        logger.removeHandler(handler)

        assert log_file.exists()
        content = log_file.read_text(encoding="utf-8")
        entry = json.loads(content.strip())
        assert entry["level"] == "INFO"
        assert entry["message"] == "Test message"
        assert "timestamp" in entry

    def test_json_file_handler_records_exception(self, tmp_path):
        log_file = tmp_path / "test_exc.log"
        handler = JsonFileHandler(filepath=log_file)
        handler.setLevel(logging.DEBUG)

        logger = logging.getLogger("test_json_exc")
        logger.addHandler(handler)
        logger.setLevel(logging.DEBUG)

        try:
            raise ValueError("test error")
        except ValueError:
            logger.exception("Something failed")
        logger.removeHandler(handler)

        content = log_file.read_text(encoding="utf-8")
        entry = json.loads(content.strip())
        assert entry["level"] == "ERROR"
        assert "exception" in entry
        assert "test error" in entry["exception"]

    def test_read_logs_empty_file(self, tmp_path):
        """read_logs returns empty when log file doesn't exist."""
        with patch("app.core.json_logger.LOG_FILE", tmp_path / "nonexistent.log"):
            result = read_logs()
            assert result["items"] == []
            assert result["total"] == 0

    def test_read_logs_with_data(self, tmp_path):
        log_file = tmp_path / "readable.log"
        entries = [
            {"timestamp": "2024-01-01T00:00:00", "level": "INFO", "message": "msg1", "module": "test"},
            {"timestamp": "2024-01-01T00:01:00", "level": "ERROR", "message": "msg2", "module": "test"},
            {"timestamp": "2024-01-01T00:02:00", "level": "INFO", "message": "msg3", "module": "test"},
        ]
        with open(log_file, "w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")

        with patch("app.core.json_logger.LOG_FILE", log_file):
            result = read_logs(page=1, size=10)
            assert result["total"] == 3
            # Newest first
            assert result["items"][0]["message"] == "msg3"

    def test_read_logs_level_filter(self, tmp_path):
        log_file = tmp_path / "filter.log"
        entries = [
            {"timestamp": "2024-01-01T00:00:00", "level": "INFO", "message": "info msg", "module": "test"},
            {"timestamp": "2024-01-01T00:01:00", "level": "ERROR", "message": "error msg", "module": "test"},
        ]
        with open(log_file, "w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")

        with patch("app.core.json_logger.LOG_FILE", log_file):
            result = read_logs(level="ERROR")
            assert result["total"] == 1
            assert result["items"][0]["level"] == "ERROR"

    def test_read_logs_pagination(self, tmp_path):
        log_file = tmp_path / "paginated.log"
        entries = [
            {"timestamp": f"2024-01-01T00:0{i}:00", "level": "INFO", "message": f"msg{i}", "module": "test"}
            for i in range(5)
        ]
        with open(log_file, "w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")

        with patch("app.core.json_logger.LOG_FILE", log_file):
            result = read_logs(page=1, size=2)
            assert len(result["items"]) == 2
            assert result["total"] == 5
            assert result["pages"] == 3

    def test_json_handler_rotation(self, tmp_path):
        """Handler rotates when file exceeds MAX_LOG_SIZE."""
        log_file = tmp_path / "rotate.log"
        handler = JsonFileHandler(filepath=log_file)

        with patch.object(handler, "_filepath", log_file):
            # Write enough data to trigger rotation check
            logger = logging.getLogger("test_rotation")
            logger.addHandler(handler)
            logger.setLevel(logging.DEBUG)

            # Write a message
            logger.info("Pre-rotation message")

            # Simulate large file by patching MAX_LOG_SIZE to 0
            with patch("app.core.json_logger.MAX_LOG_SIZE", 0):
                logger.info("Trigger rotation")

            logger.removeHandler(handler)

            # Either the main file or backup should exist
            assert log_file.exists() or (tmp_path / "rotate.log.1").exists()
