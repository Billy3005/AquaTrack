from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.friend import friend_crud, friend_request_crud
from app.crud.leaderboard import leaderboard_crud
from app.schemas.social import (
    FriendReminderRequest,
    FriendReminderResponse,
    FriendRequestCreate,
    FriendRequestResponse,
    FriendRequestUpdate,
    FriendResponse,
    LeaderboardEntryResponse,
    SocialStatsResponse,
    UserSearchResult,
    WeeklyLeaderboardResponse,
)
from app.services.social_service import social_service

router = APIRouter()


# Friend Request endpoints
@router.post(
    "/request/",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
)
async def send_friend_request(
    request_data: dict,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Send a friend request to another user by username

    - **username**: Username of the user to send request to
    - **message**: Optional message to include with the request
    """
    username = request_data.get("username")
    message = request_data.get("message")

    if not username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username is required"
        )

    result = await social_service.send_friend_request(
        db, sender_id=current_user_id, receiver_username=username, message=message
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


# Flutter-compatible friend request response endpoint
@router.put("/request/{request_id}/", response_model=dict)
async def respond_to_friend_request(
    request_id: str,
    action_data: dict,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Respond to friend request (accept/decline) - Flutter compatible"""
    action = action_data.get("action")

    if action not in ["accept", "decline"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Action must be 'accept' or 'decline'",
        )

    if action == "accept":
        result = await social_service.accept_friend_request(
            db, request_id=request_id, user_id=current_user_id
        )
    else:
        result = await social_service.decline_friend_request(
            db, request_id=request_id, user_id=current_user_id
        )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


@router.get("/requests/", response_model=List[FriendRequestResponse])
async def get_received_requests(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get friend requests received by current user"""
    requests = friend_request_crud.get_user_requests(
        db, user_id=current_user_id, request_type="received", skip=skip, limit=limit
    )

    return requests


@router.get("/requests/sent", response_model=List[FriendRequestResponse])
async def get_sent_requests(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get friend requests sent by current user"""
    requests = friend_request_crud.get_user_requests(
        db, user_id=current_user_id, request_type="sent", skip=skip, limit=limit
    )

    return requests


@router.put("/requests/{request_id}/accept", response_model=dict)
async def accept_friend_request(
    request_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Accept a friend request"""
    result = await social_service.accept_friend_request(
        db, request_id=request_id, user_id=current_user_id
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


@router.put("/requests/{request_id}/decline", response_model=dict)
async def decline_friend_request(
    request_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Decline a friend request"""
    result = await social_service.decline_friend_request(
        db, request_id=request_id, user_id=current_user_id
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


@router.delete("/requests/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_friend_request(
    request_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Cancel a friend request (sender only)"""
    try:
        friend_request_crud.cancel_request(
            db, request_id=request_id, user_id=current_user_id
        )
        return None
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# Friends management endpoints
@router.get("/", response_model=List[FriendResponse])
async def get_friends(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get current user's friends list"""
    friends = friend_crud.get_user_friends(
        db, user_id=current_user_id, skip=skip, limit=limit
    )

    return friends


@router.delete("/{friend_id}/", response_model=dict)
async def remove_friend_by_id(
    friend_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Remove a friend by friend ID (Flutter compatible)"""
    # Get friend username from user ID
    from app.crud.user import user_crud

    friend_user = user_crud.get(db, id=friend_id)

    if not friend_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Friend not found"
        )

    result = await social_service.remove_friend(
        db, user_id=current_user_id, friend_username=friend_user.username
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


@router.delete("/", response_model=dict)
async def remove_friend_by_username(
    friend_username: str = Query(..., description="Username of friend to remove"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Remove a friend by username"""
    result = await social_service.remove_friend(
        db, user_id=current_user_id, friend_username=friend_username
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


@router.post("/{friend_id}/remind/", response_model=FriendReminderResponse)
async def send_hydration_reminder(
    friend_id: str,
    reminder_data: FriendReminderRequest,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Send hydration reminder to a friend (Flutter compatible)"""
    # Get friend username from user ID
    from app.crud.user import user_crud

    friend_user = user_crud.get(db, id=friend_id)

    if not friend_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Friend not found"
        )

    result = await social_service.send_hydration_reminder(
        db,
        sender_id=current_user_id,
        friend_username=friend_user.username,
        message=reminder_data.message,
    )

    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["message"]
        )

    return result


# User search endpoint - Must come BEFORE /{friend_id}/ route
@router.get("/search", response_model=List[UserSearchResult])
async def search_users(
    q: str = Query(..., min_length=2, description="Search query (username)"),
    limit: int = Query(20, ge=1, le=50),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Search for users by username"""
    users = friend_crud.search_users(
        db, query=q, current_user_id=current_user_id, limit=limit
    )

    return users


@router.get("/{friend_id}/", response_model=FriendResponse)
async def get_friend_profile(
    friend_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get friend profile by friend ID"""
    # Check if they are friends
    if not friend_crud.are_friends(
        db, user_id=current_user_id, other_user_id=friend_id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view profiles of friends",
        )

    # Get friend data
    friend_data = friend_crud.get_friend_profile(
        db, user_id=current_user_id, friend_user_id=friend_id
    )

    if not friend_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Friend not found"
        )

    return friend_data


@router.put("/me/status/", response_model=dict)
async def update_my_status(
    status_data: dict,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Update current user's friend status"""
    status_value = status_data.get("status")

    if status_value not in ["normal", "thirsty", "stressed", "offline"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status must be one of: normal, thirsty, stressed, offline",
        )

    # Update user status in database
    from app.crud.user import user_crud

    user_crud.update_status(db, user_id=current_user_id, status=status_value)

    return {
        "success": True,
        "message": f"Status updated to {status_value}",
        "status": status_value,
        "updated_at": "datetime.utcnow().isoformat()",
    }


# Leaderboard endpoints
@router.get("/leaderboard/weekly", response_model=WeeklyLeaderboardResponse)
async def get_weekly_leaderboard(
    limit: int = Query(10, ge=1, le=50, description="Number of top entries to return"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get current week's hydration leaderboard"""
    leaderboard = leaderboard_crud.get_weekly_leaderboard(
        db, current_user_id=current_user_id, limit=limit
    )

    return leaderboard


@router.get("/leaderboard/history", response_model=List[dict])
async def get_leaderboard_history(
    limit: int = Query(10, ge=1, le=20, description="Number of weeks to return"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get user's leaderboard history"""
    history = leaderboard_crud.get_user_leaderboard_history(
        db, user_id=current_user_id, limit=limit
    )

    return history


# Social stats endpoint
@router.get("/stats", response_model=SocialStatsResponse)
async def get_social_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get user's social statistics and activity"""
    stats = await social_service.get_social_stats(db, user_id=current_user_id)

    return stats


# Block/unblock endpoints
@router.post("/block", response_model=dict)
async def block_user(
    username: str = Query(..., description="Username of user to block"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Block a user (removes friendship and prevents future requests)"""
    from app.crud.user import user_crud

    # Find user by username
    user_to_block = user_crud.get_by_username(db, username=username)
    if not user_to_block:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=f"User '{username}' not found"
        )

    if user_to_block.id == current_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot block yourself"
        )

    success = friend_crud.block_user(
        db, user_id=current_user_id, blocked_user_id=user_to_block.id
    )

    if success:
        return {
            "success": True,
            "message": f"Blocked user {username}",
            "blocked_at": "datetime.utcnow().isoformat()",
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to block user"
        )


@router.post("/unblock", response_model=dict)
async def unblock_user(
    username: str = Query(..., description="Username of user to unblock"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Unblock a previously blocked user"""
    from app.crud.user import user_crud

    # Find user by username
    user_to_unblock = user_crud.get_by_username(db, username=username)
    if not user_to_unblock:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=f"User '{username}' not found"
        )

    success = friend_crud.unblock_user(
        db, user_id=current_user_id, blocked_user_id=user_to_unblock.id
    )

    if success:
        return {
            "success": True,
            "message": f"Unblocked user {username}",
            "unblocked_at": "datetime.utcnow().isoformat()",
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User was not blocked or failed to unblock",
        )
