from fastapi import APIRouter

# Import individual routers
from app.api.v1.endpoints import auth, coach, friends, intake, levels, stats, users, vision

# Main API router
api_router = APIRouter()

# Include endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(intake.router, prefix="/intake", tags=["intake"])
api_router.include_router(stats.router, prefix="/stats", tags=["stats"])
api_router.include_router(coach.router, prefix="/coach", tags=["ai-coach"])
api_router.include_router(levels.router, prefix="/levels", tags=["levels"])
api_router.include_router(vision.router, prefix="/vision", tags=["smart-scan"])
api_router.include_router(friends.router, prefix="/friends", tags=["social-features"])


# Health check endpoint
@api_router.get("/ping")
async def ping():
    """Health check endpoint for API v1"""
    return {
        "message": "pong",
        "status": "AquaTrack API v1 + Phase 2 Social Features! 🚀",
        "endpoints": "auth, users, intake, stats, coach, levels, vision, friends ready",
        "features": "Full hydration tracking + AI coach + gamification + Smart Scan ML + Social Features",
    }
