#!/usr/bin/env python3
"""
Background Task Processing Service cho AquaTrack Production
Asynchronous task processing với queue system, retry mechanisms và monitoring
"""

import asyncio
import json
import uuid
import time
import traceback
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, Callable, List, Union
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict, deque
import threading
from concurrent.futures import ThreadPoolExecutor

from ..middleware.logging import structured_logger


class TaskStatus(Enum):
    """Task execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    RETRY = "retry"
    CANCELLED = "cancelled"


class TaskPriority(Enum):
    """Task priority levels"""
    LOW = 1
    NORMAL = 2
    HIGH = 3
    CRITICAL = 4


@dataclass
class BackgroundTask:
    """Background task definition"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    func_name: str = ""
    args: tuple = field(default_factory=tuple)
    kwargs: dict = field(default_factory=dict)
    priority: TaskPriority = TaskPriority.NORMAL
    max_retries: int = 3
    retry_delay: int = 5  # seconds
    timeout: int = 300    # seconds

    # State tracking
    status: TaskStatus = TaskStatus.PENDING
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    retry_count: int = 0
    error_message: Optional[str] = None
    result: Any = None

    # Context
    user_id: Optional[str] = None
    request_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert task to dictionary for serialization"""
        return {
            "id": self.id,
            "name": self.name,
            "func_name": self.func_name,
            "priority": self.priority.value,
            "status": self.status.value,
            "created_at": self.created_at,
            "started_at": self.started_at,
            "completed_at": self.completed_at,
            "retry_count": self.retry_count,
            "max_retries": self.max_retries,
            "error_message": self.error_message,
            "user_id": self.user_id,
            "request_id": self.request_id,
            "metadata": self.metadata,
            "duration_ms": self._get_duration_ms()
        }

    def _get_duration_ms(self) -> Optional[float]:
        """Calculate task duration in milliseconds"""
        if self.started_at:
            end_time = self.completed_at or time.time()
            return round((end_time - self.started_at) * 1000, 2)
        return None


class BackgroundTaskManager:
    """
    Production-ready background task manager với queue system
    """

    def __init__(self, max_workers: int = 4):
        # Task queues by priority
        self.queues = {
            TaskPriority.CRITICAL: asyncio.Queue(),
            TaskPriority.HIGH: asyncio.Queue(),
            TaskPriority.NORMAL: asyncio.Queue(),
            TaskPriority.LOW: asyncio.Queue()
        }

        # Task registry và tracking
        self.tasks: Dict[str, BackgroundTask] = {}
        self.running_tasks: Dict[str, asyncio.Task] = {}
        self.task_registry: Dict[str, Callable] = {}

        # Worker configuration
        self.max_workers = max_workers
        self.workers: List[asyncio.Task] = []
        self.is_running = False

        # Thread pool for CPU-intensive tasks
        self.thread_executor = ThreadPoolExecutor(max_workers=2)

        # Statistics và monitoring
        self.stats = {
            "total_submitted": 0,
            "total_completed": 0,
            "total_failed": 0,
            "total_retried": 0,
            "task_types": defaultdict(int),
            "completion_times": deque(maxlen=100),
            "recent_errors": deque(maxlen=50),
            "hourly_stats": defaultdict(lambda: {"submitted": 0, "completed": 0, "failed": 0})
        }

        # Cleanup task
        self.cleanup_task: Optional[asyncio.Task] = None

        # Register built-in tasks
        self._register_builtin_tasks()

    def _register_builtin_tasks(self):
        """Register built-in background tasks"""
        self.register_task("ai_coach_processing", self._ai_coach_processing_task)
        self.register_task("vision_image_processing", self._vision_processing_task)
        self.register_task("analytics_calculation", self._analytics_calculation_task)
        self.register_task("database_cleanup", self._database_cleanup_task)
        self.register_task("user_insights_generation", self._user_insights_task)
        self.register_task("daily_summary_calculation", self._daily_summary_task)

    def register_task(self, name: str, func: Callable):
        """Register task function"""
        self.task_registry[name] = func
        structured_logger.log_application_event(
            "task_registered",
            f"Background task '{name}' registered",
            context={"task_name": name}
        )

    async def start(self):
        """Start background task manager"""
        if self.is_running:
            return

        self.is_running = True

        # Start worker tasks
        for i in range(self.max_workers):
            worker_task = asyncio.create_task(self._worker(f"worker-{i}"))
            self.workers.append(worker_task)

        # Start cleanup task
        self.cleanup_task = asyncio.create_task(self._cleanup_completed_tasks())

        structured_logger.log_application_event(
            "task_manager_started",
            f"Background task manager started with {self.max_workers} workers"
        )

    async def stop(self):
        """Stop background task manager gracefully"""
        if not self.is_running:
            return

        self.is_running = False

        # Cancel all workers
        for worker in self.workers:
            worker.cancel()

        # Cancel cleanup task
        if self.cleanup_task:
            self.cleanup_task.cancel()

        # Wait for workers to complete
        await asyncio.gather(*self.workers, return_exceptions=True)

        # Shutdown thread executor
        self.thread_executor.shutdown(wait=True)

        structured_logger.log_application_event(
            "task_manager_stopped",
            "Background task manager stopped"
        )

    async def submit_task(
        self,
        func_name: str,
        *args,
        task_name: str = None,
        priority: TaskPriority = TaskPriority.NORMAL,
        max_retries: int = 3,
        timeout: int = 300,
        user_id: str = None,
        request_id: str = None,
        metadata: Dict[str, Any] = None,
        **kwargs
    ) -> str:
        """
        Submit background task for processing
        Returns task ID for tracking
        """
        if not self.is_running:
            raise RuntimeError("Task manager is not running")

        if func_name not in self.task_registry:
            raise ValueError(f"Unknown task function: {func_name}")

        # Create task
        task = BackgroundTask(
            name=task_name or func_name,
            func_name=func_name,
            args=args,
            kwargs=kwargs,
            priority=priority,
            max_retries=max_retries,
            timeout=timeout,
            user_id=user_id,
            request_id=request_id,
            metadata=metadata or {}
        )

        # Store task
        self.tasks[task.id] = task

        # Add to appropriate queue
        await self.queues[priority].put(task)

        # Update statistics
        self.stats["total_submitted"] += 1
        self.stats["task_types"][func_name] += 1
        hour_key = datetime.now().strftime("%Y-%m-%d-%H")
        self.stats["hourly_stats"][hour_key]["submitted"] += 1

        structured_logger.log_application_event(
            "task_submitted",
            f"Background task '{task.name}' submitted",
            user_id=user_id,
            context={
                "task_id": task.id,
                "func_name": func_name,
                "priority": priority.name,
                "request_id": request_id
            }
        )

        return task.id

    async def get_task_status(self, task_id: str) -> Optional[Dict[str, Any]]:
        """Get task status và progress"""
        task = self.tasks.get(task_id)
        if not task:
            return None

        return task.to_dict()

    async def cancel_task(self, task_id: str) -> bool:
        """Cancel pending or running task"""
        task = self.tasks.get(task_id)
        if not task:
            return False

        # Cancel if running
        if task_id in self.running_tasks:
            self.running_tasks[task_id].cancel()

        # Update status
        task.status = TaskStatus.CANCELLED
        task.completed_at = time.time()

        structured_logger.log_application_event(
            "task_cancelled",
            f"Task '{task.name}' cancelled",
            context={"task_id": task_id}
        )

        return True

    async def _worker(self, worker_name: str):
        """Background worker để process tasks"""
        structured_logger.log_application_event(
            "worker_started",
            f"Background worker '{worker_name}' started"
        )

        while self.is_running:
            try:
                # Get highest priority task
                task = await self._get_next_task()
                if not task:
                    await asyncio.sleep(1)
                    continue

                # Process task
                await self._execute_task(task, worker_name)

            except asyncio.CancelledError:
                break
            except Exception as e:
                structured_logger.log_application_event(
                    "worker_error",
                    f"Worker '{worker_name}' error: {str(e)}",
                    level="error",
                    context={"worker": worker_name, "error": str(e)}
                )
                await asyncio.sleep(1)

        structured_logger.log_application_event(
            "worker_stopped",
            f"Background worker '{worker_name}' stopped"
        )

    async def _get_next_task(self) -> Optional[BackgroundTask]:
        """Get next task from queues (priority order)"""
        for priority in [TaskPriority.CRITICAL, TaskPriority.HIGH, TaskPriority.NORMAL, TaskPriority.LOW]:
            try:
                task = self.queues[priority].get_nowait()
                return task
            except asyncio.QueueEmpty:
                continue
        return None

    async def _execute_task(self, task: BackgroundTask, worker_name: str):
        """Execute individual task với error handling và retry logic"""
        task.status = TaskStatus.RUNNING
        task.started_at = time.time()

        structured_logger.log_application_event(
            "task_started",
            f"Task '{task.name}' started by {worker_name}",
            user_id=task.user_id,
            context={"task_id": task.id, "worker": worker_name}
        )

        try:
            # Get task function
            func = self.task_registry[task.func_name]

            # Create task coroutine
            if asyncio.iscoroutinefunction(func):
                coro = func(*task.args, **task.kwargs)
            else:
                # Run CPU-bound task in thread pool
                loop = asyncio.get_event_loop()
                coro = loop.run_in_executor(self.thread_executor, func, *task.args, **task.kwargs)

            # Execute with timeout
            async_task = asyncio.create_task(coro)
            self.running_tasks[task.id] = async_task

            try:
                result = await asyncio.wait_for(async_task, timeout=task.timeout)

                # Task completed successfully
                task.status = TaskStatus.COMPLETED
                task.result = result
                task.completed_at = time.time()

                # Update statistics
                self.stats["total_completed"] += 1
                completion_time = task._get_duration_ms()
                if completion_time:
                    self.stats["completion_times"].append(completion_time)

                hour_key = datetime.now().strftime("%Y-%m-%d-%H")
                self.stats["hourly_stats"][hour_key]["completed"] += 1

                structured_logger.log_application_event(
                    "task_completed",
                    f"Task '{task.name}' completed successfully",
                    user_id=task.user_id,
                    context={
                        "task_id": task.id,
                        "duration_ms": completion_time,
                        "worker": worker_name
                    }
                )

            except asyncio.TimeoutError:
                # Task timeout
                async_task.cancel()
                raise TimeoutError(f"Task timed out after {task.timeout} seconds")

            finally:
                # Remove from running tasks
                self.running_tasks.pop(task.id, None)

        except Exception as e:
            # Task failed
            error_msg = str(e)
            task.error_message = error_msg

            # Check if should retry
            if task.retry_count < task.max_retries:
                task.retry_count += 1
                task.status = TaskStatus.RETRY

                # Re-queue with delay
                asyncio.create_task(self._retry_task(task))

                structured_logger.log_application_event(
                    "task_retry",
                    f"Task '{task.name}' will retry ({task.retry_count}/{task.max_retries})",
                    user_id=task.user_id,
                    context={
                        "task_id": task.id,
                        "error": error_msg,
                        "retry_count": task.retry_count
                    },
                    level="warning"
                )

                self.stats["total_retried"] += 1

            else:
                # Max retries exceeded
                task.status = TaskStatus.FAILED
                task.completed_at = time.time()

                # Update statistics
                self.stats["total_failed"] += 1
                self.stats["recent_errors"].append({
                    "task_id": task.id,
                    "task_name": task.name,
                    "error": error_msg,
                    "timestamp": time.time(),
                    "user_id": task.user_id
                })

                hour_key = datetime.now().strftime("%Y-%m-%d-%H")
                self.stats["hourly_stats"][hour_key]["failed"] += 1

                structured_logger.log_application_event(
                    "task_failed",
                    f"Task '{task.name}' failed permanently",
                    user_id=task.user_id,
                    context={
                        "task_id": task.id,
                        "error": error_msg,
                        "retry_count": task.retry_count,
                        "traceback": traceback.format_exc()
                    },
                    level="error"
                )

    async def _retry_task(self, task: BackgroundTask):
        """Retry failed task after delay"""
        await asyncio.sleep(task.retry_delay * task.retry_count)  # Exponential backoff
        task.status = TaskStatus.PENDING
        await self.queues[task.priority].put(task)

    async def _cleanup_completed_tasks(self):
        """Cleanup old completed tasks để prevent memory leak"""
        while self.is_running:
            try:
                current_time = time.time()
                cleanup_threshold = current_time - (24 * 3600)  # 24 hours

                tasks_to_remove = []
                for task_id, task in self.tasks.items():
                    if (task.status in [TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED] and
                        task.completed_at and task.completed_at < cleanup_threshold):
                        tasks_to_remove.append(task_id)

                for task_id in tasks_to_remove:
                    del self.tasks[task_id]

                if tasks_to_remove:
                    structured_logger.log_application_event(
                        "tasks_cleaned_up",
                        f"Cleaned up {len(tasks_to_remove)} old completed tasks"
                    )

                # Sleep for 1 hour before next cleanup
                await asyncio.sleep(3600)

            except asyncio.CancelledError:
                break
            except Exception as e:
                structured_logger.log_application_event(
                    "cleanup_error",
                    f"Task cleanup error: {str(e)}",
                    level="error"
                )
                await asyncio.sleep(60)  # Wait 1 minute before retry

    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive task manager statistics"""
        current_time = time.time()

        # Calculate averages
        avg_completion_time = (
            sum(self.stats["completion_times"]) / len(self.stats["completion_times"])
            if self.stats["completion_times"] else 0
        )

        # Active task counts
        active_counts = {
            status.value: sum(1 for t in self.tasks.values() if t.status == status)
            for status in TaskStatus
        }

        # Queue sizes
        queue_sizes = {}
        for priority, queue in self.queues.items():
            queue_sizes[priority.name.lower()] = queue.qsize()

        return {
            "overview": {
                "total_submitted": self.stats["total_submitted"],
                "total_completed": self.stats["total_completed"],
                "total_failed": self.stats["total_failed"],
                "total_retried": self.stats["total_retried"],
                "success_rate_percent": round(
                    (self.stats["total_completed"] / max(1, self.stats["total_submitted"])) * 100, 2
                ),
                "avg_completion_time_ms": round(avg_completion_time, 2),
                "active_workers": len(self.workers),
                "is_running": self.is_running
            },
            "active_task_counts": active_counts,
            "queue_sizes": queue_sizes,
            "task_types": dict(self.stats["task_types"]),
            "recent_errors": list(self.stats["recent_errors"])[-10:],  # Last 10 errors
            "hourly_stats": dict(list(self.stats["hourly_stats"].items())[-24:])  # Last 24 hours
        }

    # Built-in task implementations

    async def _ai_coach_processing_task(self, user_id: str, message: str, context: Dict = None):
        """Process AI coach request in background"""
        from ..services.ai_coach_service import enhanced_ai_coach_service

        try:
            response = await enhanced_ai_coach_service.generate_coach_response(
                user_message=message,
                user_context=context or {},
                hydration_data={},  # Will be populated from database
                user_id=user_id
            )

            return {
                "status": "success",
                "response": response,
                "processing_time_ms": response.get("processing_time_ms", 0)
            }
        except Exception as e:
            raise Exception(f"AI Coach processing failed: {str(e)}")

    async def _vision_processing_task(self, user_id: str, image_data: bytes, image_format: str):
        """Process vision image analysis in background"""
        # Placeholder for vision processing
        # In real implementation, this would call vision service
        await asyncio.sleep(2)  # Simulate processing time

        return {
            "container_class": "water_bottle",
            "fill_level_percent": 75.0,
            "confidence": 0.92,
            "estimated_volume_ml": 375
        }

    async def _analytics_calculation_task(self, user_id: str, calculation_type: str, date_range: Dict):
        """Calculate analytics in background"""
        from ..services.analytics_service import analytics_service

        # Simulate analytics calculation
        await asyncio.sleep(1)

        return {
            "calculation_type": calculation_type,
            "date_range": date_range,
            "insights": ["Good hydration pattern", "Consistent morning intake"]
        }

    def _database_cleanup_task(self, cleanup_type: str, days_old: int = 30):
        """Database cleanup task (CPU-bound, runs in thread pool)"""
        # Placeholder for database cleanup
        time.sleep(0.5)  # Simulate cleanup

        return {
            "cleanup_type": cleanup_type,
            "records_cleaned": 150,
            "days_old": days_old
        }

    async def _user_insights_task(self, user_id: str):
        """Generate user insights in background"""
        # Placeholder for insights generation
        await asyncio.sleep(1.5)

        return {
            "insights": [
                "Your hydration improved 15% this week",
                "Best hydration time: 10-11 AM"
            ],
            "score": 85
        }

    async def _daily_summary_task(self, user_id: str, date: str):
        """Calculate daily summary in background"""
        # Placeholder for daily summary calculation
        await asyncio.sleep(0.8)

        return {
            "date": date,
            "total_volume_ml": 2100,
            "goal_achieved": True,
            "streak_days": 5
        }


# Global task manager instance
task_manager = BackgroundTaskManager()


# Utility functions for application use

async def submit_ai_coach_task(
    user_id: str,
    message: str,
    context: Dict = None,
    priority: TaskPriority = TaskPriority.HIGH
) -> str:
    """Submit AI coach processing task"""
    return await task_manager.submit_task(
        "ai_coach_processing",
        user_id, message, context,
        task_name=f"AI Coach for user {user_id}",
        priority=priority,
        user_id=user_id,
        timeout=120  # Increased for Ollama AI responses
    )

async def submit_vision_task(
    user_id: str,
    image_data: bytes,
    image_format: str,
    priority: TaskPriority = TaskPriority.HIGH
) -> str:
    """Submit vision processing task"""
    return await task_manager.submit_task(
        "vision_image_processing",
        user_id, image_data, image_format,
        task_name=f"Vision scan for user {user_id}",
        priority=priority,
        user_id=user_id,
        timeout=120  # Vision processing can take longer
    )

async def submit_analytics_task(
    user_id: str,
    calculation_type: str,
    date_range: Dict,
    priority: TaskPriority = TaskPriority.NORMAL
) -> str:
    """Submit analytics calculation task"""
    return await task_manager.submit_task(
        "analytics_calculation",
        user_id, calculation_type, date_range,
        task_name=f"Analytics for user {user_id}",
        priority=priority,
        user_id=user_id,
        timeout=180
    )