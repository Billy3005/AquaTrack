#!/usr/bin/env python3
"""
Security Middleware cho AquaTrack Production
Comprehensive security protection: input validation, XSS, injection prevention, security headers
"""

import hashlib
import json
import re
import secrets
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import unquote

from fastapi import HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from pydantic import ValidationError

from .logging import log_security_violation, structured_logger


class SecurityConfig:
    """Security configuration constants"""

    # Request size limits (bytes)
    MAX_REQUEST_SIZE = 50 * 1024 * 1024  # 50MB for image uploads
    MAX_JSON_SIZE = 1 * 1024 * 1024  # 1MB for JSON requests
    MAX_HEADER_SIZE = 8 * 1024  # 8KB for headers

    # Content type whitelist
    ALLOWED_CONTENT_TYPES = {
        "application/json",
        "application/x-www-form-urlencoded",
        "multipart/form-data",
        "image/jpeg",
        "image/png",
        "image/webp",
        "text/plain",
    }

    # Suspicious patterns for injection detection
    SQL_INJECTION_PATTERNS = [
        r"(\b(union|select|insert|update|delete|drop|create|alter|exec|execute)\b)",
        r"(;[\s]*drop|;[\s]*delete|;[\s]*update)",
        r"('[\s]*(or|and)[\s]*')",
        r"([\s]*(or|and)[\s]+\d+[\s]*=[\s]*\d+)",
        r"(\/\*.*?\*\/)",
        r"(--[\s].*)",
    ]

    # XSS patterns
    XSS_PATTERNS = [
        r"<script[^>]*>.*?</script>",
        r"javascript:",
        r"vbscript:",
        r"on\w+\s*=",
        r"<iframe[^>]*>",
        r"<object[^>]*>",
        r"<embed[^>]*>",
        r"<form[^>]*>",
    ]

    # Path traversal patterns
    PATH_TRAVERSAL_PATTERNS = [
        r"\.\.\/",
        r"\.\.\%2f",
        r"\.\.\%5c",
        r"%2e%2e%2f",
        r"%2e%2e%5c",
    ]


class SecurityValidator:
    """
    Comprehensive security validator với pattern detection và sanitization
    """

    def __init__(self):
        # Compile regex patterns for performance
        self.sql_patterns = [
            re.compile(pattern, re.IGNORECASE)
            for pattern in SecurityConfig.SQL_INJECTION_PATTERNS
        ]
        self.xss_patterns = [
            re.compile(pattern, re.IGNORECASE)
            for pattern in SecurityConfig.XSS_PATTERNS
        ]
        self.path_patterns = [
            re.compile(pattern, re.IGNORECASE)
            for pattern in SecurityConfig.PATH_TRAVERSAL_PATTERNS
        ]

        # Threat tracking
        self.threat_tracking = {
            "sql_injection_attempts": defaultdict(int),
            "xss_attempts": defaultdict(int),
            "path_traversal_attempts": defaultdict(int),
            "suspicious_ips": set(),
            "blocked_requests": deque(maxlen=1000),
        }

    def validate_request_size(self, request: Request, body: bytes = None) -> bool:
        """Validate request size limits"""
        try:
            # Check content length header
            content_length = request.headers.get("content-length")
            if content_length:
                size = int(content_length)
                if size > SecurityConfig.MAX_REQUEST_SIZE:
                    return False

            # Check actual body size if provided
            if body and len(body) > SecurityConfig.MAX_REQUEST_SIZE:
                return False

            return True
        except (ValueError, TypeError):
            return False

    def validate_content_type(self, request: Request) -> bool:
        """Validate content type"""
        content_type = (
            request.headers.get("content-type", "").split(";")[0].strip().lower()
        )

        # Skip validation for GET requests
        if request.method == "GET":
            return True

        # Allow empty content type for some methods
        if not content_type and request.method in ["DELETE", "HEAD", "OPTIONS"]:
            return True

        return content_type in SecurityConfig.ALLOWED_CONTENT_TYPES

    def detect_sql_injection(self, text: str, client_ip: str) -> bool:
        """Detect SQL injection attempts"""
        if not isinstance(text, str):
            return False

        decoded_text = unquote(text).lower()

        for pattern in self.sql_patterns:
            if pattern.search(decoded_text):
                self.threat_tracking["sql_injection_attempts"][client_ip] += 1
                return True

        return False

    def detect_xss(self, text: str, client_ip: str) -> bool:
        """Detect XSS attempts"""
        if not isinstance(text, str):
            return False

        decoded_text = unquote(text)

        for pattern in self.xss_patterns:
            if pattern.search(decoded_text):
                self.threat_tracking["xss_attempts"][client_ip] += 1
                return True

        return False

    def detect_path_traversal(self, text: str, client_ip: str) -> bool:
        """Detect path traversal attempts"""
        if not isinstance(text, str):
            return False

        decoded_text = unquote(text).lower()

        for pattern in self.path_patterns:
            if pattern.search(decoded_text):
                self.threat_tracking["path_traversal_attempts"][client_ip] += 1
                return True

        return False

    def sanitize_string(self, text: str) -> str:
        """Sanitize potentially dangerous strings"""
        if not isinstance(text, str):
            return str(text)

        # HTML entity encoding for basic XSS prevention
        replacements = {
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#x27;",
            "&": "&amp;",
        }

        sanitized = text
        for char, replacement in replacements.items():
            sanitized = sanitized.replace(char, replacement)

        return sanitized

    def validate_input_data(self, data: Any, client_ip: str) -> Tuple[bool, str]:
        """
        Comprehensive input validation
        Returns: (is_valid, violation_type)
        """
        try:
            if isinstance(data, str):
                if self.detect_sql_injection(data, client_ip):
                    return False, "sql_injection"
                if self.detect_xss(data, client_ip):
                    return False, "xss"
                if self.detect_path_traversal(data, client_ip):
                    return False, "path_traversal"

            elif isinstance(data, dict):
                for key, value in data.items():
                    is_valid, violation = self.validate_input_data(value, client_ip)
                    if not is_valid:
                        return False, violation

            elif isinstance(data, list):
                for item in data:
                    is_valid, violation = self.validate_input_data(item, client_ip)
                    if not is_valid:
                        return False, violation

            return True, ""

        except Exception as e:
            structured_logger.log_application_event(
                "security_validation_error",
                f"Input validation error: {str(e)}",
                level="error",
            )
            return False, "validation_error"

    def is_suspicious_ip(self, client_ip: str) -> bool:
        """Check if IP has suspicious activity"""
        total_attempts = (
            self.threat_tracking["sql_injection_attempts"][client_ip]
            + self.threat_tracking["xss_attempts"][client_ip]
            + self.threat_tracking["path_traversal_attempts"][client_ip]
        )

        # Mark as suspicious if > 5 attack attempts
        if total_attempts > 5:
            self.threat_tracking["suspicious_ips"].add(client_ip)
            return True

        return client_ip in self.threat_tracking["suspicious_ips"]

    def record_blocked_request(
        self, request: Request, violation_type: str, client_ip: str
    ):
        """Record blocked request for analysis"""
        blocked_info = {
            "timestamp": time.time(),
            "client_ip": client_ip,
            "method": request.method,
            "path": request.url.path,
            "violation_type": violation_type,
            "user_agent": request.headers.get("user-agent", "unknown"),
        }

        self.threat_tracking["blocked_requests"].append(blocked_info)

    def get_security_stats(self) -> Dict:
        """Get security monitoring statistics"""
        current_time = time.time()
        hour_ago = current_time - 3600

        # Recent blocked requests
        recent_blocks = [
            req
            for req in self.threat_tracking["blocked_requests"]
            if req["timestamp"] > hour_ago
        ]

        # Top attacking IPs
        attack_counts = defaultdict(int)
        for ip, count in self.threat_tracking["sql_injection_attempts"].items():
            attack_counts[ip] += count
        for ip, count in self.threat_tracking["xss_attempts"].items():
            attack_counts[ip] += count
        for ip, count in self.threat_tracking["path_traversal_attempts"].items():
            attack_counts[ip] += count

        top_attackers = sorted(attack_counts.items(), key=lambda x: x[1], reverse=True)[
            :10
        ]

        return {
            "overview": {
                "total_sql_attempts": sum(
                    self.threat_tracking["sql_injection_attempts"].values()
                ),
                "total_xss_attempts": sum(
                    self.threat_tracking["xss_attempts"].values()
                ),
                "total_path_traversal": sum(
                    self.threat_tracking["path_traversal_attempts"].values()
                ),
                "suspicious_ips": len(self.threat_tracking["suspicious_ips"]),
                "blocks_last_hour": len(recent_blocks),
            },
            "recent_blocks": recent_blocks[-20:],  # Last 20
            "top_attackers": top_attackers,
            "attack_types": {
                "sql_injection": dict(self.threat_tracking["sql_injection_attempts"]),
                "xss": dict(self.threat_tracking["xss_attempts"]),
                "path_traversal": dict(self.threat_tracking["path_traversal_attempts"]),
            },
        }


class SecurityHeaders:
    """Utility for adding security headers"""

    @staticmethod
    def add_security_headers(response: Response):
        """Add comprehensive security headers"""
        headers = {
            # CORS security
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            # Content Security Policy
            "Content-Security-Policy": (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "font-src 'self' data:; "
                "connect-src 'self' https:; "
                "frame-ancestors 'none'"
            ),
            # HSTS (HTTP Strict Transport Security)
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            # Hide server information
            "Server": "AquaTrack-API",
            # Referrer Policy
            "Referrer-Policy": "strict-origin-when-cross-origin",
            # Feature Policy / Permissions Policy
            "Permissions-Policy": (
                "geolocation=(), camera=(), microphone=(), "
                "payment=(), usb=(), magnetometer=(), gyroscope=()"
            ),
            # Cache control for sensitive endpoints
            "Cache-Control": "no-store, no-cache, must-revalidate, private",
        }

        for header_name, header_value in headers.items():
            response.headers[header_name] = header_value


# Global security validator
security_validator = SecurityValidator()


async def security_middleware(request: Request, call_next):
    """
    Comprehensive security middleware cho production
    """
    start_time = time.time()
    client_ip = _get_client_ip(request)

    try:
        # Skip security for health check endpoints
        if request.url.path in ["/health", "/docs", "/openapi.json"]:
            return await call_next(request)

        # 1. Check if IP is marked as suspicious
        if security_validator.is_suspicious_ip(client_ip):
            log_security_violation(
                request,
                "suspicious_ip_blocked",
                {"client_ip": client_ip, "reason": "repeated_violations"},
            )

            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={
                    "error": "Access denied",
                    "message": "Your IP has been flagged for suspicious activity",
                    "timestamp": datetime.utcnow().isoformat(),
                },
            )

        # 2. Validate content type
        if not security_validator.validate_content_type(request):
            log_security_violation(
                request,
                "invalid_content_type",
                {"content_type": request.headers.get("content-type")},
            )

            return JSONResponse(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                content={"error": "Unsupported content type"},
            )

        # 3. Read and validate request body if present
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()

                # Validate request size
                if not security_validator.validate_request_size(request, body):
                    log_security_violation(
                        request, "request_too_large", {"size": len(body) if body else 0}
                    )

                    return JSONResponse(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        content={"error": "Request too large"},
                    )

                # Validate JSON body for injection attacks
                if (
                    body
                    and "application/json"
                    in request.headers.get("content-type", "").lower()
                ):
                    try:
                        json_data = json.loads(body)
                        is_valid, violation_type = (
                            security_validator.validate_input_data(json_data, client_ip)
                        )

                        if not is_valid:
                            security_validator.record_blocked_request(
                                request, violation_type, client_ip
                            )
                            log_security_violation(
                                request,
                                f"input_validation_failed_{violation_type}",
                                {"violation_type": violation_type},
                            )

                            return JSONResponse(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                content={
                                    "error": "Invalid input data",
                                    "message": "Request contains potentially dangerous content",
                                },
                            )

                    except json.JSONDecodeError:
                        # Invalid JSON - let the application handle this
                        pass

            except Exception as e:
                structured_logger.log_application_event(
                    "security_middleware_error",
                    f"Error processing request body: {str(e)}",
                    level="error",
                )

        # 4. Validate URL path and query parameters
        full_url = str(request.url)
        is_valid, violation_type = security_validator.validate_input_data(
            full_url, client_ip
        )

        if not is_valid:
            security_validator.record_blocked_request(
                request, violation_type, client_ip
            )
            log_security_violation(
                request,
                f"url_validation_failed_{violation_type}",
                {"violation_type": violation_type, "url": request.url.path},
            )

            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={
                    "error": "Invalid request",
                    "message": "URL contains potentially dangerous content",
                },
            )

        # 5. Process request
        response = await call_next(request)

        # 6. Add security headers to response
        SecurityHeaders.add_security_headers(response)

        # 7. Add security timing header
        security_duration = round((time.time() - start_time) * 1000, 2)
        response.headers["X-Security-Check-Duration"] = f"{security_duration}ms"

        return response

    except Exception as e:
        # Log security middleware errors
        structured_logger.log_application_event(
            "security_middleware_critical_error",
            f"Critical security middleware error: {str(e)}",
            context={"client_ip": client_ip, "path": request.url.path},
            level="error",
        )

        # Fail secure - return error response
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Security check failed",
                "message": "Unable to validate request security",
            },
        )


def _get_client_ip(request: Request) -> str:
    """Get real client IP considering proxies"""
    # Check for forwarded headers
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()

    real_ip = request.headers.get("x-real-ip")
    if real_ip:
        return real_ip

    # Fallback to direct client IP
    return request.client.host if request.client else "unknown"


# Utility functions for application-level security


def validate_user_input(data: Any, client_ip: str = "unknown") -> Tuple[bool, str]:
    """
    Validate user input data in application code
    Returns: (is_valid, violation_type)
    """
    return security_validator.validate_input_data(data, client_ip)


def sanitize_user_input(data: str) -> str:
    """Sanitize user input string"""
    return security_validator.sanitize_string(data)


async def get_security_analytics():
    """Get security analytics cho admin dashboard"""
    try:
        stats = security_validator.get_security_stats()
        return {"status": "success", "analytics": stats, "timestamp": time.time()}
    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}


async def manage_security_ip(ip: str, action: str, reason: str = "admin action"):
    """
    Manage IP security status
    Actions: block, unblock, get_status
    """
    try:
        if action == "block":
            security_validator.threat_tracking["suspicious_ips"].add(ip)
            result = {"message": f"IP {ip} blocked"}

        elif action == "unblock":
            security_validator.threat_tracking["suspicious_ips"].discard(ip)
            # Reset attack counters
            security_validator.threat_tracking["sql_injection_attempts"][ip] = 0
            security_validator.threat_tracking["xss_attempts"][ip] = 0
            security_validator.threat_tracking["path_traversal_attempts"][ip] = 0
            result = {"message": f"IP {ip} unblocked and reset"}

        elif action == "get_status":
            is_suspicious = security_validator.is_suspicious_ip(ip)
            attacks = (
                security_validator.threat_tracking["sql_injection_attempts"][ip]
                + security_validator.threat_tracking["xss_attempts"][ip]
                + security_validator.threat_tracking["path_traversal_attempts"][ip]
            )
            result = {
                "ip": ip,
                "is_blocked": is_suspicious,
                "total_attacks": attacks,
                "sql_attempts": security_validator.threat_tracking[
                    "sql_injection_attempts"
                ][ip],
                "xss_attempts": security_validator.threat_tracking["xss_attempts"][ip],
                "traversal_attempts": security_validator.threat_tracking[
                    "path_traversal_attempts"
                ][ip],
            }

        else:
            return {"status": "error", "error": f"Unknown action: {action}"}

        result["status"] = "success"
        result["action"] = action
        result["timestamp"] = time.time()
        return result

    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}
