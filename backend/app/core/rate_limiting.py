"""
Rate limiting middleware for FastAPI
Implements OWASP rate limiting guidelines
"""
import time
from typing import Dict, Optional
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
import logging
import redis
from app.core.config import settings

logger = logging.getLogger(__name__)

# Redis connection for distributed rate limiting
redis_client = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=settings.REDIS_DB,
    decode_responses=True
) if settings.REDIS_URL else None

def get_user_id_from_request(request: Request) -> str:
    """Extract user ID from JWT token for user-specific rate limiting"""
    try:
        # Get token from Authorization header
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            # In production, decode JWT to get user_id
            # For now, return IP as fallback
            return get_remote_address(request)
        return get_remote_address(request)
    except Exception:
        return get_remote_address(request)

# Create limiter instance
limiter = Limiter(
    key_func=get_user_id_from_request,
    storage_uri=settings.REDIS_URL if settings.REDIS_URL else "memory://",
    default_limits=["1000/hour", "100/minute"]
)

class SecurityMiddleware:
    """OWASP Security Headers Middleware"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = dict(message.get("headers", []))
                
                # OWASP Security Headers
                security_headers = {
                    b"x-content-type-options": b"nosniff",
                    b"x-frame-options": b"DENY",
                    b"x-xss-protection": b"1; mode=block",
                    b"strict-transport-security": b"max-age=31536000; includeSubDomains",
                    b"content-security-policy": b"default-src 'self'; script-src 'self' 'unsafe-inline'",
                    b"referrer-policy": b"strict-origin-when-cross-origin",
                    b"permissions-policy": b"geolocation=(), microphone=(), camera=()"
                }
                
                headers.update(security_headers)
                message["headers"] = list(headers.items())
            
            await send(message)
        
        await self.app(scope, receive, send_wrapper)

def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    """Custom rate limit exceeded handler with security logging"""
    client_ip = get_remote_address(request)
    
    # Log security event
    logger.warning(
        "Rate limit exceeded",
        client_ip=client_ip,
        path=request.url.path,
        method=request.method,
        limit=str(exc.detail)
    )
    
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={
            "error": "Rate limit exceeded",
            "detail": "Too many requests. Please try again later.",
            "retry_after": 60
        },
        headers={"Retry-After": "60"}
    )

# Different rate limits for different endpoints
class RateLimits:
    # Authentication endpoints - stricter limits
    AUTH_LOGIN = "5/minute"
    AUTH_REGISTER = "3/minute"
    
    # Audio upload - moderate limits
    AUDIO_UPLOAD = "10/minute"
    
    # General API - generous limits
    API_READ = "100/minute"
    API_WRITE = "30/minute"
    
    # Admin endpoints - moderate limits
    ADMIN_READ = "50/minute"
    ADMIN_WRITE = "20/minute"

def get_client_identifier(request: Request) -> str:
    """Get client identifier for rate limiting"""
    # Try to get user ID from JWT first
    try:
        # In production, decode JWT token to get user_id
        user_id = getattr(request.state, 'user_id', None)
        if user_id:
            return f"user:{user_id}"
    except:
        pass
    
    # Fallback to IP address
    return f"ip:{get_remote_address(request)}"

class EnhancedRateLimiter:
    """Enhanced rate limiter with user-specific and IP-based limiting"""
    
    def __init__(self):
        self.redis_client = redis_client
        self.memory_store: Dict[str, Dict] = {}
    
    async def is_allowed(self, identifier: str, limit: str, window: int = 60) -> tuple[bool, Dict]:
        """Check if request is allowed based on rate limit"""
        current_time = int(time.time())
        window_start = current_time - window
        
        if self.redis_client:
            return await self._check_redis(identifier, limit, current_time, window_start)
        else:
            return self._check_memory(identifier, limit, current_time, window_start)
    
    async def _check_redis(self, identifier: str, limit: str, current_time: int, window_start: int) -> tuple[bool, Dict]:
        """Redis-based rate limiting for distributed systems"""
        pipe = self.redis_client.pipeline()
        
        # Clean old entries
        pipe.zremrangebyscore(identifier, 0, window_start)
        
        # Count current requests
        pipe.zcard(identifier)
        
        # Add current request
        pipe.zadd(identifier, {str(current_time): current_time})
        
        # Set expiry
        pipe.expire(identifier, 3600)  # 1 hour
        
        results = pipe.execute()
        current_count = results[1]
        
        limit_count = int(limit.split('/')[0])
        
        return current_count < limit_count, {
            "current": current_count,
            "limit": limit_count,
            "reset_time": current_time + 60
        }
    
    def _check_memory(self, identifier: str, limit: str, current_time: int, window_start: int) -> tuple[bool, Dict]:
        """Memory-based rate limiting for single instance"""
        if identifier not in self.memory_store:
            self.memory_store[identifier] = {"requests": [], "count": 0}
        
        store = self.memory_store[identifier]
        
        # Clean old requests
        store["requests"] = [req_time for req_time in store["requests"] if req_time > window_start]
        
        # Add current request
        store["requests"].append(current_time)
        current_count = len(store["requests"])
        
        limit_count = int(limit.split('/')[0])
        
        return current_count <= limit_count, {
            "current": current_count,
            "limit": limit_count,
            "reset_time": current_time + 60
        }

# Global rate limiter instance
rate_limiter = EnhancedRateLimiter()
