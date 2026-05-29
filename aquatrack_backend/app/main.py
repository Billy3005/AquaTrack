import asyncio
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import api_router
from app.core.config import settings
from app.core.database import init_db
from app.core.monitoring import (HealthChecker, metrics, monitoring_middleware,
                                 system_monitoring_task)
from app.middleware.rate_limiting import rate_limit_middleware
from app.services.email_service import cleanup_expired_tokens_task

# Background task references for cleanup
background_tasks = []


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management"""
    # Startup
    print("Starting AquaTrack API...")

    # Initialize database
    init_db()
    print("Database initialized")

    # Start background tasks if monitoring enabled
    if settings.ENABLE_MONITORING:
        # Start system monitoring task
        monitoring_task = asyncio.create_task(system_monitoring_task())
        background_tasks.append(monitoring_task)
        print("System monitoring started")

        # Start email token cleanup task
        cleanup_task = asyncio.create_task(cleanup_expired_tokens_task())
        background_tasks.append(cleanup_task)
        print("Email token cleanup started")

    print("AquaTrack API is ready!")

    yield

    # Shutdown
    print("Shutting down AquaTrack API...")

    # Cancel background tasks
    for task in background_tasks:
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass

    print("AquaTrack API shutdown complete")


# FastAPI app instance
app = FastAPI(
    title="AquaTrack API",
    description="The hydration tracking app backend that feels alive",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "development" else None,
)

# Performance monitoring middleware
if settings.ENABLE_MONITORING:
    app.middleware("http")(monitoring_middleware)

# Rate limiting middleware
if settings.ENABLE_RATE_LIMITING:
    app.middleware("http")(rate_limit_middleware)

# CORS middleware cho Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=[
        "Accept",
        "Accept-Language",
        "Content-Language",
        "Content-Type",
        "Authorization",
        "X-Requested-With",
        "X-RateLimit-Limit",
        "X-RateLimit-Remaining",
        "X-RateLimit-Reset",
    ],
    expose_headers=[
        "X-Process-Time",
        "X-RateLimit-Limit",
        "X-RateLimit-Remaining",
        "X-RateLimit-Reset",
        "X-RateLimit-Window",
    ],
)

# API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/", response_class=JSONResponse)
async def root():
    """Health check endpoint"""
    return {
        "message": "AquaTrack API is running! 💧",
        "version": "1.0.0",
        "status": "healthy",
        "features": "Phase 4 - Production Ready + Smart Scan + Social Features + Achievements",
    }


@app.get("/health", response_class=JSONResponse)
async def health_check():
    """Basic health check"""
    return {
        "status": "ok",
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0",
        "uptime_seconds": int(metrics.start_time),
    }


@app.get("/health/detailed", response_class=JSONResponse)
async def detailed_health_check():
    """Comprehensive health check with system metrics"""
    if not settings.ENABLE_MONITORING:
        return {"error": "Monitoring disabled"}

    health_data = await HealthChecker.get_comprehensive_health()
    return health_data


@app.get("/metrics", response_class=JSONResponse)
async def get_metrics():
    """Get application metrics"""
    if not settings.ENABLE_MONITORING:
        return {"error": "Monitoring disabled"}

    return {
        "request_stats": metrics.get_request_stats(),
        "system_stats": metrics.get_system_stats(),
        "recent_errors": metrics.get_recent_errors(10),
    }


@app.get("/cors-test", response_class=JSONResponse)
async def cors_test():
    """CORS test endpoint"""
    return {
        "message": "CORS working! Frontend can call backend APIs",
        "allowed_origins": settings.ALLOWED_ORIGINS,
        "timestamp": "2026-05-04",
    }


@app.post("/simple-login", response_class=JSONResponse)
async def simple_login(request: dict):
    """Simple login endpoint for CORS testing"""
    email = request.get("email", "")
    password = request.get("password", "")

    if email == "demo@aquatrack.com" and password == "demo123":
        return {
            "success": True,
            "message": "Login successful!",
            "access_token": "demo_token_123",
            "user": {"email": email, "name": "Demo User"},
        }
    else:
        return {"success": False, "message": "Invalid credentials"}


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8001,
        reload=settings.ENVIRONMENT == "development",
    )
