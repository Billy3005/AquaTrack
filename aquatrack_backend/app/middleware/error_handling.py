#!/usr/bin/env python3
"""
Graceful Error Handling và Recovery Mechanisms cho AquaTrack Production
Global exception handling, circuit breakers, fallback strategies và recovery mechanisms
"""

import asyncio
import json
import time
import traceback
from collections import defaultdict, deque
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Union

import pydantic
from fastapi import HTTPException, Request, Response, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from ..middleware.logging import structured_logger


class CircuitBreakerState(Enum):
    """Circuit breaker states"""

    CLOSED = "closed"  # Normal operation
    OPEN = "open"  # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if service recovered


class ErrorSeverity(Enum):
    """Error severity levels"""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class CircuitBreaker:
    """
    Circuit breaker implementation for resilient external service calls
    """

    def __init__(
        self,
        name: str,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: type = Exception,
    ):
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception

        # State tracking
        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
        self.success_count = 0

        # Metrics
        self.total_calls = 0
        self.successful_calls = 0
        self.failed_calls = 0
        self.rejected_calls = 0

        # History for monitoring
        self.call_history = deque(maxlen=100)

    async def call(self, func: Callable, *args, **kwargs):
        """Execute function with circuit breaker protection"""
        self.total_calls += 1

        # Check if circuit is open
        if self.state == CircuitBreakerState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitBreakerState.HALF_OPEN
                structured_logger.log_application_event(
                    "circuit_breaker_half_open",
                    f"Circuit breaker '{self.name}' entering half-open state",
                )
            else:
                self.rejected_calls += 1
                self._record_call("rejected", None, "Circuit breaker open")
                raise CircuitBreakerOpenError(f"Circuit breaker '{self.name}' is open")

        # Attempt to call function
        start_time = time.time()
        try:
            if asyncio.iscoroutinefunction(func):
                result = await func(*args, **kwargs)
            else:
                result = func(*args, **kwargs)

            # Success
            self._on_success()
            duration = time.time() - start_time
            self._record_call("success", duration, None)

            return result

        except self.expected_exception as e:
            # Expected failure
            self._on_failure()
            duration = time.time() - start_time
            self._record_call("failure", duration, str(e))
            raise

        except Exception as e:
            # Unexpected failure
            self._on_failure()
            duration = time.time() - start_time
            self._record_call("error", duration, str(e))
            raise

    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if self.last_failure_time is None:
            return False
        return time.time() - self.last_failure_time >= self.recovery_timeout

    def _on_success(self):
        """Handle successful call"""
        self.successful_calls += 1

        if self.state == CircuitBreakerState.HALF_OPEN:
            # Reset circuit breaker
            self.state = CircuitBreakerState.CLOSED
            self.failure_count = 0
            self.success_count += 1

            structured_logger.log_application_event(
                "circuit_breaker_closed",
                f"Circuit breaker '{self.name}' reset to closed state",
            )
        else:
            self.success_count += 1

    def _on_failure(self):
        """Handle failed call"""
        self.failed_calls += 1
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            if self.state != CircuitBreakerState.OPEN:
                self.state = CircuitBreakerState.OPEN

                structured_logger.log_application_event(
                    "circuit_breaker_opened",
                    f"Circuit breaker '{self.name}' opened after {self.failure_count} failures",
                    level="warning",
                    context={
                        "failure_threshold": self.failure_threshold,
                        "failure_count": self.failure_count,
                    },
                )

    def _record_call(
        self, result_type: str, duration: Optional[float], error_msg: Optional[str]
    ):
        """Record call for monitoring"""
        self.call_history.append(
            {
                "timestamp": time.time(),
                "result": result_type,
                "duration": duration,
                "error": error_msg,
                "state": self.state.value,
            }
        )

    def get_stats(self) -> Dict[str, Any]:
        """Get circuit breaker statistics"""
        success_rate = (self.successful_calls / max(1, self.total_calls)) * 100

        return {
            "name": self.name,
            "state": self.state.value,
            "total_calls": self.total_calls,
            "successful_calls": self.successful_calls,
            "failed_calls": self.failed_calls,
            "rejected_calls": self.rejected_calls,
            "success_rate_percent": round(success_rate, 2),
            "failure_count": self.failure_count,
            "failure_threshold": self.failure_threshold,
            "last_failure_time": self.last_failure_time,
            "recovery_timeout": self.recovery_timeout,
        }


class CircuitBreakerOpenError(Exception):
    """Exception raised when circuit breaker is open"""

    pass


class ErrorHandler:
    """
    Comprehensive error handling and recovery system
    """

    def __init__(self):
        # Circuit breakers for external services
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}

        # Error tracking
        self.error_stats = {
            "total_errors": 0,
            "errors_by_type": defaultdict(int),
            "errors_by_endpoint": defaultdict(int),
            "recent_errors": deque(maxlen=100),
            "error_trends": defaultdict(lambda: deque(maxlen=50)),
        }

        # Recovery strategies
        self.recovery_strategies: Dict[str, Callable] = {}

        # Error thresholds for alerting
        self.alert_thresholds = {
            "error_rate_5min": 10,  # 10 errors in 5 minutes
            "consecutive_errors": 5,  # 5 consecutive errors
            "critical_error_count": 3,  # 3 critical errors
        }

        self.consecutive_error_count = 0
        self.last_success_time = time.time()

        # Register built-in recovery strategies
        self._register_builtin_strategies()

    def _register_builtin_strategies(self):
        """Register built-in recovery strategies"""
        self.register_recovery_strategy(
            "database_fallback", self._database_fallback_strategy
        )
        self.register_recovery_strategy(
            "ai_coach_fallback", self._ai_coach_fallback_strategy
        )
        self.register_recovery_strategy(
            "vision_fallback", self._vision_fallback_strategy
        )

    def register_circuit_breaker(
        self,
        name: str,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: type = Exception,
    ) -> CircuitBreaker:
        """Register circuit breaker for external service"""
        circuit_breaker = CircuitBreaker(
            name=name,
            failure_threshold=failure_threshold,
            recovery_timeout=recovery_timeout,
            expected_exception=expected_exception,
        )

        self.circuit_breakers[name] = circuit_breaker

        structured_logger.log_application_event(
            "circuit_breaker_registered",
            f"Circuit breaker '{name}' registered",
            context={
                "failure_threshold": failure_threshold,
                "recovery_timeout": recovery_timeout,
            },
        )

        return circuit_breaker

    def register_recovery_strategy(self, name: str, strategy_func: Callable):
        """Register recovery strategy"""
        self.recovery_strategies[name] = strategy_func
        structured_logger.log_application_event(
            "recovery_strategy_registered", f"Recovery strategy '{name}' registered"
        )

    async def handle_error(
        self, error: Exception, request: Request, context: Dict[str, Any] = None
    ) -> JSONResponse:
        """
        Handle error với comprehensive error processing
        """
        error_context = context or {}
        timestamp = time.time()

        # Classify error
        error_info = self._classify_error(error, request)

        # Record error
        self._record_error(error_info, request, timestamp)

        # Check if recovery strategy available
        recovery_response = await self._attempt_recovery(error, error_info, request)
        if recovery_response:
            return recovery_response

        # Generate appropriate error response
        return self._generate_error_response(error, error_info, request, timestamp)

    def _classify_error(self, error: Exception, request: Request) -> Dict[str, Any]:
        """Classify error type và severity"""
        error_type = type(error).__name__
        endpoint = f"{request.method} {request.url.path}"

        # Determine severity
        if isinstance(error, (ConnectionError, TimeoutError, CircuitBreakerOpenError)):
            severity = ErrorSeverity.CRITICAL
        elif isinstance(error, HTTPException) and error.status_code >= 500:
            severity = ErrorSeverity.HIGH
        elif isinstance(error, HTTPException) and error.status_code >= 400:
            severity = ErrorSeverity.MEDIUM
        elif isinstance(error, (RequestValidationError, pydantic.ValidationError)):
            severity = ErrorSeverity.LOW
        else:
            severity = ErrorSeverity.MEDIUM

        # Check if error is recoverable
        recoverable_types = {
            "ConnectionError",
            "TimeoutError",
            "HTTPException",
            "CircuitBreakerOpenError",
            "DatabaseError",
        }
        is_recoverable = error_type in recoverable_types

        return {
            "type": error_type,
            "severity": severity,
            "endpoint": endpoint,
            "is_recoverable": is_recoverable,
            "message": str(error),
            "traceback": traceback.format_exc(),
        }

    def _record_error(
        self, error_info: Dict[str, Any], request: Request, timestamp: float
    ):
        """Record error for tracking và analysis"""
        # Update statistics
        self.error_stats["total_errors"] += 1
        self.error_stats["errors_by_type"][error_info["type"]] += 1
        self.error_stats["errors_by_endpoint"][error_info["endpoint"]] += 1

        # Add to recent errors
        error_record = {
            "timestamp": timestamp,
            "type": error_info["type"],
            "severity": error_info["severity"].value,
            "endpoint": error_info["endpoint"],
            "message": error_info["message"],
            "user_id": getattr(request.state, "user_id", None),
            "request_id": getattr(request.state, "request_id", None),
            "client_ip": request.client.host if request.client else "unknown",
        }

        self.error_stats["recent_errors"].append(error_record)
        self.error_stats["error_trends"][error_info["type"]].append(timestamp)

        # Update consecutive error count
        current_time = time.time()
        if current_time - self.last_success_time > 60:  # No success in last minute
            self.consecutive_error_count += 1
        else:
            self.consecutive_error_count = 0

        # Check alert thresholds
        self._check_error_alerts(error_info, timestamp)

        # Log error
        structured_logger.log_application_event(
            "error_handled",
            f"Error handled: {error_info['type']} on {error_info['endpoint']}",
            level="error",
            context=error_record,
        )

    def _check_error_alerts(self, error_info: Dict[str, Any], timestamp: float):
        """Check if error alerts should be triggered"""
        five_minutes_ago = timestamp - 300

        # Check 5-minute error rate
        recent_errors = [
            e
            for e in self.error_stats["recent_errors"]
            if e["timestamp"] > five_minutes_ago
        ]
        if len(recent_errors) >= self.alert_thresholds["error_rate_5min"]:
            structured_logger.log_application_event(
                "high_error_rate_alert",
                f"High error rate: {len(recent_errors)} errors in 5 minutes",
                level="warning",
                context={"recent_error_count": len(recent_errors)},
            )

        # Check consecutive errors
        if self.consecutive_error_count >= self.alert_thresholds["consecutive_errors"]:
            structured_logger.log_application_event(
                "consecutive_errors_alert",
                f"Consecutive errors detected: {self.consecutive_error_count}",
                level="warning",
                context={"consecutive_count": self.consecutive_error_count},
            )

        # Check critical errors
        if error_info["severity"] == ErrorSeverity.CRITICAL:
            critical_errors = [
                e
                for e in recent_errors
                if e["severity"] == ErrorSeverity.CRITICAL.value
            ]
            if len(critical_errors) >= self.alert_thresholds["critical_error_count"]:
                structured_logger.log_application_event(
                    "critical_error_alert",
                    f"Multiple critical errors: {len(critical_errors)} in 5 minutes",
                    level="error",
                    context={"critical_error_count": len(critical_errors)},
                )

    async def _attempt_recovery(
        self, error: Exception, error_info: Dict[str, Any], request: Request
    ) -> Optional[JSONResponse]:
        """Attempt error recovery using available strategies"""
        if not error_info["is_recoverable"]:
            return None

        endpoint = error_info["endpoint"]

        # Try endpoint-specific recovery strategies
        recovery_strategy = None
        if "/coach/" in endpoint:
            recovery_strategy = "ai_coach_fallback"
        elif "/vision/" in endpoint:
            recovery_strategy = "vision_fallback"
        elif "/stats" in endpoint or "/analytics" in endpoint:
            recovery_strategy = "database_fallback"

        if recovery_strategy and recovery_strategy in self.recovery_strategies:
            try:
                structured_logger.log_application_event(
                    "recovery_attempt",
                    f"Attempting recovery strategy: {recovery_strategy}",
                    context={"error_type": error_info["type"], "endpoint": endpoint},
                )

                strategy_func = self.recovery_strategies[recovery_strategy]
                recovery_result = await strategy_func(error, request, error_info)

                if recovery_result:
                    structured_logger.log_application_event(
                        "recovery_successful",
                        f"Recovery strategy '{recovery_strategy}' succeeded",
                        context={
                            "error_type": error_info["type"],
                            "endpoint": endpoint,
                        },
                    )

                    # Record successful recovery
                    self.last_success_time = time.time()
                    self.consecutive_error_count = 0

                    return recovery_result

            except Exception as recovery_error:
                structured_logger.log_application_event(
                    "recovery_failed",
                    f"Recovery strategy '{recovery_strategy}' failed: {str(recovery_error)}",
                    level="error",
                    context={
                        "original_error": error_info["type"],
                        "recovery_error": str(recovery_error),
                    },
                )

        return None

    def _generate_error_response(
        self,
        error: Exception,
        error_info: Dict[str, Any],
        request: Request,
        timestamp: float,
    ) -> JSONResponse:
        """Generate appropriate error response"""
        request_id = getattr(request.state, "request_id", "unknown")

        # Base error response
        error_response = {
            "error": "An error occurred",
            "timestamp": datetime.fromtimestamp(timestamp).isoformat(),
            "request_id": request_id,
            "path": request.url.path,
        }

        # Handle specific error types
        if isinstance(error, HTTPException):
            status_code = error.status_code
            error_response["error"] = error.detail
            error_response["status_code"] = status_code

        elif isinstance(error, RequestValidationError):
            status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
            error_response["error"] = "Validation error"
            error_response["details"] = error.errors()

        elif isinstance(error, CircuitBreakerOpenError):
            status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            error_response["error"] = "Service temporarily unavailable"
            error_response["message"] = (
                "The requested service is experiencing issues. Please try again later."
            )
            error_response["retry_after"] = 60

        elif isinstance(error, (ConnectionError, TimeoutError)):
            status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            error_response["error"] = "Service unavailable"
            error_response["message"] = (
                "Unable to process request due to service connectivity issues"
            )

        else:
            # Generic server error
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
            error_response["error"] = "Internal server error"
            error_response["message"] = "An unexpected error occurred"

        # Add helpful information for client
        if status_code >= 500:
            error_response["support"] = {
                "contact": "Report this issue if it persists",
                "reference": request_id,
            }

        return JSONResponse(status_code=status_code, content=error_response)

    def get_error_statistics(self) -> Dict[str, Any]:
        """Get comprehensive error statistics"""
        current_time = time.time()
        five_minutes_ago = current_time - 300
        one_hour_ago = current_time - 3600

        # Recent error analysis
        recent_errors_5min = [
            e
            for e in self.error_stats["recent_errors"]
            if e["timestamp"] > five_minutes_ago
        ]
        recent_errors_1hr = [
            e
            for e in self.error_stats["recent_errors"]
            if e["timestamp"] > one_hour_ago
        ]

        # Error rate calculations
        error_rate_5min = len(recent_errors_5min)
        error_rate_1hr = len(recent_errors_1hr)

        # Circuit breaker stats
        circuit_breaker_stats = {}
        for name, cb in self.circuit_breakers.items():
            circuit_breaker_stats[name] = cb.get_stats()

        return {
            "overview": {
                "total_errors": self.error_stats["total_errors"],
                "error_rate_5min": error_rate_5min,
                "error_rate_1hr": error_rate_1hr,
                "consecutive_errors": self.consecutive_error_count,
                "last_success_time": self.last_success_time,
            },
            "error_breakdown": {
                "by_type": dict(self.error_stats["errors_by_type"]),
                "by_endpoint": dict(self.error_stats["errors_by_endpoint"]),
            },
            "recent_errors": list(self.error_stats["recent_errors"])[-10:],  # Last 10
            "circuit_breakers": circuit_breaker_stats,
            "alert_status": {
                "high_error_rate": error_rate_5min
                >= self.alert_thresholds["error_rate_5min"],
                "consecutive_errors": self.consecutive_error_count
                >= self.alert_thresholds["consecutive_errors"],
            },
        }

    # Built-in recovery strategies

    async def _database_fallback_strategy(
        self, error: Exception, request: Request, error_info: Dict[str, Any]
    ) -> Optional[JSONResponse]:
        """Fallback strategy for database-related endpoints"""
        endpoint = error_info["endpoint"]

        # Provide cached or default data
        fallback_data = {
            "status": "partial_data",
            "message": "Using cached data due to database issues",
            "data": {},
            "timestamp": time.time(),
            "source": "fallback",
        }

        if "/stats" in endpoint:
            fallback_data["data"] = {
                "total_volume_ml": 0,
                "goal_achievement_percentage": 0,
                "streak_days": 0,
                "note": "Live data temporarily unavailable",
            }

        return JSONResponse(status_code=200, content=fallback_data)

    async def _ai_coach_fallback_strategy(
        self, error: Exception, request: Request, error_info: Dict[str, Any]
    ) -> Optional[JSONResponse]:
        """Fallback strategy for AI coach endpoints"""
        # Provide rule-based fallback response
        fallback_response = {
            "response": "Xin chào! Tôi đang gặp sự cố nhỏ nhưng vẫn có thể giúp bạn. Hãy nhớ uống nước đều đặn nhé!",
            "coaching_type": "general",
            "motivation_level": "medium",
            "suggestions": ["Uống một ly nước nhỏ", "Đặt nhắc nhở 30 phút"],
            "action_items": [],
            "source": "fallback_rules",
            "timestamp": time.time(),
        }

        return JSONResponse(status_code=200, content=fallback_response)

    async def _vision_fallback_strategy(
        self, error: Exception, request: Request, error_info: Dict[str, Any]
    ) -> Optional[JSONResponse]:
        """Fallback strategy for vision endpoints"""
        # Provide manual input option
        fallback_response = {
            "status": "vision_unavailable",
            "message": "Smart scan temporarily unavailable. Please enter volume manually.",
            "fallback_options": [
                {"volume_ml": 250, "label": "Standard cup"},
                {"volume_ml": 500, "label": "Water bottle"},
                {"volume_ml": 750, "label": "Large bottle"},
            ],
            "timestamp": time.time(),
        }

        return JSONResponse(
            status_code=202,  # Accepted but needs manual input
            content=fallback_response,
        )


# Global error handler instance
error_handler = ErrorHandler()


# Global exception handlers for FastAPI


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Global exception handler"""
    return await error_handler.handle_error(exc, request)


async def http_exception_handler(
    request: Request, exc: StarletteHTTPException
) -> JSONResponse:
    """HTTP exception handler"""
    return await error_handler.handle_error(exc, request)


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Validation exception handler"""
    return await error_handler.handle_error(exc, request)


# Utility functions


def get_circuit_breaker(name: str) -> Optional[CircuitBreaker]:
    """Get circuit breaker by name"""
    return error_handler.circuit_breakers.get(name)


async def execute_with_circuit_breaker(
    circuit_breaker_name: str, func: Callable, *args, **kwargs
):
    """Execute function với circuit breaker protection"""
    circuit_breaker = error_handler.circuit_breakers.get(circuit_breaker_name)
    if not circuit_breaker:
        # No circuit breaker registered, execute directly
        if asyncio.iscoroutinefunction(func):
            return await func(*args, **kwargs)
        else:
            return func(*args, **kwargs)

    return await circuit_breaker.call(func, *args, **kwargs)


async def get_error_analytics():
    """Get error analytics cho admin dashboard"""
    try:
        stats = error_handler.get_error_statistics()
        return {"status": "success", "analytics": stats, "timestamp": time.time()}
    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}


# Register built-in circuit breakers
def initialize_circuit_breakers():
    """Initialize circuit breakers for external services"""
    # AI provider circuit breakers
    error_handler.register_circuit_breaker(
        "anthropic_api",
        failure_threshold=3,
        recovery_timeout=30,
        expected_exception=Exception,
    )

    error_handler.register_circuit_breaker(
        "openai_api",
        failure_threshold=3,
        recovery_timeout=30,
        expected_exception=Exception,
    )

    error_handler.register_circuit_breaker(
        "ollama_api",
        failure_threshold=5,
        recovery_timeout=60,
        expected_exception=Exception,
    )

    # Database circuit breaker
    error_handler.register_circuit_breaker(
        "database",
        failure_threshold=5,
        recovery_timeout=120,
        expected_exception=(ConnectionError, TimeoutError),
    )

    structured_logger.log_application_event(
        "circuit_breakers_initialized", "All circuit breakers initialized successfully"
    )
