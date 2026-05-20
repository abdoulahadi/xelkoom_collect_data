from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
import uuid
from app.db.database import get_db
from app.core.auth import authenticate_user, create_access_token, get_current_active_user
from app.core.config import settings
from app.core.pydantic_utils import model_to_dict
from app.models import User
from app.schemas import UserCreate, UserResponse, Token, LoginRequest

router = APIRouter()

@router.post("/register", response_model=Token)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    import logging
    from app.core.auth import get_password_hash
    
    logger = logging.getLogger("auth")
    
    # Check if username already exists
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        logger.warning(f"Registration failed: username already exists: {user_data.username}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
    
    # Validate consent
    if not user_data.consent_given:
        logger.warning(f"Registration failed: consent not given for {user_data.username}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Consent is required to register"
        )
    
    # Create new user
    db_user = User(
        username=user_data.username,
        hashed_password=get_password_hash(user_data.password),
        gender=user_data.gender,
        age_range=user_data.age_range,
        consent_given=user_data.consent_given,
        is_active=True
    )
    
    logger.info(f"Creating new user: {user_data.username}")
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": db_user.username}, 
        expires_delta=access_token_expires
    )
    
    # Convertir le modèle User en dictionnaire compatible avec Pydantic
    prepared_user = model_to_dict(db_user)
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(prepared_user)
    )

@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """Login user with username and password (JSON body only)"""
    import logging
    logger = logging.getLogger("auth")
    
    logger.info(f"Login attempt for username: {login_data.username}")
    
    user = authenticate_user(db, login_data.username, login_data.password)
    if not user:
        logger.error(f"Authentication failed for username: {login_data.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    logger.info(f"User authenticated successfully: {user.username}")
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, 
        expires_delta=access_token_expires
    )
    
    # Convertir le modèle User en dictionnaire compatible avec Pydantic
    prepared_user = model_to_dict(user)
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(prepared_user)
    )

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    # Convertir le modèle User en dictionnaire compatible avec Pydantic
    prepared_user = model_to_dict(current_user)
    return UserResponse.model_validate(prepared_user)

@router.post("/refresh", response_model=Token)
async def refresh_token(current_user: User = Depends(get_current_active_user)):
    """Refresh access token"""
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": current_user.username}, 
        expires_delta=access_token_expires
    )
    
    # Convertir le modèle User en dictionnaire compatible avec Pydantic
    prepared_user = model_to_dict(current_user)
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(prepared_user)
    )
