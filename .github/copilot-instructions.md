# Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Context

This is a comprehensive audio data collection platform for Wolof Text-to-Speech (TTS) training. The project consists of:

1. **Backend (FastAPI)**: REST API for managing users, sentences, and audio recordings
2. **Mobile App (Flutter)**: Cross-platform app for audio recording
3. **Admin Dashboard**: Web interface for content moderation and statistics
4. **Database**: PostgreSQL with SQLAlchemy ORM

## Architecture Guidelines

- Use FastAPI for backend APIs with async/await patterns
- Implement JWT authentication with role-based access
- Use SQLAlchemy for database operations
- Store audio files locally or on S3
- Process audio with FFmpeg for normalization
- Follow REST API conventions
- Use Pydantic for data validation
- Implement GDPR compliance features

## Code Standards

- Use type hints throughout Python code
- Follow PEP 8 style guidelines
- Use dependency injection in FastAPI
- Implement proper error handling and logging
- Use environment variables for configuration
- Write comprehensive docstrings
- Include unit tests for critical functions

## Audio Processing

- Accept WAV files (mono, 16kHz)
- Normalize audio levels
- Trim silence from recordings
- Validate audio quality
- Store metadata with recordings

## Security Considerations

- Implement input validation
- Use secure password hashing
- Protect against SQL injection
- Implement rate limiting
- Log security events
- Follow OWASP guidelines
