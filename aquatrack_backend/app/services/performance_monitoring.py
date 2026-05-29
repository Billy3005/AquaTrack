#!/usr/bin/env python3
"""
Performance Monitoring và Metrics Collection cho AquaTrack Production
Real-time performance tracking, health checks, resource monitoring và analytics
"""

import asyncio
import gc
import json
import os
import threading
import time
from collections import defaultdict, deque
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import psutil
from fastapi import Request, Response
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..core.database import SessionLocal
from ..middleware.logging import structured_logger


@dataclass
class PerformanceMetric:
    """Individual performance metric data point"""

    timestamp: float
    value: float
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class HealthCheckResult:
    """Health check result"""

    service: str
    status: str  # "healthy", "degraded", "unhealthy"
    response_time_ms: float
    message: str
    timestamp: float
    metadata: Dict[str, Any] = field(default_factory=dict)


class PerformanceMonitor:
    """
    Comprehensive performance monitoring system
    """

    def __init__(self):
        # Metrics storage (in-memory với size limits)
        self.metrics = {
            "response_times": defaultdict(lambda: deque(maxlen=1000)),  # Per endpoint
            "request_counts": defaultdict(lambda: deque(maxlen=1000)),  # Per endpoint
            "error_rates": defaultdict(lambda: deque(maxlen=1000)),  # Per endpoint
            "database_queries": deque(maxlen=500),
            "memory_usage": deque(maxlen=300),  # 5 minutes at 1s intervals
            "cpu_usage": deque(maxlen=300),
            "disk_usage": deque(maxlen=60),  # 5 minutes at 5s intervals
            "active_connections": deque(maxlen=1000),
        }

        # Health check registry
        self.health_checks: Dict[str, callable] = {}
        self.last_health_results: Dict[str, HealthCheckResult] = {}

        # Performance alerts
        self.alert_thresholds = {
            "response_time_ms": 5000,  # 5 seconds
            "error_rate_percent": 10,  # 10%
            "memory_usage_percent": 85,  # 85%
            "cpu_usage_percent": 80,  # 80%
            "disk_usage_percent": 90,  # 90%
            "database_connections": 50,  # 50 connections
        }

        self.active_alerts = {}
        self.alert_history = deque(maxlen=100)

        # Background monitoring task
        self.monitoring_task: Optional[asyncio.Task] = None
        self.is_monitoring = False

        # Performance summaries cache
        self.summary_cache = {}
        self.cache_ttl = 60  # 60 seconds

        # Register built-in health checks
        self._register_builtin_health_checks()

    def _register_builtin_health_checks(self):
        """Register built-in health checks"""
        self.register_health_check("database", self._check_database_health)
        self.register_health_check("memory", self._check_memory_health)
        self.register_health_check("disk", self._check_disk_health)
        self.register_health_check("cpu", self._check_cpu_health)

    def register_health_check(self, name: str, check_func: callable):
        """Register custom health check"""
        self.health_checks[name] = check_func
        structured_logger.log_application_event(
            "health_check_registered", f"Health check '{name}' registered"
        )

    async def start_monitoring(self):
        """Start background performance monitoring"""
        if self.is_monitoring:
            return

        self.is_monitoring = True
        self.monitoring_task = asyncio.create_task(self._monitoring_loop())

        structured_logger.log_application_event(
            "performance_monitoring_started", "Performance monitoring started"
        )

    async def stop_monitoring(self):
        """Stop background monitoring"""
        if not self.is_monitoring:
            return

        self.is_monitoring = False
        if self.monitoring_task:
            self.monitoring_task.cancel()
            try:
                await self.monitoring_task
            except asyncio.CancelledError:
                pass

        structured_logger.log_application_event(
            "performance_monitoring_stopped", "Performance monitoring stopped"
        )

    def record_request_metrics(
        self, request: Request, response: Response, duration_ms: float
    ):
        """Record metrics for HTTP request"""
        endpoint = f"{request.method} {request.url.path}"
        timestamp = time.time()

        # Record response time
        self.metrics["response_times"][endpoint].append(
            PerformanceMetric(
                timestamp, duration_ms, {"status_code": response.status_code}
            )
        )

        # Record request count
        self.metrics["request_counts"][endpoint].append(
            PerformanceMetric(timestamp, 1, {"status_code": response.status_code})
        )

        # Record error if applicable
        if response.status_code >= 400:
            self.metrics["error_rates"][endpoint].append(
                PerformanceMetric(timestamp, 1, {"status_code": response.status_code})
            )

        # Check alerts
        self._check_performance_alerts(endpoint, duration_ms, response.status_code)

    def record_database_query(self, query_time_ms: float, query_type: str = "unknown"):
        """Record database query performance"""
        timestamp = time.time()
        self.metrics["database_queries"].append(
            PerformanceMetric(timestamp, query_time_ms, {"query_type": query_type})
        )

    async def get_health_status(self) -> Dict[str, Any]:
        """Get comprehensive system health status"""
        health_results = {}
        overall_status = "healthy"

        # Run all health checks
        for name, check_func in self.health_checks.items():
            try:
                start_time = time.time()

                if asyncio.iscoroutinefunction(check_func):
                    result = await check_func()
                else:
                    result = check_func()

                response_time_ms = (time.time() - start_time) * 1000

                if isinstance(result, HealthCheckResult):
                    health_result = result
                else:
                    # Convert simple result to HealthCheckResult
                    status = "healthy" if result else "unhealthy"
                    health_result = HealthCheckResult(
                        service=name,
                        status=status,
                        response_time_ms=response_time_ms,
                        message="OK" if result else "Check failed",
                        timestamp=time.time(),
                    )

                health_results[name] = health_result
                self.last_health_results[name] = health_result

                # Determine overall status
                if health_result.status == "unhealthy":
                    overall_status = "unhealthy"
                elif health_result.status == "degraded" and overall_status == "healthy":
                    overall_status = "degraded"

            except Exception as e:
                error_result = HealthCheckResult(
                    service=name,
                    status="unhealthy",
                    response_time_ms=0,
                    message=f"Health check failed: {str(e)}",
                    timestamp=time.time(),
                )
                health_results[name] = error_result
                self.last_health_results[name] = error_result
                overall_status = "unhealthy"

        return {
            "overall_status": overall_status,
            "timestamp": time.time(),
            "checks": {
                name: result.__dict__ for name, result in health_results.items()
            },
            "summary": {
                "total_checks": len(health_results),
                "healthy": sum(
                    1 for r in health_results.values() if r.status == "healthy"
                ),
                "degraded": sum(
                    1 for r in health_results.values() if r.status == "degraded"
                ),
                "unhealthy": sum(
                    1 for r in health_results.values() if r.status == "unhealthy"
                ),
            },
        }

    def get_performance_summary(self, cache_ttl: int = None) -> Dict[str, Any]:
        """Get performance metrics summary với caching"""
        cache_key = "performance_summary"
        current_time = time.time()

        # Check cache
        if cache_key in self.summary_cache:
            cached_data, cache_time = self.summary_cache[cache_key]
            ttl = cache_ttl or self.cache_ttl

            if current_time - cache_time < ttl:
                return cached_data

        # Generate fresh summary
        summary = self._generate_performance_summary()

        # Cache result
        self.summary_cache[cache_key] = (summary, current_time)

        return summary

    def _generate_performance_summary(self) -> Dict[str, Any]:
        """Generate comprehensive performance summary"""
        current_time = time.time()
        one_hour_ago = current_time - 3600
        five_minutes_ago = current_time - 300

        # Endpoint performance analysis
        endpoint_stats = {}
        for endpoint, metrics in self.metrics["response_times"].items():
            recent_metrics = [m for m in metrics if m.timestamp > one_hour_ago]
            if not recent_metrics:
                continue

            response_times = [m.value for m in recent_metrics]
            avg_response_time = sum(response_times) / len(response_times)
            max_response_time = max(response_times)
            min_response_time = min(response_times)

            # Calculate percentiles
            sorted_times = sorted(response_times)
            p95_idx = int(len(sorted_times) * 0.95)
            p99_idx = int(len(sorted_times) * 0.99)

            endpoint_stats[endpoint] = {
                "request_count": len(recent_metrics),
                "avg_response_time_ms": round(avg_response_time, 2),
                "max_response_time_ms": round(max_response_time, 2),
                "min_response_time_ms": round(min_response_time, 2),
                "p95_response_time_ms": round(
                    sorted_times[p95_idx] if sorted_times else 0, 2
                ),
                "p99_response_time_ms": round(
                    sorted_times[p99_idx] if sorted_times else 0, 2
                ),
            }

        # System resource summary
        system_summary = self._get_current_system_metrics()

        # Error analysis
        error_summary = self._analyze_errors(one_hour_ago)

        # Database performance
        db_summary = self._analyze_database_performance(one_hour_ago)

        return {
            "timestamp": current_time,
            "time_range": "1_hour",
            "system": system_summary,
            "endpoints": endpoint_stats,
            "errors": error_summary,
            "database": db_summary,
            "alerts": {
                "active": len(self.active_alerts),
                "recent": list(self.alert_history)[-5:],  # Last 5 alerts
            },
        }

    def _get_current_system_metrics(self) -> Dict[str, Any]:
        """Get current system resource metrics"""
        try:
            # Memory usage
            memory = psutil.virtual_memory()
            memory_used_percent = memory.percent

            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=0.1)

            # Disk usage
            disk = psutil.disk_usage("/")
            disk_used_percent = (disk.used / disk.total) * 100

            # Network connections (approximation for active connections)
            connections = psutil.net_connections()
            active_connections = len(
                [c for c in connections if c.status == "ESTABLISHED"]
            )

            return {
                "memory": {
                    "used_percent": round(memory_used_percent, 2),
                    "used_mb": round(memory.used / 1024 / 1024, 2),
                    "total_mb": round(memory.total / 1024 / 1024, 2),
                },
                "cpu": {
                    "usage_percent": round(cpu_percent, 2),
                    "core_count": psutil.cpu_count(),
                },
                "disk": {
                    "used_percent": round(disk_used_percent, 2),
                    "used_gb": round(disk.used / 1024 / 1024 / 1024, 2),
                    "total_gb": round(disk.total / 1024 / 1024 / 1024, 2),
                },
                "connections": {
                    "active": active_connections,
                    "total": len(connections),
                },
            }
        except Exception as e:
            structured_logger.log_application_event(
                "system_metrics_error",
                f"Failed to get system metrics: {str(e)}",
                level="error",
            )
            return {"error": f"Failed to get system metrics: {str(e)}"}

    def _analyze_errors(self, since_timestamp: float) -> Dict[str, Any]:
        """Analyze error patterns"""
        total_errors = 0
        total_requests = 0
        error_by_endpoint = defaultdict(int)
        error_by_status = defaultdict(int)

        for endpoint, error_metrics in self.metrics["error_rates"].items():
            recent_errors = [m for m in error_metrics if m.timestamp > since_timestamp]
            total_errors += len(recent_errors)

            for error in recent_errors:
                error_by_endpoint[endpoint] += 1
                status_code = error.metadata.get("status_code", "unknown")
                error_by_status[str(status_code)] += 1

        # Count total requests for error rate calculation
        for endpoint, request_metrics in self.metrics["request_counts"].items():
            recent_requests = [
                m for m in request_metrics if m.timestamp > since_timestamp
            ]
            total_requests += len(recent_requests)

        error_rate = (total_errors / max(1, total_requests)) * 100

        return {
            "total_errors": total_errors,
            "total_requests": total_requests,
            "error_rate_percent": round(error_rate, 2),
            "errors_by_endpoint": dict(
                sorted(error_by_endpoint.items(), key=lambda x: x[1], reverse=True)[:10]
            ),
            "errors_by_status_code": dict(error_by_status),
        }

    def _analyze_database_performance(self, since_timestamp: float) -> Dict[str, Any]:
        """Analyze database query performance"""
        recent_queries = [
            q for q in self.metrics["database_queries"] if q.timestamp > since_timestamp
        ]

        if not recent_queries:
            return {
                "query_count": 0,
                "avg_query_time_ms": 0,
                "max_query_time_ms": 0,
                "slow_queries": 0,
            }

        query_times = [q.value for q in recent_queries]
        avg_time = sum(query_times) / len(query_times)
        max_time = max(query_times)
        slow_queries = sum(1 for t in query_times if t > 1000)  # > 1 second

        return {
            "query_count": len(recent_queries),
            "avg_query_time_ms": round(avg_time, 2),
            "max_query_time_ms": round(max_time, 2),
            "slow_queries": slow_queries,
            "slow_query_rate_percent": round(
                (slow_queries / len(recent_queries)) * 100, 2
            ),
        }

    def _check_performance_alerts(
        self, endpoint: str, response_time_ms: float, status_code: int
    ):
        """Check and trigger performance alerts"""
        current_time = time.time()

        # Response time alert
        if response_time_ms > self.alert_thresholds["response_time_ms"]:
            alert_key = f"slow_response_{endpoint}"
            if (
                alert_key not in self.active_alerts
                or current_time - self.active_alerts[alert_key] > 300
            ):
                self._trigger_alert(
                    alert_key,
                    f"Slow response on {endpoint}: {response_time_ms:.2f}ms",
                    {"endpoint": endpoint, "response_time_ms": response_time_ms},
                )

        # Error rate alerts (calculated over last 10 requests)
        if status_code >= 400:
            recent_requests = list(self.metrics["request_counts"][endpoint])[-10:]
            recent_errors = [
                m for m in recent_requests if m.metadata.get("status_code", 200) >= 400
            ]

            if len(recent_requests) >= 5:  # Only alert if we have enough data
                error_rate = (len(recent_errors) / len(recent_requests)) * 100
                if error_rate > self.alert_thresholds["error_rate_percent"]:
                    alert_key = f"high_error_rate_{endpoint}"
                    if (
                        alert_key not in self.active_alerts
                        or current_time - self.active_alerts[alert_key] > 300
                    ):
                        self._trigger_alert(
                            alert_key,
                            f"High error rate on {endpoint}: {error_rate:.1f}%",
                            {"endpoint": endpoint, "error_rate": error_rate},
                        )

    def _trigger_alert(self, alert_key: str, message: str, metadata: Dict[str, Any]):
        """Trigger performance alert"""
        current_time = time.time()
        self.active_alerts[alert_key] = current_time

        alert_info = {
            "alert_key": alert_key,
            "message": message,
            "metadata": metadata,
            "timestamp": current_time,
        }

        self.alert_history.append(alert_info)

        structured_logger.log_application_event(
            "performance_alert", message, level="warning", context=metadata
        )

    async def _monitoring_loop(self):
        """Background monitoring loop"""
        while self.is_monitoring:
            try:
                # Collect system metrics
                system_metrics = self._get_current_system_metrics()
                timestamp = time.time()

                # Store metrics
                if "memory" in system_metrics:
                    self.metrics["memory_usage"].append(
                        PerformanceMetric(
                            timestamp, system_metrics["memory"]["used_percent"]
                        )
                    )

                if "cpu" in system_metrics:
                    self.metrics["cpu_usage"].append(
                        PerformanceMetric(
                            timestamp, system_metrics["cpu"]["usage_percent"]
                        )
                    )

                # Check system alerts
                self._check_system_alerts(system_metrics)

                # Sleep for monitoring interval
                await asyncio.sleep(5)

            except asyncio.CancelledError:
                break
            except Exception as e:
                structured_logger.log_application_event(
                    "monitoring_loop_error",
                    f"Monitoring loop error: {str(e)}",
                    level="error",
                )
                await asyncio.sleep(10)  # Wait longer on error

    def _check_system_alerts(self, system_metrics: Dict[str, Any]):
        """Check system resource alerts"""
        current_time = time.time()

        # Memory usage alert
        if "memory" in system_metrics:
            memory_percent = system_metrics["memory"]["used_percent"]
            if memory_percent > self.alert_thresholds["memory_usage_percent"]:
                alert_key = "high_memory_usage"
                if (
                    alert_key not in self.active_alerts
                    or current_time - self.active_alerts[alert_key] > 600
                ):
                    self._trigger_alert(
                        alert_key,
                        f"High memory usage: {memory_percent:.1f}%",
                        {"memory_usage_percent": memory_percent},
                    )

        # CPU usage alert
        if "cpu" in system_metrics:
            cpu_percent = system_metrics["cpu"]["usage_percent"]
            if cpu_percent > self.alert_thresholds["cpu_usage_percent"]:
                alert_key = "high_cpu_usage"
                if (
                    alert_key not in self.active_alerts
                    or current_time - self.active_alerts[alert_key] > 600
                ):
                    self._trigger_alert(
                        alert_key,
                        f"High CPU usage: {cpu_percent:.1f}%",
                        {"cpu_usage_percent": cpu_percent},
                    )

        # Disk usage alert
        if "disk" in system_metrics:
            disk_percent = system_metrics["disk"]["used_percent"]
            if disk_percent > self.alert_thresholds["disk_usage_percent"]:
                alert_key = "high_disk_usage"
                if (
                    alert_key not in self.active_alerts
                    or current_time - self.active_alerts[alert_key] > 1800
                ):
                    self._trigger_alert(
                        alert_key,
                        f"High disk usage: {disk_percent:.1f}%",
                        {"disk_usage_percent": disk_percent},
                    )

    # Built-in health checks

    async def _check_database_health(self) -> HealthCheckResult:
        """Check database connectivity và performance"""
        start_time = time.time()
        try:
            db: Session = SessionLocal()
            try:
                # Simple query to test connectivity
                result = db.execute(text("SELECT 1")).scalar()
                response_time_ms = (time.time() - start_time) * 1000

                if result == 1 and response_time_ms < 1000:  # < 1 second
                    status = "healthy"
                    message = f"Database OK ({response_time_ms:.2f}ms)"
                elif result == 1:
                    status = "degraded"
                    message = f"Database slow ({response_time_ms:.2f}ms)"
                else:
                    status = "unhealthy"
                    message = "Database query failed"

                return HealthCheckResult(
                    service="database",
                    status=status,
                    response_time_ms=response_time_ms,
                    message=message,
                    timestamp=time.time(),
                    metadata={"query_result": result},
                )

            finally:
                db.close()

        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                service="database",
                status="unhealthy",
                response_time_ms=response_time_ms,
                message=f"Database connection failed: {str(e)}",
                timestamp=time.time(),
            )

    def _check_memory_health(self) -> HealthCheckResult:
        """Check memory usage health"""
        try:
            memory = psutil.virtual_memory()
            usage_percent = memory.percent

            if usage_percent < 70:
                status = "healthy"
                message = f"Memory usage OK ({usage_percent:.1f}%)"
            elif usage_percent < 85:
                status = "degraded"
                message = f"Memory usage elevated ({usage_percent:.1f}%)"
            else:
                status = "unhealthy"
                message = f"Memory usage critical ({usage_percent:.1f}%)"

            return HealthCheckResult(
                service="memory",
                status=status,
                response_time_ms=1.0,  # Memory check is very fast
                message=message,
                timestamp=time.time(),
                metadata={
                    "usage_percent": usage_percent,
                    "used_mb": round(memory.used / 1024 / 1024, 2),
                    "total_mb": round(memory.total / 1024 / 1024, 2),
                },
            )

        except Exception as e:
            return HealthCheckResult(
                service="memory",
                status="unhealthy",
                response_time_ms=1.0,
                message=f"Memory check failed: {str(e)}",
                timestamp=time.time(),
            )

    def _check_disk_health(self) -> HealthCheckResult:
        """Check disk usage health"""
        try:
            disk = psutil.disk_usage("/")
            usage_percent = (disk.used / disk.total) * 100

            if usage_percent < 80:
                status = "healthy"
                message = f"Disk usage OK ({usage_percent:.1f}%)"
            elif usage_percent < 90:
                status = "degraded"
                message = f"Disk usage elevated ({usage_percent:.1f}%)"
            else:
                status = "unhealthy"
                message = f"Disk usage critical ({usage_percent:.1f}%)"

            return HealthCheckResult(
                service="disk",
                status=status,
                response_time_ms=1.0,
                message=message,
                timestamp=time.time(),
                metadata={
                    "usage_percent": round(usage_percent, 2),
                    "used_gb": round(disk.used / 1024 / 1024 / 1024, 2),
                    "total_gb": round(disk.total / 1024 / 1024 / 1024, 2),
                },
            )

        except Exception as e:
            return HealthCheckResult(
                service="disk",
                status="unhealthy",
                response_time_ms=1.0,
                message=f"Disk check failed: {str(e)}",
                timestamp=time.time(),
            )

    def _check_cpu_health(self) -> HealthCheckResult:
        """Check CPU usage health"""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)

            if cpu_percent < 60:
                status = "healthy"
                message = f"CPU usage OK ({cpu_percent:.1f}%)"
            elif cpu_percent < 80:
                status = "degraded"
                message = f"CPU usage elevated ({cpu_percent:.1f}%)"
            else:
                status = "unhealthy"
                message = f"CPU usage critical ({cpu_percent:.1f}%)"

            return HealthCheckResult(
                service="cpu",
                status=status,
                response_time_ms=100.0,  # CPU check takes ~100ms
                message=message,
                timestamp=time.time(),
                metadata={
                    "usage_percent": round(cpu_percent, 2),
                    "core_count": psutil.cpu_count(),
                },
            )

        except Exception as e:
            return HealthCheckResult(
                service="cpu",
                status="unhealthy",
                response_time_ms=100.0,
                message=f"CPU check failed: {str(e)}",
                timestamp=time.time(),
            )


# Global performance monitor instance
performance_monitor = PerformanceMonitor()


# Middleware function for performance tracking


async def performance_monitoring_middleware(request: Request, call_next):
    """Performance monitoring middleware"""
    start_time = time.time()

    # Process request
    response = await call_next(request)

    # Record metrics
    duration_ms = (time.time() - start_time) * 1000
    performance_monitor.record_request_metrics(request, response, duration_ms)

    # Add performance headers
    response.headers["X-Response-Time"] = f"{duration_ms:.2f}ms"

    return response


# Utility functions


async def get_performance_dashboard_data():
    """Get comprehensive performance data cho admin dashboard"""
    try:
        health_status = await performance_monitor.get_health_status()
        performance_summary = performance_monitor.get_performance_summary()

        return {
            "status": "success",
            "health": health_status,
            "performance": performance_summary,
            "timestamp": time.time(),
        }
    except Exception as e:
        return {"status": "error", "error": str(e), "timestamp": time.time()}


def record_database_operation(operation_type: str, duration_ms: float):
    """Record database operation performance"""
    performance_monitor.record_database_query(duration_ms, operation_type)


async def check_system_health():
    """Quick system health check"""
    return await performance_monitor.get_health_status()
