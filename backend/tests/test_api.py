"""
Comprehensive test suite for the backend API
Tests authentication, audio processing, and API endpoints
"""
import pytest
import tempfile
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.config import settings
from app.db.database import get_db, Base
from app.models import User, Sentence, Recording
from app.core.auth import get_password_hash
import io
import wave

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
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
def test_user(db_session):
    user = User(
        username="testuser",
        gender="male",
        age_range="25-34",
        consent_given=True,
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

@pytest.fixture
def admin_user(db_session):
    user = User(
        username="admin",
        gender="male",
        age_range="25-34",
        consent_given=True,
        is_active=True,
        is_admin=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

@pytest.fixture
def test_sentence(db_session):
    sentence = Sentence(
        text="Jàngalekat dafay wax ci wolof.",
        language="wo",
        status="available"
    )
    db_session.add(sentence)
    db_session.commit()
    db_session.refresh(sentence)
    return sentence

@pytest.fixture
def auth_headers(client, test_user):
    """Get authentication headers for test user"""
    response = client.post("/auth/login", json={"username": test_user.username})
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def admin_headers(client, admin_user):
    """Get authentication headers for admin user"""
    response = client.post("/auth/login", json={"username": admin_user.username})
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def create_test_audio_file():
    """Create a test WAV audio file"""
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        # Create a simple sine wave
        import numpy as np
        sample_rate = 16000
        duration = 2.0  # seconds
        frequency = 440  # Hz
        
        t = np.linspace(0, duration, int(sample_rate * duration), False)
        audio_data = np.sin(2 * np.pi * frequency * t)
        audio_data = (audio_data * 32767).astype(np.int16)
        
        # Write WAV file
        with wave.open(f.name, 'wb') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(audio_data.tobytes())
        
        return f.name

class TestAuthentication:
    """Test authentication endpoints"""
    
    def test_register_user(self, client):
        """Test user registration"""
        user_data = {
            "username": "newuser",
            "gender": "female",
            "age_range": "18-24",
            "consent_given": True
        }
        response = client.post("/auth/register", json=user_data)
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_register_duplicate_username(self, client, test_user):
        """Test registration with existing username"""
        user_data = {
            "username": test_user.username,
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True
        }
        response = client.post("/auth/register", json=user_data)
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"]
    
    def test_register_without_consent(self, client):
        """Test registration without consent"""
        user_data = {
            "username": "noconsent",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": False
        }
        response = client.post("/auth/register", json=user_data)
        assert response.status_code == 400
        assert "Consent is required" in response.json()["detail"]
    
    def test_login_success(self, client, test_user):
        """Test successful login"""
        response = client.post("/auth/login", json={"username": test_user.username})
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_login_nonexistent_user(self, client):
        """Test login with non-existent user"""
        response = client.post("/auth/login", json={"username": "nonexistent"})
        assert response.status_code == 401
    
    def test_get_current_user(self, client, auth_headers, test_user):
        """Test getting current user info"""
        response = client.get("/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == test_user.username
        assert data["id"] == str(test_user.id)

class TestSentences:
    """Test sentence management endpoints"""
    
    def test_get_next_sentence(self, client, auth_headers, test_sentence):
        """Test getting next sentence to record"""
        response = client.get("/sentences/next", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["text"] == test_sentence.text
        assert data["language"] == test_sentence.language
    
    def test_get_sentences_unauthorized(self, client):
        """Test getting sentences without authentication"""
        response = client.get("/sentences/next")
        assert response.status_code == 401

class TestRecordings:
    """Test recording upload and management"""
    
    def test_upload_recording_success(self, client, auth_headers, test_sentence):
        """Test successful audio recording upload"""
        audio_file_path = create_test_audio_file()
        
        try:
            with open(audio_file_path, 'rb') as audio_file:
                files = {"audio_file": ("test.wav", audio_file, "audio/wav")}
                data = {"sentence_id": str(test_sentence.id)}
                
                response = client.post(
                    "/recordings/",
                    headers=auth_headers,
                    files=files,
                    data=data
                )
                
                assert response.status_code == 200
                result = response.json()
                assert "id" in result
                assert result["status"] == "pending"
                assert result["sentence_id"] == str(test_sentence.id)
        finally:
            os.unlink(audio_file_path)
    
    def test_upload_recording_invalid_sentence(self, client, auth_headers):
        """Test upload with invalid sentence ID"""
        audio_file_path = create_test_audio_file()
        
        try:
            with open(audio_file_path, 'rb') as audio_file:
                files = {"audio_file": ("test.wav", audio_file, "audio/wav")}
                data = {"sentence_id": "invalid-id"}
                
                response = client.post(
                    "/recordings/",
                    headers=auth_headers,
                    files=files,
                    data=data
                )
                
                assert response.status_code == 404
        finally:
            os.unlink(audio_file_path)
    
    def test_upload_recording_unauthorized(self, client, test_sentence):
        """Test upload without authentication"""
        audio_file_path = create_test_audio_file()
        
        try:
            with open(audio_file_path, 'rb') as audio_file:
                files = {"audio_file": ("test.wav", audio_file, "audio/wav")}
                data = {"sentence_id": str(test_sentence.id)}
                
                response = client.post(
                    "/recordings/",
                    files=files,
                    data=data
                )
                
                assert response.status_code == 401
        finally:
            os.unlink(audio_file_path)
    
    def test_get_user_recordings(self, client, auth_headers):
        """Test getting user's recordings"""
        response = client.get("/recordings/my", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

class TestAdminEndpoints:
    """Test admin-only endpoints"""
    
    def test_get_metrics_as_admin(self, client, admin_headers):
        """Test getting metrics as admin"""
        response = client.get("/admin/metrics", headers=admin_headers)
        assert response.status_code == 200
        data = response.json()
        assert "total_recordings" in data
        assert "total_users" in data
        assert "pending_recordings" in data
    
    def test_get_metrics_as_regular_user(self, client, auth_headers):
        """Test getting metrics as regular user (should fail)"""
        response = client.get("/admin/metrics", headers=auth_headers)
        assert response.status_code == 403
    
    def test_get_all_recordings_as_admin(self, client, admin_headers):
        """Test getting all recordings as admin"""
        response = client.get("/admin/recordings", headers=admin_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_moderate_recording_as_admin(self, client, admin_headers, db_session, test_user, test_sentence):
        """Test moderating a recording as admin"""
        # First create a recording
        recording = Recording(
            user_id=test_user.id,
            sentence_id=test_sentence.id,
            filepath="test.wav",
            status="pending"
        )
        db_session.add(recording)
        db_session.commit()
        db_session.refresh(recording)
        
        # Moderate it
        moderation_data = {
            "status": "validated",
            "admin_notes": "Good recording quality"
        }
        response = client.put(
            f"/admin/recordings/{recording.id}/moderate",
            headers=admin_headers,
            json=moderation_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "validated"
        assert data["admin_notes"] == "Good recording quality"

class TestAudioProcessing:
    """Test audio processing functionality"""
    
    def test_audio_validation_format(self, client, auth_headers, test_sentence):
        """Test audio format validation"""
        # Create a non-audio file
        with tempfile.NamedTemporaryFile(suffix='.txt', delete=False) as f:
            f.write(b"This is not an audio file")
            invalid_file_path = f.name
        
        try:
            with open(invalid_file_path, 'rb') as invalid_file:
                files = {"audio_file": ("test.txt", invalid_file, "text/plain")}
                data = {"sentence_id": str(test_sentence.id)}
                
                response = client.post(
                    "/recordings/",
                    headers=auth_headers,
                    files=files,
                    data=data
                )
                
                assert response.status_code == 400
                assert "Unsupported audio format" in response.json()["detail"]
        finally:
            os.unlink(invalid_file_path)
    
    def test_audio_file_size_limit(self, client, auth_headers, test_sentence):
        """Test audio file size validation"""
        # Create a large dummy file
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
            # Write 20MB of data (assuming max is 10MB)
            large_data = b"0" * (20 * 1024 * 1024)
            f.write(large_data)
            large_file_path = f.name
        
        try:
            with open(large_file_path, 'rb') as large_file:
                files = {"audio_file": ("large.wav", large_file, "audio/wav")}
                data = {"sentence_id": str(test_sentence.id)}
                
                response = client.post(
                    "/recordings/",
                    headers=auth_headers,
                    files=files,
                    data=data
                )
                
                assert response.status_code == 400
                assert "too large" in response.json()["detail"]
        finally:
            os.unlink(large_file_path)

class TestRateLimiting:
    """Test rate limiting functionality"""
    
    def test_registration_rate_limit(self, client):
        """Test registration rate limiting"""
        # Make multiple rapid registration attempts
        responses = []
        for i in range(10):
            user_data = {
                "username": f"user{i}",
                "gender": "male",
                "age_range": "25-34",
                "consent_given": True
            }
            response = client.post("/auth/register", json=user_data)
            responses.append(response.status_code)
        
        # Should eventually get rate limited
        assert 429 in responses or len([r for r in responses if r == 200]) < 10
    
    def test_login_rate_limit(self, client):
        """Test login rate limiting"""
        # Make multiple rapid login attempts
        responses = []
        for i in range(10):
            response = client.post("/auth/login", json={"username": "nonexistent"})
            responses.append(response.status_code)
        
        # Should eventually get rate limited
        assert 429 in responses

class TestSecurity:
    """Test security features"""
    
    def test_security_headers(self, client):
        """Test that security headers are present"""
        response = client.get("/docs")
        headers = response.headers
        
        # Check for security headers
        assert "x-content-type-options" in headers
        assert "x-frame-options" in headers
        assert "x-xss-protection" in headers
    
    def test_invalid_token(self, client):
        """Test request with invalid token"""
        invalid_headers = {"Authorization": "Bearer invalid-token"}
        response = client.get("/auth/me", headers=invalid_headers)
        assert response.status_code == 401
    
    def test_expired_token_handling(self, client):
        """Test handling of expired tokens"""
        # This would require mocking JWT expiration
        # For now, just test the endpoint exists
        response = client.post("/auth/refresh")
        assert response.status_code in [401, 422]  # Unauthorized or validation error

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
