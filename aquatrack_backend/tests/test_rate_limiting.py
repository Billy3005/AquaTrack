"""Rate limiting — path classification, tiering, and client identity.

These tests exist because turning rate limiting on naively would have locked
real users out: every /auth/* route shared one 5-per-15-minutes budget, and
every client was keyed by IP, which Vietnamese carrier NAT makes a shared
resource. Both are regressions worth catching.
"""

import pytest

from app.middleware.rate_limiting import (
    CREDENTIAL_AUTH_PATHS,
    RateLimitConfig,
    RateLimiter,
    _get_rate_limit_tiers,
)


class TestPathClassification:
    @pytest.mark.parametrize("path", CREDENTIAL_AUTH_PATHS)
    def test_credential_endpoints_get_the_strict_budget(self, path):
        tiers = _get_rate_limit_tiers(f"/api/v1{path}")
        assert len(tiers) == 1
        assert tiers[0][0] == RateLimitConfig.AUTH_LIMIT
        assert tiers[0][1] == RateLimitConfig.AUTH_WINDOW

    @pytest.mark.parametrize(
        "path", ["/api/v1/auth/me", "/api/v1/auth/refresh", "/api/v1/auth/logout"]
    )
    def test_session_endpoints_do_not_share_the_brute_force_budget(self, path):
        """The app calls /auth/me on resume and /auth/refresh every time the
        30-minute token expires. Sharing the login budget would lock users out
        of their own account within minutes."""
        limit, window, bucket = _get_rate_limit_tiers(path)[0]
        assert bucket == "session"
        assert limit == RateLimitConfig.SESSION_LIMIT
        assert limit > RateLimitConfig.AUTH_LIMIT

    @pytest.mark.parametrize(
        "path", ["/api/v1/vision/estimate-volume", "/api/v1/coach/chat"]
    )
    def test_claude_endpoints_have_a_burst_and_a_daily_tier(self, path):
        """A per-minute cap alone does not bound the monthly Anthropic bill."""
        tiers = _get_rate_limit_tiers(path)
        buckets = {bucket for _, _, bucket in tiers}
        assert buckets == {"burst", "daily"}

        daily = next(t for t in tiers if t[2] == "daily")
        assert daily[1] == RateLimitConfig.AI_DAILY_WINDOW

    def test_admin_console_is_not_throttled_into_uselessness(self):
        limit, _, _ = _get_rate_limit_tiers("/api/v1/admin/users")[0]
        # A single browsing session legitimately makes dozens of reads.
        assert limit >= 300


class TestTierIsolation:
    def test_short_window_does_not_erase_long_window_history(self):
        """The limiter prunes a client's deque to whatever window it is called
        with, so tiers must not share a bucket key. This asserts the property
        the middleware relies on when it appends |burst and |daily."""
        limiter = RateLimiter()

        # Same client, two bucket keys, very different windows.
        for _ in range(5):
            limiter.is_allowed("user:abc|daily", 100, 86400, "/vision")

        # A burst-window call on the *shared* key would prune those 5 away.
        limiter.is_allowed("user:abc|burst", 10, 60, "/vision")

        assert len(limiter._clients["user:abc|daily"]) == 5

    def test_daily_tier_blocks_after_its_limit(self):
        limiter = RateLimiter()
        for _ in range(3):
            assert limiter.is_allowed("user:abc|daily", 3, 86400, "/vision")[0]
        allowed, _ = limiter.is_allowed("user:abc|daily", 3, 86400, "/vision")
        assert allowed is False


class TestClientIdentity:
    def _request(self, headers: dict, host: str = "1.2.3.4"):
        class _Client:
            def __init__(self, h):
                self.host = h

        class _Request:
            def __init__(self, headers, host):
                self.headers = headers
                self.client = _Client(host)
                self.state = type("S", (), {})()

        return _Request(headers, host)

    def test_authenticated_requests_are_keyed_by_user_not_ip(self):
        """Carrier NAT puts many real users on one address; keying by IP would
        let one of them exhaust everyone else's budget."""
        from app.core.security import create_access_token
        from app.middleware.rate_limiting import get_client_identifier

        token = create_access_token(subject="user-42")
        ident = get_client_identifier(
            self._request({"Authorization": f"Bearer {token}"})
        )
        assert ident == "user:user-42"

    def test_two_users_behind_one_ip_get_separate_buckets(self):
        from app.core.security import create_access_token
        from app.middleware.rate_limiting import get_client_identifier

        a = create_access_token(subject="user-a")
        b = create_access_token(subject="user-b")
        same_ip = "10.0.0.1"

        id_a = get_client_identifier(
            self._request({"Authorization": f"Bearer {a}"}, same_ip)
        )
        id_b = get_client_identifier(
            self._request({"Authorization": f"Bearer {b}"}, same_ip)
        )
        assert id_a != id_b

    def test_unauthenticated_requests_fall_back_to_ip(self):
        from app.middleware.rate_limiting import get_client_identifier

        assert get_client_identifier(self._request({}, "9.9.9.9")) == "ip:9.9.9.9"

    def test_garbage_token_does_not_crash_the_limiter(self):
        """An unreadable token is the auth layer's problem, not a reason to 500
        inside middleware."""
        from app.middleware.rate_limiting import get_client_identifier

        ident = get_client_identifier(
            self._request({"Authorization": "Bearer not-a-jwt"}, "9.9.9.9")
        )
        assert ident == "ip:9.9.9.9"

    def test_forwarded_for_wins_over_socket_peer(self):
        """Railway terminates TLS upstream, so request.client.host is the proxy."""
        from app.middleware.rate_limiting import get_client_identifier

        ident = get_client_identifier(
            self._request({"X-Forwarded-For": "203.0.113.9, 10.0.0.1"}, "10.0.0.1")
        )
        assert ident == "ip:203.0.113.9"


class TestEnvironmentDefault:
    def test_rate_limiting_is_on_outside_development(self, monkeypatch):
        from app.core.config import Settings

        monkeypatch.setenv("ENVIRONMENT", "production")
        monkeypatch.delenv("ENABLE_RATE_LIMITING", raising=False)
        assert Settings(_env_file=None).ENABLE_RATE_LIMITING is True

    def test_development_leaves_it_off(self, monkeypatch):
        from app.core.config import Settings

        monkeypatch.setenv("ENVIRONMENT", "development")
        monkeypatch.delenv("ENABLE_RATE_LIMITING", raising=False)
        assert Settings(_env_file=None).ENABLE_RATE_LIMITING is False

    def test_explicit_setting_always_wins(self, monkeypatch):
        from app.core.config import Settings

        monkeypatch.setenv("ENVIRONMENT", "production")
        monkeypatch.setenv("ENABLE_RATE_LIMITING", "false")
        assert Settings(_env_file=None).ENABLE_RATE_LIMITING is False


class TestReportedHeaders:
    """The X-RateLimit-* headers a client sees must describe the tier that will
    actually stop them next, not whichever tier the loop evaluated last."""

    def _limits(self, path, calls=1):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient

        from app.middleware import rate_limiting as module
        from app.middleware.rate_limiting import RateLimiter, rate_limit_middleware

        module.rate_limiter = RateLimiter()  # isolate from other tests
        app = FastAPI()
        app.middleware("http")(rate_limit_middleware)

        @app.post(path)
        @app.get(path)
        async def _handler():
            return {"ok": True}

        client = TestClient(app)
        for _ in range(calls):
            res = client.post(path) if path != "/api/v1/ping" else client.get(path)
        return res.headers

    def test_burst_tier_is_reported_not_the_daily_one(self):
        """Vision carries a 10/min burst and a 120/day cap. After one call the
        burst has 9 left and the daily 119, so the burst is what a well-behaved
        client needs to see."""
        headers = self._limits("/api/v1/vision/estimate-volume")
        assert headers["X-RateLimit-Limit"] == str(RateLimitConfig.VISION_LIMIT)
        assert headers["X-RateLimit-Window"] == str(RateLimitConfig.VISION_WINDOW)

    def test_single_tier_paths_report_that_tier(self):
        headers = self._limits("/api/v1/ping")
        assert headers["X-RateLimit-Limit"] == str(RateLimitConfig.GENERAL_LIMIT)
