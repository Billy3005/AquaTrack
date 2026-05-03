import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import api_router
from app.core.config import settings

# FastAPI app instance
app = FastAPI(
    title="AquaTrack API",
    description="The hydration tracking app backend that feels alive",
    version="1.0.0",
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "development" else None,
)

# CORS middleware cho Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
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
    }


@app.get("/health", response_class=JSONResponse)
async def health_check():
    """Detailed health check"""
    return {
        "status": "ok",
        "environment": settings.ENVIRONMENT,
        "database": (
            "connected" if True else "disconnected"
        ),  # TODO: Add DB health check
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.ENVIRONMENT == "development",
    )
