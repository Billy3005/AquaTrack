from datetime import datetime, timezone
from typing import Dict, List, Optional

from sqlalchemy.orm import Session

from app.crud.friend import friend_crud, friend_request_crud
from app.crud.leaderboard import leaderboard_crud
from app.crud.user import user_crud
from app.models.friend_request import FriendRequest, FriendRequestStatus


class SocialService:
    """Service for social features and friend interactions"""

    def __init__(self):
        """Initialize the social service"""
        pass

    async def send_friend_request(
        self,
        db: Session,
        *,
        sender_id: str,
        receiver_username: str,
        message: Optional[str] = None,
    ) -> Dict:
        """Send a friend request by username"""
        # Find receiver by username
        receiver = user_crud.get_by_username(db, username=receiver_username)
        if not receiver:
            raise ValueError(f"User '{receiver_username}' not found")

        if receiver.id == sender_id:
            raise ValueError("Cannot send friend request to yourself")

        # Mutual-invite collision: if the receiver already has a pending request
        # to *us*, accept it instead of erroring — both clearly want to be friends.
        reverse = (
            db.query(FriendRequest)
            .filter(
                FriendRequest.sender_id == receiver.id,
                FriendRequest.receiver_id == sender_id,
                FriendRequest.status == FriendRequestStatus.PENDING,
            )
            .first()
        )
        if reverse is not None:
            friend_request_crud.accept_request(
                db, request_id=reverse.id, user_id=sender_id
            )
            return {
                "success": True,
                "message": f"Bạn và {receiver.username} đã trở thành bạn bè!",
                "auto_accepted": True,
            }

        # Use CRUD to create request
        try:
            from app.schemas.social import FriendRequestCreate

            request_data = FriendRequestCreate(receiver_id=receiver.id, message=message)
            friend_request = friend_request_crud.create_request(
                db, sender_id=sender_id, obj_in=request_data
            )

            return {
                "success": True,
                "message": f"Friend request sent to {receiver.username}",
                "request_id": friend_request.id,
                "sent_at": friend_request.created_at.isoformat(),
            }

        except ValueError as e:
            return {"success": False, "message": str(e)}

    async def accept_friend_request(
        self, db: Session, *, request_id: str, user_id: str
    ) -> Dict:
        """Accept a friend request"""
        try:
            friend_request = friend_request_crud.accept_request(
                db, request_id=request_id, user_id=user_id
            )

            # Get sender info for response
            sender = user_crud.get(db, id=friend_request.sender_id)

            return {
                "success": True,
                "message": (
                    f"You are now friends with {sender.username if sender else 'this user'}!"
                ),
                "accepted_at": friend_request.responded_at.isoformat(),
            }

        except ValueError as e:
            return {"success": False, "message": str(e)}

    async def decline_friend_request(
        self, db: Session, *, request_id: str, user_id: str
    ) -> Dict:
        """Decline a friend request"""
        try:
            friend_request = friend_request_crud.decline_request(
                db, request_id=request_id, user_id=user_id
            )

            return {
                "success": True,
                "message": "Friend request declined",
                "declined_at": friend_request.responded_at.isoformat(),
            }

        except ValueError as e:
            return {"success": False, "message": str(e)}

    async def remove_friend(
        self, db: Session, *, user_id: str, friend_username: str
    ) -> Dict:
        """Remove a friend by username"""
        # Find friend by username
        friend_user = user_crud.get_by_username(db, username=friend_username)
        if not friend_user:
            raise ValueError(f"User '{friend_username}' not found")

        # Check if they are friends
        if not friend_crud.are_friends(
            db, user_id=user_id, other_user_id=friend_user.id
        ):
            return {"success": False, "message": "You are not friends with this user"}

        # Remove friendship
        removed = friend_crud.remove_friendship(
            db, user_id=user_id, friend_user_id=friend_user.id
        )

        if removed:
            return {
                "success": True,
                "message": f"Removed {friend_user.username} from friends",
                "removed_at": datetime.utcnow().isoformat(),
            }
        else:
            return {"success": False, "message": "Failed to remove friend"}

    async def get_social_stats(self, db: Session, *, user_id: str) -> Dict:
        """Get user's social statistics"""
        # Get friends count
        friends = friend_crud.get_user_friends(db, user_id=user_id, limit=1000)
        total_friends = len(friends)

        # Get pending requests count
        pending_requests = friend_request_crud.get_user_requests(
            db, user_id=user_id, request_type="received", limit=1000
        )
        pending_count = len(pending_requests)

        # Get current week rank
        current_week_start = leaderboard_crud.get_current_week_start()
        current_week_leaderboard = leaderboard_crud.get_weekly_leaderboard(
            db, week_start=current_week_start, current_user_id=user_id, limit=100
        )
        current_week_rank = current_week_leaderboard.get("current_user_rank")

        # Get best rank
        best_week_rank = leaderboard_crud.get_user_best_rank(db, user_id=user_id)

        # Get participation count
        weeks_participated = leaderboard_crud.get_participation_count(
            db, user_id=user_id
        )

        # Get recent friend activity (simplified)
        recent_activity = self._get_recent_friend_activity(
            db, user_id=user_id, friends=friends
        )

        return {
            "total_friends": total_friends,
            "pending_requests": pending_count,
            "current_week_rank": current_week_rank,
            "best_week_rank": best_week_rank,
            "weeks_participated": weeks_participated,
            "recent_friend_activity": recent_activity,
        }

    def _get_recent_friend_activity(
        self, db: Session, *, user_id: str, friends: List[Dict], limit: int = 5
    ) -> List[Dict]:
        """Get comprehensive hydration activity from friends"""
        recent_activity = []

        for friend in friends[:limit]:
            # Get friend's recent logs with complete data
            from app.crud.intake_log import intake_log_crud

            friend_recent_logs = intake_log_crud.get_by_user(
                db,
                user_id=friend["friend_user_id"],
                skip=0,
                limit=5,  # Get more recent logs
            )

            for log in friend_recent_logs[:3]:  # Show top 3 activities
                # Calculate time since activity
                time_diff = datetime.utcnow() - log.logged_at
                hours_ago = int(time_diff.total_seconds() / 3600)

                activity = {
                    "friend_username": friend["friend_username"],
                    "friend_avatar_id": friend["friend_avatar_id"],
                    "activity_type": "logged_drink",
                    "volume_ml": log.effective_volume_ml,  # Correct field name
                    "liquid_type": log.liquid_type,  # Correct field name
                    "container_type": log.container_type,  # Additional info
                    "xp_earned": log.xp_earned,  # Show XP gained
                    "activity_time": log.logged_at.isoformat(),
                    "hours_ago": hours_ago,  # User-friendly time
                }
                recent_activity.append(activity)

        # Sort by most recent first
        recent_activity.sort(key=lambda x: x["activity_time"], reverse=True)
        return recent_activity[:limit]

    async def send_hydration_reminder(
        self,
        db: Session,
        *,
        sender_id: str,
        friend_username: str,
        message: Optional[str] = None,
    ) -> Dict:
        """Send hydration reminder to a friend"""
        # Find friend by username
        friend_user = user_crud.get_by_username(db, username=friend_username)
        if not friend_user:
            return {"success": False, "message": f"User '{friend_username}' not found"}

        # Check if they are friends
        if not friend_crud.are_friends(
            db, user_id=sender_id, other_user_id=friend_user.id
        ):
            return {
                "success": False,
                "message": "You can only send reminders to friends",
            }

        # Create notification record
        default_message = (
            "Stay hydrated! 💧 Your friend is reminding you to drink water!"
        )
        reminder_message = message or default_message

        # TODO: Replace with proper push notification service (FCM/APNS)
        # For now just log the intent; ReminderLog below is the queryable record.
        _sender_username = (
            user_crud.get(db, id=sender_id).username
            if user_crud.get(db, id=sender_id)
            else "Friend"
        )
        # (notification_data intentionally not stored — see TODO above)
        _ = {
            "type": "friend_reminder",
            "title": "Hydration Reminder",
            "body": reminder_message,
            "sender_id": sender_id,
            "sender_username": _sender_username,
            "timestamp": datetime.utcnow().isoformat(),
        }

        # Log notification for debugging/analytics
        print(f"🔔 Notification queued for {friend_user.username}: {reminder_message}")

        # Enforce a daily cap so reminders cannot be used to spam a friend or
        # farm the "Hội Bạn Cùng Uống" quest.
        from app.services import friends_view_service as fvs

        if fvs.reminders_sent_today(db, sender_id) >= fvs.REMINDER_DAILY_LIMIT:
            return {
                "success": False,
                "message": "Bạn đã gửi quá nhiều lời nhắc hôm nay. Thử lại vào ngày mai!",
            }

        # Per-pair cooldown: can't remind the *same* friend back-to-back, so the
        # "BẠN TÔI ƠI" ranking reflects a real relationship, not spam.
        last = fvs.last_reminder_at(db, sender_id, friend_user.id)
        if last is not None:
            last_aware = last if last.tzinfo else last.replace(tzinfo=timezone.utc)
            elapsed = datetime.now(timezone.utc) - last_aware
            if elapsed < fvs.REMINDER_COOLDOWN:
                mins = int((fvs.REMINDER_COOLDOWN - elapsed).total_seconds() // 60) + 1
                return {
                    "success": False,
                    "message": f"Đợi {mins} phút nữa mới nhắc {friend_user.username} được nhé!",
                }

        # Persist a queryable reminder record so the "Hội Bạn Cùng Uống" quest
        # can count reminders per day (the push payload above is not queryable).
        from app.models import ReminderLog

        db.add(ReminderLog(user_id=sender_id, friend_id=friend_user.id))
        db.commit()

        # TODO: Replace with proper push notification service (FCM, APNS)

        return {
            "success": True,
            "message": f"Hydration reminder sent to {friend_user.username}",
            "reminder_sent_at": datetime.utcnow().isoformat(),
        }

    async def update_weekly_leaderboards(self, db: Session) -> Dict:
        """Update leaderboard entries for all active users"""
        # This would typically run as a scheduled task
        current_week_start = leaderboard_crud.get_current_week_start()

        # Get all active users
        active_users = user_crud.get_active_users(
            db, limit=10000
        )  # Implement in user_crud
        updated_count = 0

        for user in active_users:
            try:
                # Update or create leaderboard entry
                leaderboard_crud.update_or_create_week_entry(
                    db, user_id=user.id, week_start=current_week_start
                )
                updated_count += 1
            except Exception as e:
                print(f"Error updating leaderboard for user {user.id}: {str(e)}")

        # Calculate rankings for all users
        leaderboard_crud.calculate_rankings(db, week_start=current_week_start)

        return {
            "success": True,
            "message": f"Updated leaderboard entries for {updated_count} users",
            "week_start": current_week_start.isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

    def get_friend_suggestions(
        self, db: Session, *, user_id: str, limit: int = 10
    ) -> List[Dict]:
        """Get friend suggestions based on level, activity, etc."""
        # Get current user info
        current_user = user_crud.get(db, id=user_id)
        if not current_user:
            return []

        # Get users with similar level (±2 levels)
        min_level = max(1, current_user.current_level - 2)
        max_level = current_user.current_level + 2

        # Get similar level users
        similar_users = user_crud.get_by_level_range(
            db,
            min_level=min_level,
            max_level=max_level,
            exclude_user_id=user_id,
            limit=limit * 2,
        )

        # Filter out existing friends and pending requests
        existing_friends = friend_crud.get_user_friends(db, user_id=user_id)
        friend_ids = {f.friend_user_id for f in existing_friends}

        # Get both sent and received pending requests
        sent_requests = friend_request_crud.get_user_requests(
            db, user_id=user_id, request_type="sent"
        )
        received_requests = friend_request_crud.get_user_requests(
            db, user_id=user_id, request_type="received"
        )

        # Extract user IDs from pending requests
        pending_ids = set()
        for req in sent_requests:
            if req.get("status") == "PENDING":
                pending_ids.add(req.get("receiver_id"))
        for req in received_requests:
            if req.get("status") == "PENDING":
                pending_ids.add(req.get("sender_id"))

        suggestions = []
        for user in similar_users:
            if user.id not in friend_ids and user.id not in pending_ids:
                # Calculate compatibility score based on multiple factors
                level_diff = abs(user.current_level - current_user.current_level)
                level_score = max(
                    0, 100 - (level_diff * 20)
                )  # Lower level diff = higher score

                # Activity similarity (based on recent logs)
                activity_score = 50  # Default base score

                # Total compatibility score
                compatibility_score = (level_score + activity_score) / 2

                suggestions.append(
                    {
                        "user_id": user.id,
                        "username": user.username,
                        "avatar_id": user.avatar_id,
                        "level": user.current_level,
                        "total_xp": user.total_xp,
                        "current_streak": user.current_streak,
                        "compatibility_score": round(compatibility_score, 1),
                        "common_interests": [
                            "hydration",
                            "health",
                        ],  # Default interests
                    }
                )

        # Sort by compatibility score
        suggestions.sort(key=lambda x: x["compatibility_score"], reverse=True)
        return suggestions[:limit]


# Global service instance
social_service = SocialService()
