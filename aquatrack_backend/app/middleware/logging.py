#!/usr/bin/env python3
"""
Enhanced Logging và Monitoring Middleware cho AquaTrack Production
Structured logging, performance monitoring, error tracking và analytics collection
"""

import time
import json
import uuid
import traceback
import asyncio
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List, Set
from collections import defaultdict, deque
from pathlib import Path

from fastapi import Request, Response
from fastapi.responses import JSONResponse
import logging
from logging.handlers import RotatingFileHandler


class StructuredLogger:
    """
    Production-ready structured logger với JSON format và filtering
    """

    def __init__(self, log_dir: str = "logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)

        # Setup loggers for different components
        self.setup_loggers()

        # Sensitive data patterns to filter
        self.sensitive_patterns = {
            "password", "token", "secret", "key", "authorization",
            "refresh_token", "access_token", "api_key"
        }

        # Performance metrics tracking
        self.metrics = {
            "request_count": 0,
            "error_count": 0,
            "slow_requests": deque(maxlen=100),  # Keep last 100 slow requests
            "endpoint_performance": defaultdict(lambda: {"count": 0, "total_time": 0, "errors": 0}),
            "hourly_stats": defaultdict(lambda: {"requests": 0, "errors": 0}),
            "user_activity": defaultdict(int)
        }

    def setup_loggers(self):
        """Setup structured loggers cho different log levels"""

        # Main application logger
        self.app_logger = self._create_logger(
            name="aquatrack.app",
            filename="app.log",
            level=logging.INFO
        )

        # Error logger với detailed context
        self.error_logger = self._create_logger(
            name="aquatrack.errors",
            filename="errors.log",
            level=logging.ERROR
        )

        # Performance logger
        self.perf_logger = self._create_logger(
            name="aquatrack.performance",
            filename="performance.log",
            level=logging.INFO
        )

        # Access logger cho request/response tracking
        self.access_logger = self._create_logger(
            name="aquatrack.access",
            filename="access.log",
            level=logging.INFO
        )

        # Security logger cho authentication/authorization events
        self.security_logger = self._create_logger(
            name="aquatrack.security",
            filename="security.log",
            level=logging.WARNING
        )

    def _create_logger(self, name: str, filename: str, level: int) -> logging.Logger:
        """Create logger với rotating file handler"""
        logger = logging.getLogger(name)
        logger.setLevel(level)

        # Prevent duplicate handlers
        if logger.handlers:
            return logger

        # Rotating file handler (10MB per file, keep 5 files)
        file_handler = RotatingFileHandler(
            self.log_dir / filename,
            maxBytes=10 * 1024 * 1024,  # 10MB
            backupCount=5,
            encoding='utf-8'
        )

        # JSON formatter
        formatter = JsonFormatter()
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        # Console handler for development
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        return logger

    def filter_sensitive_data(self, data: Dict) -> Dict:
        """Filter sensitive information from logs"""
        if not isinstance(data, dict):
            return data

        filtered = {}
        for key, value in data.items():
            if any(pattern in key.lower() for pattern in self.sensitive_patterns):
                filtered[key] = "[FILTERED]"
            elif isinstance(value, dict):
                filtered[key] = self.filter_sensitive_data(value)
            elif isinstance(value, list):
                filtered[key] = [
                    self.filter_sensitive_data(item) if isinstance(item, dict) else item
                    for item in value
                ]
            else:
                filtered[key] = value

        return filtered

    def log_request(self, request: Request, request_id: str, user_id: str = None):
        """Log incoming request với context"""
        try:
            # Basic request info
            log_data = {
                "event_type": "request_start",
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "method": request.method,
                "url": str(request.url),
                "path": request.url.path,
                "query_params": dict(request.query_params),
                "user_agent": request.headers.get("user-agent"),
                "client_ip": self._get_client_ip(request),
                "user_id": user_id
            }

            # Headers (filtered)
            headers = dict(request.headers)
            log_data["headers"] = self.filter_sensitive_data(headers)

            self.access_logger.info(json.dumps(log_data, ensure_ascii=False))

            # Update metrics
            self.metrics["request_count"] += 1
            hour_key = datetime.now().strftime("%Y-%m-%d-%H")
            self.metrics["hourly_stats"][hour_key]["requests"] += 1

            if user_id:
                self.metrics["user_activity"][user_id] += 1

        except Exception as e:
            self.error_logger.error(f"Failed to log request: {str(e)}")

    def log_response(
        self,
        request: Request,
        response: Response,
        request_id: str,
        duration_ms: float,
        user_id: str = None,
        error: Exception = None
    ):
        """Log response với performance metrics"""
        try:
            # Basic response info
            log_data = {
                "event_type": "request_complete",
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": round(duration_ms, 2),
                "user_id": user_id
            }

            # Add error info if present
            if error:
                log_data["error"] = {
                    "type": type(error).__name__,
                    "message": str(error),
                    "traceback": traceback.format_exc()
                }
                self.metrics["error_count"] += 1
                hour_key = datetime.now().strftime("%Y-%m-%d-%H")
                self.metrics["hourly_stats"][hour_key]["errors"] += 1

            # Performance classification
            if duration_ms > 5000:  # > 5 seconds
                log_data["performance"] = "very_slow"
                self.metrics["slow_requests"].append({
                    "path": request.url.path,
                    "duration_ms": duration_ms,
                    "timestamp": time.time()
                })
            elif duration_ms > 2000:  # > 2 seconds
                log_data["performance"] = "slow"
            elif duration_ms > 1000:  # > 1 second
                log_data["performance"] = "moderate"
            else:
                log_data["performance"] = "fast"

            # Update endpoint performance metrics
            endpoint_stats = self.metrics["endpoint_performance"][request.url.path]
            endpoint_stats["count"] += 1
            endpoint_stats["total_time"] += duration_ms
            if error or response.status_code >= 400:
                endpoint_stats["errors"] += 1

            # Log to appropriate logger
            if error or response.status_code >= 500:
                self.error_logger.error(json.dumps(log_data, ensure_ascii=False))
            elif response.status_code >= 400:
                self.app_logger.warning(json.dumps(log_data, ensure_ascii=False))
            else:
                self.access_logger.info(json.dumps(log_data, ensure_ascii=False))

            # Performance logging
            if duration_ms > 1000:  # Log slow requests
                self.perf_logger.warning(json.dumps(log_data, ensure_ascii=False))

        except Exception as e:
            self.error_logger.error(f"Failed to log response: {str(e)}")

    def log_security_event(
        self,
        event_type: str,
        request: Request,
        user_id: str = None,
        details: Dict = None
    ):
        """Log security-related events"""
        try:
            log_data = {
                "event_type": f"security_{event_type}",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "client_ip": self._get_client_ip(request),
                "user_agent": request.headers.get("user-agent"),
                "path": request.url.path,
                "user_id": user_id,
                "details": details or {}
            }

            self.security_logger.warning(json.dumps(log_data, ensure_ascii=False))

        except Exception as e:
            self.error_logger.error(f"Failed to log security event: {str(e)}")

    def log_application_event(
        self,
        event_type: str,
        message: str,
        user_id: str = None,
        context: Dict = None,
        level: str = "info"
    ):
        """Log application-specific events"""
        try:
            log_data = {
                "event_type": f"app_{event_type}",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "message": message,
                "user_id": user_id,
                "context": context or {}
            }

            log_message = json.dumps(log_data, ensure_ascii=False)

            if level == "error":
                self.error_logger.error(log_message)
            elif level == "warning":
                self.app_logger.warning(log_message)
            else:
                self.app_logger.info(log_message)

        except Exception as e:
            self.error_logger.error(f"Failed to log application event: {str(e)}")

    def get_metrics_summary(self) -> Dict:
        """Get performance metrics summary"""
        try:
            current_time = time.time()

            # Calculate endpoint performance averages
            endpoint_perf = {}
            for path, stats in self.metrics["endpoint_performance"].items():
                avg_time = stats["total_time"] / max(1, stats["count"])
                error_rate = (stats["errors"] / max(1, stats["count"])) * 100

                endpoint_perf[path] = {
                    "requests": stats["count"],
                    "avg_response_time_ms": round(avg_time, 2),
                    "error_rate_percent": round(error_rate, 2)
                }

            # Recent slow requests (last hour)
            hour_ago = current_time - 3600
            recent_slow = [
                req for req in self.metrics["slow_requests"]
                if req["timestamp"] > hour_ago
            ]

            # Active users (last hour)
            recent_hour = datetime.now().strftime("%Y-%m-%d-%H")
            current_stats = self.metrics["hourly_stats"][recent_hour]

            return {
                "overview": {
                    "total_requests": self.metrics["request_count"],
                    "total_errors": self.metrics["error_count"],
                    "error_rate_percent": round(
                        (self.metrics["error_count"] / max(1, self.metrics["request_count"])) * 100, 2
                    ),
                    "current_hour_requests": current_stats["requests"],
                    "current_hour_errors": current_stats["errors"],
                    "active_users": len(self.metrics["user_activity"]),
                    "slow_requests_1h": len(recent_slow)
                },
                "endpoint_performance": endpoint_perf,
                "recent_slow_requests": recent_slow[-10:],  # Last 10
                "hourly_breakdown": dict(list(self.metrics["hourly_stats"].items())[-24:])  # Last 24 hours
            }

        except Exception as e:
            return {"error": f"Failed to generate metrics: {str(e)}"}

    def _get_client_ip(self, request: Request) -> str:
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


class JsonFormatter(logging.Formatter):
    """Custom JSON formatter for structured logs"""

    def format(self, record):
        # Create log record
        log_record = {
            "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Add exception info if present
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)

        # Add extra fields
        for key, value in record.__dict__.items():
            if key not in ["name", "msg", "args", "levelname", "levelno", "pathname",
                          "filename", "module", "lineno", "funcName", "created", "msecs",
                          "relativeCreated", "thread", "threadName", "processName",
                          "process", "message", "exc_info", "exc_text", "stack_info"]:
                log_record[key] = value

        return json.dumps(log_record, ensure_ascii=False)


# Global logger instance
structured_logger = StructuredLogger()


async def logging_middleware(request: Request, call_next):
    """
    Enhanced logging middleware với comprehensive monitoring
    """
    # Generate unique request ID
    request_id = str(uuid.uuid4())
    start_time = time.time()

    # Add request ID to request state
    request.state.request_id = request_id

    # Extract user ID if available
    user_id = getattr(request.state, 'user_id', None)

    # Log request start
    structured_logger.log_request(request, request_id, user_id)

    try:
        # Process request
        response = await call_next(request)

        # Calculate duration
        duration_ms = (time.time() - start_time) * 1000

        # Log successful response
        structured_logger.log_response(
            request, response, request_id, duration_ms, user_id
        )

        # Add request ID to response headers
        response.headers["X-Request-ID"] = request_id

        return response

    except Exception as error:
        # Calculate duration for error case
        duration_ms = (time.time() - start_time) * 1000

        # Create error response
        error_response = JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "message": "An unexpected error occurred",
                "request_id": request_id,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        )

        # Log error response
        structured_logger.log_response(
            request, error_response, request_id, duration_ms, user_id, error
        )

        # Add request ID to error response
        error_response.headers["X-Request-ID"] = request_id

        return error_response


# Utility functions for application logging

def log_user_action(user_id: str, action: str, details: Dict = None):
    """Log user actions cho audit trail"""
    structured_logger.log_application_event(
        event_type="user_action",
        message=f"User {user_id} performed: {action}",
        user_id=user_id,
        context={"action": action, "details": details or {}}
    )


def log_ai_coach_interaction(user_id: str, message: str, response_type: str, duration_ms: float):
    """Log AI Coach interactions cho analytics"""
    structured_logger.log_application_event(
        event_type="ai_coach_interaction",
        message="AI Coach interaction",
        user_id=user_id,
        context={
            "message_length": len(message),
            "response_type": response_type,
            "processing_time_ms": duration_ms
        }
    )


def log_vision_scan(user_id: str, confidence: float, volume_ml: int, processing_ms: float):
    """Log Vision API usage cho monitoring"""
    structured_logger.log_application_event(
        event_type="vision_scan",
        message="Smart Scan completed",
        user_id=user_id,
        context={
            "confidence_score": confidence,
            "estimated_volume_ml": volume_ml,
            "processing_time_ms": processing_ms
        }
    )


def log_security_violation(request: Request, violation_type: str, details: Dict = None):
    """Log security violations"""
    structured_logger.log_security_event(
        event_type="violation",
        request=request,
        details={"violation_type": violation_type, **(details or {})}
    )