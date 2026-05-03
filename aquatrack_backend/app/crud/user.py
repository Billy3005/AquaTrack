from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.crud.base import CRUDBase
from app.models.achievement import Achievement
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate


class CRUDUser(CRUDBase[User, UserCreate, UserUpdate]):
    """CRUD operations for User model"""

    def get_by_email(self, db: Session, *, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()

    def get_by_username(self, db: Session, *, username: str) -> Optional[User]:
        """Get user by username"""
        return db.query(User).filter(User.username == username).first()

    def create(self, db: Session, *, obj_in: UserCreate) -> User:
        """Create new user with hashed password and default achievements"""
        db_obj = User(
            email=obj_in.email,
            hashed_password=get_password_hash(obj_in.password),
            username=obj_in.username or "Aqua Warrior",
            full_name=obj_in.full_name,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)

        # Create default achievements for new user
        default_achievements = Achievement.create_default_achievements(db_obj.id)
        for achievement in default_achievements:
            db.add(achievement)

        db.commit()
        return db_obj

    def authenticate(self, db: Session, *, email: str, password: str) -> Optional[User]:
        """Authenticate user with email and password"""
        user = self.get_by_email(db, email=email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    def is_active(self, user: User) -> bool:
        """Check if user is active"""
        return user.is_active

    def update_last_login(self, db: Session, *, user_id: str) -> None:
        """Update user's last login timestamp"""
        db.query(User).filter(User.id == user_id).update({"last_login": func.now()})
        db.commit()

    def update_stats(
        self,
        db: Session,
        *,
        user_id: str,
        xp_gained: int = 0,
        volume_ml: int = 0,
        new_level: Optional[int] = None,
        new_streak: Optional[int] = None
    ) -> User:
        """Update user statistics (XP, volume, level, streak)"""
        user = self.get(db, user_id)
        if not user:
            return None

        # Update stats
        user.total_xp += xp_gained
        user.total_volume_ml += volume_ml
        user.total_logs_count += 1 if volume_ml > 0 else 0

        if new_level is not None:
            user.current_level = new_level

        if new_streak is not None:
            user.current_streak = new_streak
            user.longest_streak = max(user.longest_streak, new_streak)

        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def update_preferences(
        self, db: Session, *, user_id: str, preferences: dict
    ) -> User:
        """Update user preferences (settings)"""
        user = self.get(db, user_id)
        if not user:
            return None

        for key, value in preferences.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)

        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def deactivate(self, db: Session, *, user_id: str) -> User:
        """Deactivate user account"""
        user = self.get(db, user_id)
        if user:
            user.is_active = False
            db.add(user)
            db.commit()
            db.refresh(user)
        return user

    def reactivate(self, db: Session, *, user_id: str) -> User:
        """Reactivate user account"""
        user = self.get(db, user_id)
        if user:
            user.is_active = True
            db.add(user)
            db.commit()
            db.refresh(user)
        return user


# Global instance
user_crud = CRUDUser(User)
