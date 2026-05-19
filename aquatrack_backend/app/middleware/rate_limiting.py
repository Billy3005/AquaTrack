"""
Rate limiting middleware for API protection
Supports both Redis and in-memory backends
"""
import time
from collections import defaultdict, deque
from typing import Dict, Optional, Tuple

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse


class RateLimiter:
    """In-memory rate limiter with sliding window"""

    def __init__(self):
        # Store: {client_id: deque of request timestamps}
        self._clients: Dict[str, deque] = defaultdict(lambda: deque())
        self._last_cleanup = time.time()

    def _cleanup_expired(self, current_time: float, window: int) -> None:
        """Remove expired entries to prevent memory leaks"""
        if current_time - self._last_cleanup > 300:  # Cleanup every 5 minutes
            cutoff = current_time - window
            for client_id in list(self._clients.keys()):
                client_requests = self._clients[client_id]
                # Remove old requests
                while client_requests and client_requests[0] < cutoff:
                    client_requests.popleft()
                # Remove empty entries
                if not client_requests:
                    del self._clients[client_id]
            self._last_cleanup = current_time

    def is_allowed(
        self,
        client_id: str,
        max_requests: int,
        window_seconds: int
    ) -> Tuple[bool, Dict[str, str]]:
        """
        Check if request is allowed under rate limit

        Args:
            client_id: Unique identifier for client (IP, user_id, etc.)
            max_requests: Maximum requests allowed in window
            window_seconds: Time window in seconds

        Returns:
            (is_allowed, headers) - headers contain rate limit info
        """
        current_time = time.time()
        cutoff = current_time - window_seconds

        # Cleanup old entries
        self._cleanup_expired(current_time, window_seconds)

        # Get client's request history
        client_requests = self._clients[client_id]

        # Remove requests outside the window
        while client_requests and client_requests[0] < cutoff:
            client_requests.popleft()

        # Check if limit exceeded
        request_count = len(client_requests)
        is_allowed = request_count < max_requests

        if is_allowed:
            # Add current request
            client_requests.append(current_time)

        # Calculate headers
        remaining = max(0, max_requests - request_count - (1 if is_allowed else 0))
        reset_time = int(current_time + window_seconds)

        headers = {
            "X-RateLimit-Limit": str(max_requests),
            "X-RateLimit-Remaining": str(remaining),
            "X-RateLimit-Reset": str(reset_time),
            "X-RateLimit-Window": str(window_seconds),
        }

        return is_allowed, headers


# Global rate limiter instance
rate_limiter = RateLimiter()


def get_client_identifier(request: Request) -> str:
    """
    Generate client identifier for rate limiting
    Priority: user_id > API key > IP address
    """
    # Try to get authenticated user ID
    if hasattr(request.state, 'user_id') and request.state.user_id:
        return f"user:{request.state.user_id}"

    # Try API key from headers
    api_key = request.headers.get("X-API-Key")
    if api_key:
        return f"api:{api_key[:10]}"  # Use first 10 chars for privacy

    # Fallback to IP address
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        client_ip = request.client.host if request.client else "unknown"

    return f"ip:{client_ip}"


class RateLimitConfig:
    """Rate limit configurations for different endpoint types"""

    # General API limits (per hour)
    GENERAL_LIMIT = 1000
    GENERAL_WINDOW = 3600

    # Authentication limits (per 15 minutes)
    AUTH_LIMIT = 5
    AUTH_WINDOW = 900

    # Image upload limits (per minute)
    UPLOAD_LIMIT = 10
    UPLOAD_WINDOW = 60

    # Search limits (per minute)
    SEARCH_LIMIT = 30
    SEARCH_WINDOW = 60

    # Social features (per hour)
    SOCIAL_LIMIT = 200
    SOCIAL_WINDOW = 3600


async def rate_limit_middleware(request: Request, call_next):
    """
    FastAPI middleware for rate limiting
    """
    # Get client identifier
    client_id = get_client_identifier(request)

    # Determine rate limit based on endpoint
    path = request.url.path
    max_requests, window = _get_rate_limit_for_path(path)

    # Check rate limit
    is_allowed, headers = rate_limiter.is_allowed(
        client_id, max_requests, window
    )

    if not is_allowed:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "error": "Rate limit exceeded",
                "message": f"Too many requests. Limit: {max_requests}/{window}s",
                "retry_after": headers["X-RateLimit-Reset"],
            },
            headers=headers
        )

    # Process request
    response = await call_next(request)

    # Add rate limit headers to successful responses
    for header_name, header_value in headers.items():
        response.headers[header_name] = header_value

    return response


def _get_rate_limit_for_path(path: str) -> Tuple[int, int]:
    """
    Get appropriate rate limit for API path
    Returns (max_requests, window_seconds)
    """
    # Authentication endpoints - stricter limits
    if "/auth/" in path:
        return RateLimitConfig.AUTH_LIMIT, RateLimitConfig.AUTH_WINDOW

    # Vision/upload endpoints - moderate limits
    elif "/vision/" in path or "upload" in path:
        return RateLimitConfig.UPLOAD_LIMIT, RateLimitConfig.UPLOAD_WINDOW

    # Search endpoints - moderate limits
    elif "/search" in path or "/friends/search" in path:
        return RateLimitConfig.SEARCH_LIMIT, RateLimitConfig.SEARCH_WINDOW

    # Social features - moderate limits
    elif "/friends/" in path:
        return RateLimitConfig.SOCIAL_LIMIT, RateLimitConfig.SOCIAL_WINDOW

    # General API endpoints - generous limits
    else:
        return RateLimitConfig.GENERAL_LIMIT, RateLimitConfig.GENERAL_WINDOW


def rate_limit(
    max_requests: int,
    window_seconds: int,
    key_func: Optional[callable] = None
):
    """
    Decorator for applying rate limits to specific endpoints

    Usage:
        @rate_limit(10, 60)  # 10 requests per minute
        async def my_endpoint():
            pass
    """
    def decorator(func):
        async def wrapper(request: Request, *args, **kwargs):
            # Get client identifier
            if key_func:
                client_id = key_func(request, *args, **kwargs)
            else:
                client_id = get_client_identifier(request)

            # Check rate limit
            is_allowed, headers = rate_limiter.is_allowed(
                client_id, max_requests, window_seconds
            )

            if not is_allowed:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "error": "Rate limit exceeded",
                        "limit": max_requests,
                        "window": window_seconds,
                        "retry_after": headers["X-RateLimit-Reset"],
                    },
                    headers=headers
                )

            # Call the original function
            response = await func(request, *args, **kwargs)

            # Add headers if response supports it
            if hasattr(response, 'headers'):
                for header_name, header_value in headers.items():
                    response.headers[header_name] = header_value

            return response

        return wrapper
    return decorator


# Specialized rate limiters for common use cases
def auth_rate_limit(func):
    """Rate limit for authentication endpoints"""
    return rate_limit(
        RateLimitConfig.AUTH_LIMIT,
        RateLimitConfig.AUTH_WINDOW
    )(func)


def upload_rate_limit(func):
    """Rate limit for file upload endpoints"""
    return rate_limit(
        RateLimitConfig.UPLOAD_LIMIT,
        RateLimitConfig.UPLOAD_WINDOW
    )(func)


def search_rate_limit(func):
    """Rate limit for search endpoints"""
    return rate_limit(
        RateLimitConfig.SEARCH_LIMIT,
        RateLimitConfig.SEARCH_WINDOW
    )(func)