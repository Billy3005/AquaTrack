"""
Performance monitoring and health checks for AquaTrack backend
Includes metrics collection, health endpoints, and alert system
"""

import asyncio
import platform
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import psutil
from fastapi import Request, Response
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import get_db


class MetricsCollector:
    """Collect and store application metrics"""

    def __init__(self):
        self.request_metrics = defaultdict(
            lambda: {
                "count": 0,
                "total_time": 0.0,
                "error_count": 0,
                "recent_times": deque(maxlen=100),  # Keep last 100 response times
            }
        )
        self.system_metrics = {
            "cpu_usage": deque(maxlen=60),  # Last 60 measurements
            "memory_usage": deque(maxlen=60),
            "disk_usage": deque(maxlen=60),
            "active_connections": deque(maxlen=60),
        }
        self.start_time = time.time()
        self.error_log = deque(maxlen=1000)  # Keep last 1000 errors

    def record_request(
        self, path: str, method: str, response_time: float, status_code: int
    ):
        """Record request metrics"""
        key = f"{method} {path}"
        metrics = self.request_metrics[key]

        metrics["count"] += 1
        metrics["total_time"] += response_time
        metrics["recent_times"].append(response_time)

        if status_code >= 400:
            metrics["error_count"] += 1

    def record_error(self, error: Exception, context: Dict[str, Any]):
        """Record error for monitoring"""
        self.error_log.append(
            {
                "timestamp": datetime.utcnow(),
                "error_type": type(error).__name__,
                "error_message": str(error),
                "context": context,
            }
        )

    def record_system_metrics(self):
        """Record current system metrics"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            self.system_metrics["cpu_usage"].append(
                {"timestamp": datetime.utcnow(), "value": cpu_percent}
            )

            # Memory usage
            memory = psutil.virtual_memory()
            self.system_metrics["memory_usage"].append(
                {"timestamp": datetime.utcnow(), "value": memory.percent}
            )

            # Disk usage
            disk = psutil.disk_usage("/")
            disk_percent = (disk.used / disk.total) * 100
            self.system_metrics["disk_usage"].append(
                {"timestamp": datetime.utcnow(), "value": disk_percent}
            )

            # Network connections (approximate active connections)
            connections = len(psutil.net_connections())
            self.system_metrics["active_connections"].append(
                {"timestamp": datetime.utcnow(), "value": connections}
            )

        except Exception as e:
            print(f"Failed to collect system metrics: {e}")

    def get_request_stats(self) -> Dict[str, Any]:
        """Get aggregated request statistics"""
        stats = {}

        for endpoint, metrics in self.request_metrics.items():
            if metrics["count"] > 0:
                avg_time = metrics["total_time"] / metrics["count"]
                error_rate = (metrics["error_count"] / metrics["count"]) * 100

                recent_times = list(metrics["recent_times"])
                if recent_times:
                    recent_avg = sum(recent_times) / len(recent_times)
                    p95_time = (
                        sorted(recent_times)[int(len(recent_times) * 0.95)]
                        if len(recent_times) >= 20
                        else max(recent_times)
                    )
                else:
                    recent_avg = avg_time
                    p95_time = avg_time

                stats[endpoint] = {
                    "total_requests": metrics["count"],
                    "error_count": metrics["error_count"],
                    "error_rate_percent": round(error_rate, 2),
                    "avg_response_time_ms": round(avg_time * 1000, 2),
                    "recent_avg_response_time_ms": round(recent_avg * 1000, 2),
                    "p95_response_time_ms": round(p95_time * 1000, 2),
                }

        return stats

    def get_system_stats(self) -> Dict[str, Any]:
        """Get current system statistics"""
        stats = {
            "uptime_seconds": int(time.time() - self.start_time),
            "platform": platform.system(),
            "python_version": platform.python_version(),
        }

        # Add latest system metrics
        for metric_name, metric_data in self.system_metrics.items():
            if metric_data:
                latest = metric_data[-1]
                stats[f"{metric_name}_current"] = latest["value"]

                # Calculate average over last 5 minutes
                recent_values = [
                    item["value"]
                    for item in metric_data
                    if item["timestamp"] > datetime.utcnow() - timedelta(minutes=5)
                ]
                if recent_values:
                    stats[f"{metric_name}_avg_5min"] = round(
                        sum(recent_values) / len(recent_values), 2
                    )

        return stats

    def get_recent_errors(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent errors"""
        recent_errors = list(self.error_log)[-limit:]
        return [
            {
                "timestamp": error["timestamp"].isoformat(),
                "error_type": error["error_type"],
                "error_message": error["error_message"],
                "context": error["context"],
            }
            for error in recent_errors
        ]


# Global metrics collector
metrics = MetricsCollector()


class HealthChecker:
    """Health check utilities"""

    @staticmethod
    async def check_database_health() -> Dict[str, Any]:
        """Check database connectivity and performance"""
        try:
            start_time = time.time()

            # Get database session
            db_gen = get_db()
            db: Session = next(db_gen)

            try:
                # Simple query to test connectivity
                result = db.execute(text("SELECT 1")).fetchone()
                connection_time = (time.time() - start_time) * 1000

                # Check if result is valid
                if result and result[0] == 1:
                    return {
                        "status": "healthy",
                        "connection_time_ms": round(connection_time, 2),
                        "message": "Database connection successful",
                    }
                else:
                    return {
                        "status": "unhealthy",
                        "connection_time_ms": round(connection_time, 2),
                        "message": "Database query returned unexpected result",
                    }
            finally:
                db.close()

        except Exception as e:
            return {
                "status": "unhealthy",
                "connection_time_ms": None,
                "message": f"Database connection failed: {str(e)}",
            }

    @staticmethod
    def check_disk_space() -> Dict[str, Any]:
        """Check available disk space"""
        try:
            disk_usage = psutil.disk_usage("/")
            free_gb = disk_usage.free / (1024**3)
            total_gb = disk_usage.total / (1024**3)
            used_percent = (disk_usage.used / disk_usage.total) * 100

            status = "healthy"
            message = "Disk space normal"

            if used_percent > 90:
                status = "critical"
                message = "Disk space critically low"
            elif used_percent > 80:
                status = "warning"
                message = "Disk space getting low"

            return {
                "status": status,
                "free_gb": round(free_gb, 2),
                "total_gb": round(total_gb, 2),
                "used_percent": round(used_percent, 2),
                "message": message,
            }
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to check disk space: {str(e)}",
            }

    @staticmethod
    def check_memory_usage() -> Dict[str, Any]:
        """Check memory usage"""
        try:
            memory = psutil.virtual_memory()

            status = "healthy"
            message = "Memory usage normal"

            if memory.percent > 90:
                status = "critical"
                message = "Memory usage critically high"
            elif memory.percent > 80:
                status = "warning"
                message = "Memory usage high"

            return {
                "status": status,
                "used_percent": memory.percent,
                "available_gb": round(memory.available / (1024**3), 2),
                "total_gb": round(memory.total / (1024**3), 2),
                "message": message,
            }
        except Exception as e:
            return {"status": "error", "message": f"Failed to check memory: {str(e)}"}

    @staticmethod
    async def get_comprehensive_health() -> Dict[str, Any]:
        """Get comprehensive health check"""
        health_checks = {
            "database": await HealthChecker.check_database_health(),
            "disk": HealthChecker.check_disk_space(),
            "memory": HealthChecker.check_memory_usage(),
        }

        # Determine overall status
        critical_count = sum(
            1 for check in health_checks.values() if check["status"] == "critical"
        )
        warning_count = sum(
            1
            for check in health_checks.values()
            if check["status"] in ["warning", "unhealthy"]
        )

        if critical_count > 0:
            overall_status = "critical"
        elif warning_count > 0:
            overall_status = "warning"
        else:
            overall_status = "healthy"

        return {
            "overall_status": overall_status,
            "timestamp": datetime.utcnow().isoformat(),
            "checks": health_checks,
            "uptime_seconds": int(time.time() - metrics.start_time),
        }


async def monitoring_middleware(request: Request, call_next):
    """Middleware to collect request metrics"""
    start_time = time.time()

    try:
        response: Response = await call_next(request)
        process_time = time.time() - start_time

        # Record successful request
        metrics.record_request(
            path=request.url.path,
            method=request.method,
            response_time=process_time,
            status_code=response.status_code,
        )

        # Add performance headers
        response.headers["X-Process-Time"] = str(round(process_time * 1000, 2))

        return response

    except Exception as e:
        process_time = time.time() - start_time

        # Record error
        metrics.record_request(
            path=request.url.path,
            method=request.method,
            response_time=process_time,
            status_code=500,
        )

        # Log error for monitoring
        metrics.record_error(
            e,
            {
                "path": request.url.path,
                "method": request.method,
                "user_agent": request.headers.get("user-agent"),
                "ip": request.client.host if request.client else "unknown",
            },
        )

        raise


class AlertManager:
    """Manage alerts and notifications for system issues"""

    def __init__(self):
        self.alert_thresholds = {
            "cpu_usage": 80,
            "memory_usage": 85,
            "disk_usage": 85,
            "error_rate": 5.0,  # 5% error rate
            "response_time": 2000,  # 2 seconds
        }
        self.active_alerts = {}

    def check_alerts(self):
        """Check for alert conditions"""
        current_time = datetime.utcnow()
        alerts_triggered = []

        # Check system metrics
        system_stats = metrics.get_system_stats()

        for metric, threshold in self.alert_thresholds.items():
            if f"{metric}_current" in system_stats:
                current_value = system_stats[f"{metric}_current"]

                if current_value > threshold:
                    alert_key = f"high_{metric}"

                    if alert_key not in self.active_alerts:
                        alert = {
                            "type": alert_key,
                            "message": f'{metric.replace("_", " ").title()} is high: {current_value}%',
                            "value": current_value,
                            "threshold": threshold,
                            "started_at": current_time,
                            "severity": (
                                "warning"
                                if current_value < threshold * 1.2
                                else "critical"
                            ),
                        }

                        self.active_alerts[alert_key] = alert
                        alerts_triggered.append(alert)

                elif alert_key in self.active_alerts:
                    # Clear resolved alert
                    del self.active_alerts[alert_key]

        # Check error rates
        request_stats = metrics.get_request_stats()
        for endpoint, stats in request_stats.items():
            error_rate = stats["error_rate_percent"]

            if error_rate > self.alert_thresholds["error_rate"]:
                alert_key = f"high_error_rate_{endpoint}"

                if alert_key not in self.active_alerts:
                    alert = {
                        "type": "high_error_rate",
                        "endpoint": endpoint,
                        "message": f"High error rate on {endpoint}: {error_rate}%",
                        "error_rate": error_rate,
                        "threshold": self.alert_thresholds["error_rate"],
                        "started_at": current_time,
                        "severity": "warning" if error_rate < 10 else "critical",
                    }

                    self.active_alerts[alert_key] = alert
                    alerts_triggered.append(alert)

        return alerts_triggered

    def get_active_alerts(self) -> List[Dict[str, Any]]:
        """Get all active alerts"""
        return [
            {
                **alert,
                "started_at": alert["started_at"].isoformat(),
                "duration_minutes": int(
                    (datetime.utcnow() - alert["started_at"]).total_seconds() / 60
                ),
            }
            for alert in self.active_alerts.values()
        ]


# Global alert manager
alert_manager = AlertManager()


# Background task for system monitoring
async def system_monitoring_task():
    """Background task to collect system metrics and check alerts"""
    while True:
        try:
            # Collect system metrics
            metrics.record_system_metrics()

            # Check for alerts
            new_alerts = alert_manager.check_alerts()

            # Log new alerts (in production, would send to monitoring service)
            for alert in new_alerts:
                print(f"ALERT: {alert['message']} (Severity: {alert['severity']})")

            await asyncio.sleep(60)  # Check every minute

        except Exception as e:
            print(f"System monitoring error: {e}")
            await asyncio.sleep(60)  # Continue monitoring even if there's an error
