"""
Enhanced Rate Limiting Middleware for Wafubi Production
Production-ready với monitoring, analytics và flexible configuration
"""

import time
from collections import defaultdict, deque
from typing import Dict, List, Optional, Tuple

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse


class RateLimiter:
    """
    Enhanced production-ready rate limiter với monitoring và analytics
    Sliding window algorithm với automatic cleanup và detailed metrics
    """

    def __init__(self):
        # Store: {client_id: deque of request timestamps}
        self._clients: Dict[str, deque] = defaultdict(lambda: deque())
        self._last_cleanup = time.time()

        # Analytics tracking
        self._stats = {
            "total_requests": 0,
            "blocked_requests": 0,
            "unique_clients": set(),
            "endpoint_stats": defaultdict(lambda: {"requests": 0, "blocks": 0}),
            "hourly_stats": defaultdict(int),
            "client_violations": defaultdict(int),
        }

        # Configuration cho dynamic rate limiting
        self._dynamic_limits = {}  # Override limits cho specific clients
        self._maintenance_mode = False  # Emergency rate limiting
        self._whitelist = set()  # Clients không bị rate limit

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
        window_seconds: int,
        endpoint_path: str = "unknown",
    ) -> Tuple[bool, Dict[str, str]]:
        """
        Enhanced rate limit checker với analytics và dynamic limits

        Args:
            client_id: Unique identifier for client (IP, user_id, etc.)
            max_requests: Maximum requests allowed in window
            window_seconds: Time window in seconds
            endpoint_path: API endpoint path cho analytics

        Returns:
            (is_allowed, headers) - headers contain rate limit info với analytics
        """
        current_time = time.time()
        cutoff = current_time - window_seconds

        # Analytics tracking
        self._stats["total_requests"] += 1
        self._stats["unique_clients"].add(client_id)
        self._stats["endpoint_stats"][endpoint_path]["requests"] += 1
        hour_key = int(current_time // 3600)
        self._stats["hourly_stats"][hour_key] += 1

        # Check whitelist
        if client_id in self._whitelist:
            headers = {
                "X-RateLimit-Limit": str(max_requests),
                "X-RateLimit-Remaining": str(max_requests),
                "X-RateLimit-Reset": str(int(current_time + window_seconds)),
                "X-RateLimit-Window": str(window_seconds),
                "X-RateLimit-Status": "whitelisted",
            }
            return True, headers

        # Check maintenance mode (emergency braking)
        if self._maintenance_mode:
            maintenance_limit = max(1, max_requests // 10)  # 10% of normal
            max_requests = maintenance_limit

        # Dynamic limits override
        if client_id in self._dynamic_limits:
            max_requests = self._dynamic_limits[client_id].get("limit", max_requests)

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
        else:
            # Track violation
            self._stats["blocked_requests"] += 1
            self._stats["endpoint_stats"][endpoint_path]["blocks"] += 1
            self._stats["client_violations"][client_id] += 1

        # Calculate headers với enhanced info
        remaining = max(0, max_requests - request_count - (1 if is_allowed else 0))
        reset_time = int(current_time + window_seconds)

        headers = {
            "X-RateLimit-Limit": str(max_requests),
            "X-RateLimit-Remaining": str(remaining),
            "X-RateLimit-Reset": str(reset_time),
            "X-RateLimit-Window": str(window_seconds),
            "X-RateLimit-Client": client_id[:20],  # Truncated for privacy
        }

        # Add status info
        if self._maintenance_mode:
            headers["X-RateLimit-Mode"] = "maintenance"
        if client_id in self._dynamic_limits:
            headers["X-RateLimit-Type"] = "dynamic"

        return is_allowed, headers

    def get_analytics(self) -> Dict:
        """Get comprehensive rate limiting analytics"""
        current_time = time.time()

        # Calculate stats
        total_clients = len(self._stats["unique_clients"])
        block_rate = (
            self._stats["blocked_requests"]
            / max(1, self._stats["total_requests"])
            * 100
        )

        # Recent activity (last hour)
        hour_key = int(current_time // 3600)
        recent_activity = sum(
            count
            for h, count in self._stats["hourly_stats"].items()
            if h >= hour_key - 1
        )

        # Top violators
        top_violators = sorted(
            self._stats["client_violations"].items(), key=lambda x: x[1], reverse=True
        )[:10]

        return {
            "overview": {
                "total_requests": self._stats["total_requests"],
                "blocked_requests": self._stats["blocked_requests"],
                "block_rate_percent": round(block_rate, 2),
                "unique_clients": total_clients,
                "active_clients": len(self._clients),
                "recent_activity_1h": recent_activity,
                "maintenance_mode": self._maintenance_mode,
                "whitelist_size": len(self._whitelist),
                "dynamic_limits": len(self._dynamic_limits),
            },
            "endpoint_stats": dict(self._stats["endpoint_stats"]),
            "top_violators": top_violators,
            "hourly_breakdown": dict(self._stats["hourly_stats"]),
            "memory_usage": {
                "tracked_clients": len(self._clients),
                "total_entries": sum(len(q) for q in self._clients.values()),
            },
        }

    def add_to_whitelist(self, client_id: str, reason: str = "manual"):
        """Add client to whitelist (bypasses rate limiting)"""
        self._whitelist.add(client_id)
        print(f"[RATE LIMIT] Client {client_id} whitelisted: {reason}")

    def remove_from_whitelist(self, client_id: str):
        """Remove client from whitelist"""
        self._whitelist.discard(client_id)
        print(f"[RATE LIMIT] Client {client_id} removed from whitelist")

    def set_dynamic_limit(self, client_id: str, limit: int, reason: str = "manual"):
        """Set custom rate limit for specific client"""
        self._dynamic_limits[client_id] = {
            "limit": limit,
            "reason": reason,
            "set_at": time.time(),
        }
        print(f"[RATE LIMIT] Dynamic limit {limit} set for {client_id}: {reason}")

    def enable_maintenance_mode(self, reason: str = "manual"):
        """Enable emergency maintenance mode (severe rate limiting)"""
        self._maintenance_mode = True
        print(f"[RATE LIMIT] Maintenance mode enabled: {reason}")

    def disable_maintenance_mode(self):
        """Disable maintenance mode"""
        self._maintenance_mode = False
        print("[RATE LIMIT] Maintenance mode disabled")

    def reset_client(self, client_id: str):
        """Reset rate limiting for specific client"""
        if client_id in self._clients:
            del self._clients[client_id]
        if client_id in self._stats["client_violations"]:
            del self._stats["client_violations"][client_id]
        print(f"[RATE LIMIT] Client {client_id} reset")

    def get_client_status(self, client_id: str) -> Dict:
        """Get detailed status cho specific client"""
        current_time = time.time()
        client_requests = self._clients.get(client_id, deque())

        recent_requests = [
            ts for ts in client_requests if current_time - ts < 3600  # Last hour
        ]

        return {
            "client_id": client_id,
            "active_requests": len(client_requests),
            "recent_requests_1h": len(recent_requests),
            "violations": self._stats["client_violations"].get(client_id, 0),
            "is_whitelisted": client_id in self._whitelist,
            "has_dynamic_limit": client_id in self._dynamic_limits,
            "dynamic_limit_info": self._dynamic_limits.get(client_id),
            "last_request": max(client_requests) if client_requests else None,
        }


# Global rate limiter instance
rate_limiter = RateLimiter()


def get_client_identifier(request: Request) -> str:
    """
    Generate client identifier for rate limiting
    Priority: user_id > API key > IP address

    Identifying by user matters more than it looks. Vietnamese mobile carriers
    put large numbers of subscribers behind the same NAT address, so a purely
    IP-keyed limiter would let one heavy user exhaust the budget of everyone on
    their network — and would leave a per-account abuser free to rotate IPs.
    The token is decoded, not looked up: no database hit on every request.
    """
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        # Local import: this middleware is imported at app start-up, before
        # settings-dependent modules are safe to pull in at module scope.
        from app.core.security import verify_token

        try:
            user_id = verify_token(auth[7:])
            if user_id:
                return f"user:{user_id}"
        except Exception:
            # An unreadable token is not a rate-limiting decision; fall through
            # to IP and let the auth dependency reject it properly.
            pass

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
    """Production-ready rate limit configurations cho Wafubi"""

    # General API limits (per hour) - generous for normal usage
    GENERAL_LIMIT = 1000
    GENERAL_WINDOW = 3600

    # Credential-submitting endpoints (per 15 minutes) - strict, brute force.
    # Applies ONLY to login/register/google/password-reset. It must never cover
    # /auth/me or /auth/refresh: those are ordinary session traffic that the app
    # fires on every resume and every token expiry, and lumping them in here
    # would lock real users out within minutes of opening the app.
    AUTH_LIMIT = 15
    AUTH_WINDOW = 900

    # Session endpoints (/auth/me, /auth/refresh, /auth/logout) - generous.
    SESSION_LIMIT = 120
    SESSION_WINDOW = 3600

    # AI Coach limits (per minute) - moderate for real-time chat
    AI_COACH_LIMIT = 20
    AI_COACH_WINDOW = 60

    # Vision/Smart Scan limits (per minute) - limited due to ML processing cost
    VISION_LIMIT = 10
    VISION_WINDOW = 60

    # Daily caps for the endpoints that spend real money on the Anthropic API.
    # The per-minute limits above stop bursts but do nothing about sustained
    # use: 10 scans/minute is 14,400 scans/day from a single account. These
    # second-tier windows are what actually bounds the monthly bill.
    VISION_DAILY_LIMIT = 120
    AI_COACH_DAILY_LIMIT = 300
    AI_DAILY_WINDOW = 86400

    # Search limits (per minute) - moderate
    SEARCH_LIMIT = 30
    SEARCH_WINDOW = 60

    # Social features (per hour) - generous for social interaction
    SOCIAL_LIMIT = 200
    SOCIAL_WINDOW = 3600

    # Data logging (per hour) - generous for active users
    LOGGING_LIMIT = 500
    LOGGING_WINDOW = 3600

    # Analytics/Stats (per hour) - moderate
    ANALYTICS_LIMIT = 100
    ANALYTICS_WINDOW = 3600

    # Admin Console (per hour). Not "very strict": these routes are already
    # gated by require_cap, and a single console session legitimately fires
    # dozens of reads while an operator browses. Too tight a limit here locks
    # out the person investigating an incident, which is when they need it most.
    ADMIN_LIMIT = 600
    ADMIN_WINDOW = 3600


async def rate_limit_middleware(request: Request, call_next):
    """
    Enhanced FastAPI middleware for production rate limiting với monitoring
    """
    start_time = time.time()

    # Skip rate limiting for health/admin endpoints
    if request.url.path in ["/health", "/admin/rate-limit", "/docs", "/openapi.json"]:
        return await call_next(request)

    try:
        # Get client identifier
        client_id = get_client_identifier(request)

        # Determine rate limits based on endpoint. A path may carry several
        # tiers (e.g. a burst window plus a daily cap); all must pass.
        path = request.url.path
        tiers = _get_rate_limit_tiers(path)

        is_allowed = True
        headers: Dict[str, str] = {}
        max_requests, window = tiers[0][0], tiers[0][1]
        tightest = None  # (remaining, headers, max, window)

        for tier_max, tier_window, bucket in tiers:
            # Each tier keeps its own bucket: the limiter prunes a client's
            # deque to whatever window it is called with, so a shared key would
            # let the 60s tier erase the 24h tier's history.
            allowed, tier_headers = rate_limiter.is_allowed(
                f"{client_id}|{bucket}", tier_max, tier_window, path
            )

            if not allowed:
                is_allowed = False
                headers = tier_headers
                max_requests, window = tier_max, tier_window
                break

            # Report the tier closest to exhaustion, not whichever happened to
            # run last. A caller reading "120 remaining" off the daily cap while
            # the minute burst allows 3 more cannot back off correctly.
            try:
                remaining = int(tier_headers.get("X-RateLimit-Remaining", tier_max))
            except (TypeError, ValueError):
                remaining = tier_max
            if tightest is None or remaining < tightest[0]:
                tightest = (remaining, tier_headers, tier_max, tier_window)

        if is_allowed and tightest is not None:
            _, headers, max_requests, window = tightest

        if not is_allowed:
            # Enhanced error response với helpful info
            retry_after = int(headers.get("X-RateLimit-Reset", 60))
            current_time = int(time.time())
            wait_seconds = max(0, retry_after - current_time)

            error_response = JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "error": "Rate limit exceeded",
                    "message": f"Too many requests to {path}. Limit: {max_requests}/{window}s",
                    "retry_after_seconds": wait_seconds,
                    "retry_after_timestamp": retry_after,
                    "client_id": client_id[:20],  # Truncated for privacy
                    "limit_info": {
                        "max_requests": max_requests,
                        "window_seconds": window,
                        "remaining": headers.get("X-RateLimit-Remaining", "0"),
                    },
                },
                headers=headers,
            )

            # Log violation for monitoring
            print(
                f"[RATE LIMIT BLOCK] {client_id} blocked on {path} "
                f"({max_requests}/{window}s limit)"
            )

            return error_response

        # Process request
        response = await call_next(request)

        # Add enhanced rate limit headers
        for header_name, header_value in headers.items():
            response.headers[header_name] = header_value

        # Add performance header
        request_duration = round((time.time() - start_time) * 1000, 2)
        response.headers["X-Request-Duration"] = f"{request_duration}ms"

        return response

    except Exception as e:
        # Log error nhưng không block request trong production
        print(f"[RATE LIMIT ERROR] {str(e)} for {request.url.path}")

        # Fallback: process request normally
        response = await call_next(request)
        response.headers["X-RateLimit-Status"] = "error-fallback"
        return response


# Credential-submitting auth routes. Everything else under /auth/ is ordinary
# session traffic and must not share the brute-force budget.
CREDENTIAL_AUTH_PATHS = (
    "/auth/login",
    "/auth/register",
    "/auth/google",
    "/auth/forgot-password",
    "/auth/reset-password",
)


def _get_rate_limit_tiers(path: str) -> List[Tuple[int, int, str]]:
    """Rate limit tiers that apply to a path.

    Returns a list of (max_requests, window_seconds, bucket_label). A request
    must satisfy every tier. Multiple tiers let a path have both a burst limit
    and a long-window cap — the AI endpoints need both, because a per-minute
    limit says nothing about what a single account can spend in a day.

    Each tier gets its own bucket label because the limiter stores one
    timestamp deque per key and prunes it to the window it was called with;
    sharing a key between a 60s and an 86400s tier would have the short window
    silently delete the long window's history.
    """
    # Credential endpoints - strict, brute force protection
    if any(path.endswith(p) or p in path for p in CREDENTIAL_AUTH_PATHS):
        return [(RateLimitConfig.AUTH_LIMIT, RateLimitConfig.AUTH_WINDOW, "auth")]

    # Remaining /auth/ routes (/me, /refresh, /logout) - normal session traffic
    if "/auth/" in path:
        return [
            (RateLimitConfig.SESSION_LIMIT, RateLimitConfig.SESSION_WINDOW, "session")
        ]

    # AI Coach - burst limit plus a daily spend cap
    if "/coach/" in path:
        return [
            (RateLimitConfig.AI_COACH_LIMIT, RateLimitConfig.AI_COACH_WINDOW, "burst"),
            (
                RateLimitConfig.AI_COACH_DAILY_LIMIT,
                RateLimitConfig.AI_DAILY_WINDOW,
                "daily",
            ),
        ]

    # Vision/Smart Scan - the most expensive call in the product
    if "/vision/" in path or "estimate-volume" in path:
        return [
            (RateLimitConfig.VISION_LIMIT, RateLimitConfig.VISION_WINDOW, "burst"),
            (
                RateLimitConfig.VISION_DAILY_LIMIT,
                RateLimitConfig.AI_DAILY_WINDOW,
                "daily",
            ),
        ]

    return [(*_get_rate_limit_for_path(path), "general")]


def _get_rate_limit_for_path(path: str) -> Tuple[int, int]:
    """
    Single-tier limits for the remaining paths.
    Auth, Coach and Vision are handled by _get_rate_limit_tiers above.
    Returns (max_requests, window_seconds)
    """
    # Social features - generous for user interaction
    if "/friends/" in path or "/social/" in path:
        return RateLimitConfig.SOCIAL_LIMIT, RateLimitConfig.SOCIAL_WINDOW

    # Search endpoints - moderate
    elif "/search" in path:
        return RateLimitConfig.SEARCH_LIMIT, RateLimitConfig.SEARCH_WINDOW

    # Data logging endpoints - generous for active users
    elif "/intake-logs" in path or "/daily-summary" in path:
        return RateLimitConfig.LOGGING_LIMIT, RateLimitConfig.LOGGING_WINDOW

    # Analytics and stats endpoints
    elif "/stats" in path or "/analytics" in path or "/insights" in path:
        return RateLimitConfig.ANALYTICS_LIMIT, RateLimitConfig.ANALYTICS_WINDOW

    # Admin Console
    elif "/admin/" in path or "/rate-limit" in path:
        return RateLimitConfig.ADMIN_LIMIT, RateLimitConfig.ADMIN_WINDOW

    # General API endpoints - generous default
    else:
        return RateLimitConfig.GENERAL_LIMIT, RateLimitConfig.GENERAL_WINDOW


def rate_limit(
    max_requests: int, window_seconds: int, key_func: Optional[callable] = None
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
                    headers=headers,
                )

            # Call the original function
            response = await func(request, *args, **kwargs)

            # Add headers if response supports it
            if hasattr(response, "headers"):
                for header_name, header_value in headers.items():
                    response.headers[header_name] = header_value

            return response

        return wrapper

    return decorator


# Specialized rate limiters for common use cases
def auth_rate_limit(func):
    """Rate limit for authentication endpoints"""
    return rate_limit(RateLimitConfig.AUTH_LIMIT, RateLimitConfig.AUTH_WINDOW)(func)


def upload_rate_limit(func):
    """Rate limit for file upload endpoints"""
    return rate_limit(RateLimitConfig.UPLOAD_LIMIT, RateLimitConfig.UPLOAD_WINDOW)(func)


def search_rate_limit(func):
    """Rate limit for search endpoints"""
    return rate_limit(RateLimitConfig.SEARCH_LIMIT, RateLimitConfig.SEARCH_WINDOW)(func)


def ai_coach_rate_limit(func):
    """Rate limit for AI Coach endpoints"""
    return rate_limit(RateLimitConfig.AI_COACH_LIMIT, RateLimitConfig.AI_COACH_WINDOW)(
        func
    )


def vision_rate_limit(func):
    """Rate limit for Vision/Smart Scan endpoints"""
    return rate_limit(RateLimitConfig.VISION_LIMIT, RateLimitConfig.VISION_WINDOW)(func)


# Rate Limiting Management API Functions
# Sử dụng trong admin endpoints


async def get_rate_limit_analytics():
    """Get comprehensive rate limiting analytics cho admin dashboard"""
    try:
        analytics = rate_limiter.get_analytics()
        return {"status": "success", "analytics": analytics, "timestamp": time.time()}
    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}


async def manage_client_rate_limit(
    client_id: str,
    action: str,
    limit: Optional[int] = None,
    reason: str = "admin action",
):
    """
    Manage rate limiting cho specific client

    Actions: whitelist, unwhitelist, set_limit, reset, get_status
    """
    try:
        result = {}

        if action == "whitelist":
            rate_limiter.add_to_whitelist(client_id, reason)
            result["message"] = f"Client {client_id} whitelisted"

        elif action == "unwhitelist":
            rate_limiter.remove_from_whitelist(client_id)
            result["message"] = f"Client {client_id} removed from whitelist"

        elif action == "set_limit":
            if limit is None:
                return {"status": "error", "error": "Limit value required"}
            rate_limiter.set_dynamic_limit(client_id, limit, reason)
            result["message"] = f"Dynamic limit {limit} set for {client_id}"

        elif action == "reset":
            rate_limiter.reset_client(client_id)
            result["message"] = f"Client {client_id} reset"

        elif action == "get_status":
            status = rate_limiter.get_client_status(client_id)
            result["client_status"] = status

        else:
            return {"status": "error", "error": f"Unknown action: {action}"}

        result["status"] = "success"
        result["timestamp"] = time.time()
        return result

    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}


async def toggle_maintenance_mode(enable: bool, reason: str = "admin action"):
    """Enable/disable emergency maintenance mode"""
    try:
        if enable:
            rate_limiter.enable_maintenance_mode(reason)
            message = "Maintenance mode enabled"
        else:
            rate_limiter.disable_maintenance_mode()
            message = "Maintenance mode disabled"

        return {
            "status": "success",
            "message": message,
            "maintenance_mode": enable,
            "timestamp": time.time(),
        }
    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}
