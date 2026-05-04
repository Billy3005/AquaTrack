#!/usr/bin/env python3
"""
Create demo user for testing authentication
"""

import sys
from pathlib import Path

# Add app directory to path
app_dir = Path(__file__).parent / "app"
sys.path.append(str(app_dir))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal, init_db
from app.crud.user import user_crud
from app.schemas.user import UserCreate

def create_demo_user():
    """Create demo user for testing"""
    print("Initializing database...")
    init_db()

    print("Creating demo user...")
    db: Session = SessionLocal()

    try:
        # Check if demo user already exists
        existing_user = user_crud.get_by_email(db, email="demo@aquatrack.com")
        if existing_user:
            print("Demo user already exists!")
            print(f"  Email: {existing_user.email}")
            print(f"  ID: {existing_user.id}")
            return

        # Create demo user
        user_create = UserCreate(
            email="demo@aquatrack.com",
            password="demo123",
            username="demo",
            full_name="Demo User"
        )

        user = user_crud.create(db, obj_in=user_create)
        print("Demo user created successfully!")
        print(f"  Email: {user.email}")
        print(f"  Username: {user.username}")
        print(f"  ID: {user.id}")

    except Exception as e:
        print(f"Error creating demo user: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    create_demo_user()