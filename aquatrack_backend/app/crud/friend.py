from datetime import date, datetime, timedelta
from typing import List, Optional, Tuple

from sqlalchemy import and_, desc, func, or_
from sqlalchemy.orm import Session, aliased, joinedload

from app.crud.base import CRUDBase
from app.models.friend import Friend
from app.models.friend_request import FriendRequest, FriendRequestStatus
from app.models.leaderboard import LeaderboardEntry
from app.models.user import User
from app.schemas.social import FriendRequestCreate, FriendRequestUpdate


class CRUDFriend(CRUDBase[Friend, dict, dict]):
    """CRUD operations for Friend model"""

    def create_friendship(
        self, db: Session, *, user_id: str, friend_user_id: str
    ) -> Tuple[Friend, Friend]:
        """
        Create mutual friendship between two users
        Returns both Friend records (bidirectional)
        """
        # Create friendship from user to friend
        friend1 = Friend(user_id=user_id, friend_user_id=friend_user_id)
        # Create friendship from friend to user (mutual)
        friend2 = Friend(user_id=friend_user_id, friend_user_id=user_id)

        db.add(friend1)
        db.add(friend2)
        db.commit()
        db.refresh(friend1)
        db.refresh(friend2)

        return friend1, friend2

    def get_user_friends(
        self, db: Session, *, user_id: str, skip: int = 0, limit: int = 100
    ) -> List[dict]:
        """Get user's friends with additional info for UI"""
        FriendUser = aliased(User)

        friends = (
            db.query(Friend, FriendUser)
            .join(FriendUser, Friend.friend_user_id == FriendUser.id)
            .filter(
                and_(
                    Friend.user_id == user_id,
                    Friend.is_active == True,
                    Friend.is_blocked == False,
                )
            )
            .options(joinedload(Friend.user))
            .offset(skip)
            .limit(limit)
            .all()
        )

        result = []
        for friend, friend_user in friends:
            # Calculate friendship duration
            friendship_duration = (datetime.utcnow() - friend.created_at).days

            result.append({
                "id": friend.id,
                "user_id": friend.user_id,
                "friend_user_id": friend.friend_user_id,
                "is_active": friend.is_active,
                "is_blocked": friend.is_blocked,
                "created_at": friend.created_at,
                "friend_username": friend_user.username,
                "friend_avatar_id": friend_user.avatar_id,
                "friend_current_level": friend_user.current_level,
                "friend_total_xp": friend_user.total_xp,
                "friendship_duration_days": friendship_duration,
                "last_seen": friend_user.last_login,
            })

        return result

    def remove_friendship(self, db: Session, *, user_id: str, friend_user_id: str) -> bool:
        """Remove mutual friendship between two users"""
        # Remove both directions of friendship
        removed_count = (
            db.query(Friend)
            .filter(
                or_(
                    and_(Friend.user_id == user_id, Friend.friend_user_id == friend_user_id),
                    and_(Friend.user_id == friend_user_id, Friend.friend_user_id == user_id),
                )
            )
            .delete(synchronize_session=False)
        )

        db.commit()
        return removed_count > 0

    def block_user(self, db: Session, *, user_id: str, blocked_user_id: str) -> bool:
        """Block a user (removes friendship and prevents future requests)"""
        # Remove existing friendship if any
        self.remove_friendship(db, user_id=user_id, friend_user_id=blocked_user_id)

        # Create blocked relationship
        blocked_friend = Friend(
            user_id=user_id,
            friend_user_id=blocked_user_id,
            is_active=False,
            is_blocked=True,
        )

        db.add(blocked_friend)
        db.commit()
        db.refresh(blocked_friend)

        return True

    def unblock_user(self, db: Session, *, user_id: str, blocked_user_id: str) -> bool:
        """Unblock a user"""
        removed_count = (
            db.query(Friend)
            .filter(
                and_(
                    Friend.user_id == user_id,
                    Friend.friend_user_id == blocked_user_id,
                    Friend.is_blocked == True,
                )
            )
            .delete(synchronize_session=False)
        )

        db.commit()
        return removed_count > 0

    def are_friends(self, db: Session, *, user_id: str, other_user_id: str) -> bool:
        """Check if two users are friends"""
        friendship = (
            db.query(Friend)
            .filter(
                and_(
                    Friend.user_id == user_id,
                    Friend.friend_user_id == other_user_id,
                    Friend.is_active == True,
                    Friend.is_blocked == False,
                )
            )
            .first()
        )

        return friendship is not None

    def is_blocked(self, db: Session, *, user_id: str, other_user_id: str) -> bool:
        """Check if user has blocked another user"""
        blocked = (
            db.query(Friend)
            .filter(
                and_(
                    Friend.user_id == user_id,
                    Friend.friend_user_id == other_user_id,
                    Friend.is_blocked == True,
                )
            )
            .first()
        )

        return blocked is not None

    def search_users(
        self, db: Session, *, query: str, current_user_id: str, limit: int = 20
    ) -> List[dict]:
        """Search for users by username"""
        users = (
            db.query(User)
            .filter(
                and_(
                    User.id != current_user_id,  # Don't include current user
                    User.is_active == True,
                    or_(
                        User.username.ilike(f"%{query}%"),
                        User.full_name.ilike(f"%{query}%"),
                    ),
                )
            )
            .limit(limit)
            .all()
        )

        result = []
        for user in users:
            # Check friendship status
            is_friend = self.are_friends(db, user_id=current_user_id, other_user_id=user.id)

            # Check pending requests
            has_pending_request = friend_request_crud.has_pending_request(
                db, sender_id=current_user_id, receiver_id=user.id
            ) or friend_request_crud.has_pending_request(
                db, sender_id=user.id, receiver_id=current_user_id
            )

            result.append({
                "id": user.id,
                "username": user.username,
                "avatar_id": user.avatar_id,
                "current_level": user.current_level,
                "total_xp": user.total_xp,
                "is_already_friend": is_friend,
                "has_pending_request": has_pending_request,
            })

        return result


class CRUDFriendRequest(CRUDBase[FriendRequest, FriendRequestCreate, FriendRequestUpdate]):
    """CRUD operations for FriendRequest model"""

    def create_request(
        self, db: Session, *, sender_id: str, obj_in: FriendRequestCreate
    ) -> FriendRequest:
        """Create a friend request"""
        # Check if users are already friends
        if friend_crud.are_friends(db, user_id=sender_id, other_user_id=obj_in.receiver_id):
            raise ValueError("Users are already friends")

        # Check if sender is blocked by receiver
        if friend_crud.is_blocked(db, user_id=obj_in.receiver_id, other_user_id=sender_id):
            raise ValueError("Cannot send friend request to this user")

        # Check for existing pending request
        existing_request = (
            db.query(FriendRequest)
            .filter(
                and_(
                    or_(
                        and_(
                            FriendRequest.sender_id == sender_id,
                            FriendRequest.receiver_id == obj_in.receiver_id,
                        ),
                        and_(
                            FriendRequest.sender_id == obj_in.receiver_id,
                            FriendRequest.receiver_id == sender_id,
                        ),
                    ),
                    FriendRequest.status == FriendRequestStatus.PENDING,
                )
            )
            .first()
        )

        if existing_request:
            raise ValueError("A pending friend request already exists between these users")

        request_data = obj_in.model_dump()
        request_data["sender_id"] = sender_id

        db_obj = FriendRequest(**request_data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)

        return db_obj

    def get_user_requests(
        self,
        db: Session,
        *,
        user_id: str,
        request_type: str = "received",  # "sent" or "received"
        skip: int = 0,
        limit: int = 100,
    ) -> List[dict]:
        """Get user's friend requests with additional info"""
        if request_type == "received":
            filter_condition = FriendRequest.receiver_id == user_id
            other_user_attr = "sender"
            other_user_id_attr = "sender_id"
        else:  # sent
            filter_condition = FriendRequest.sender_id == user_id
            other_user_attr = "receiver"
            other_user_id_attr = "receiver_id"

        requests = (
            db.query(FriendRequest)
            .filter(
                and_(
                    filter_condition,
                    FriendRequest.status == FriendRequestStatus.PENDING,
                )
            )
            .options(
                joinedload(FriendRequest.sender),
                joinedload(FriendRequest.receiver),
            )
            .order_by(desc(FriendRequest.created_at))
            .offset(skip)
            .limit(limit)
            .all()
        )

        result = []
        for request in requests:
            other_user = getattr(request, other_user_attr)

            result.append({
                "id": request.id,
                "sender_id": request.sender_id,
                "receiver_id": request.receiver_id,
                "status": request.status,
                "message": request.message,
                "created_at": request.created_at,
                "updated_at": request.updated_at,
                "responded_at": request.responded_at,
                # Other user info
                "sender_username": request.sender.username if request.sender else None,
                "sender_avatar_id": request.sender.avatar_id if request.sender else None,
                "receiver_username": request.receiver.username if request.receiver else None,
                "receiver_avatar_id": request.receiver.avatar_id if request.receiver else None,
            })

        return result

    def accept_request(self, db: Session, *, request_id: str, user_id: str) -> FriendRequest:
        """Accept a friend request and create friendship"""
        request = self.get(db, id=request_id)
        if not request:
            raise ValueError("Friend request not found")

        if request.receiver_id != user_id:
            raise ValueError("Only the receiver can accept this request")

        if request.status != FriendRequestStatus.PENDING:
            raise ValueError("Request is not pending")

        # Accept the request
        request.accept()

        # Create mutual friendship
        friend_crud.create_friendship(
            db, user_id=request.sender_id, friend_user_id=request.receiver_id
        )

        db.commit()
        db.refresh(request)

        return request

    def decline_request(self, db: Session, *, request_id: str, user_id: str) -> FriendRequest:
        """Decline a friend request"""
        request = self.get(db, id=request_id)
        if not request:
            raise ValueError("Friend request not found")

        if request.receiver_id != user_id:
            raise ValueError("Only the receiver can decline this request")

        if request.status != FriendRequestStatus.PENDING:
            raise ValueError("Request is not pending")

        # Decline the request
        request.decline()

        db.commit()
        db.refresh(request)

        return request

    def cancel_request(self, db: Session, *, request_id: str, user_id: str) -> FriendRequest:
        """Cancel a friend request (by sender)"""
        request = self.get(db, id=request_id)
        if not request:
            raise ValueError("Friend request not found")

        if request.sender_id != user_id:
            raise ValueError("Only the sender can cancel this request")

        if request.status != FriendRequestStatus.PENDING:
            raise ValueError("Request is not pending")

        # Cancel the request
        request.cancel()

        db.commit()
        db.refresh(request)

        return request

    def has_pending_request(
        self, db: Session, *, sender_id: str, receiver_id: str
    ) -> bool:
        """Check if there's a pending request between users"""
        request = (
            db.query(FriendRequest)
            .filter(
                and_(
                    FriendRequest.sender_id == sender_id,
                    FriendRequest.receiver_id == receiver_id,
                    FriendRequest.status == FriendRequestStatus.PENDING,
                )
            )
            .first()
        )

        return request is not None


# Global instances
friend_crud = CRUDFriend(Friend)
friend_request_crud = CRUDFriendRequest(FriendRequest)