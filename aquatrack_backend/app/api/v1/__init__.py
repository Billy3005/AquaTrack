from fastapi import APIRouter

# Import individual routers
from app.api.v1.endpoints import auth, users

# from app.api.v1.endpoints import intake, stats, coach, levels

# Main API router
api_router = APIRouter()

# Include endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
# api_router.include_router(intake.router, prefix="/intake", tags=["intake"])
# api_router.include_router(stats.router, prefix="/stats", tags=["stats"])
# api_router.include_router(coach.router, prefix="/coach", tags=["ai-coach"])
# api_router.include_router(levels.router, prefix="/levels", tags=["levels"])


# Health check endpoint
@api_router.get("/ping")
async def ping():
    """Health check endpoint for API v1"""
    return {
        "message": "pong",
        "status": "API v1 is working!",
        "endpoints": "auth, users ready",
    }
