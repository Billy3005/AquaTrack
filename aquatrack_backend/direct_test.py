#!/usr/bin/env python3
"""
Direct test authentication without server cache
"""

from app.core.database import SessionLocal, init_db
from app.crud.user import user_crud
from app.schemas.user import UserCreate

def test_direct_auth():
    """Test authentication directly via database"""

    # Initialize database
    init_db()

    # Create database session
    db = SessionLocal()

    try:
        # Test 1: Check if demo user exists
        demo_user = user_crud.get_by_email(db, email="demo@aquatrack.com")
        print(f"Demo user exists: {demo_user is not None}")
        if demo_user:
            print(f"Demo user ID: {demo_user.id}")
            print(f"Demo user email: {demo_user.email}")
            print(f"Demo user active: {demo_user.is_active}")

        # Test 2: Try authentication
        authenticated_user = user_crud.authenticate(db, email="demo@aquatrack.com", password="demo123")
        print(f"\nAuthentication result: {authenticated_user is not None}")
        if authenticated_user:
            print(f"Authenticated user ID: {authenticated_user.id}")
        else:
            print("Authentication failed!")

        # Test 3: Create new test user
        test_user_data = UserCreate(
            email="direct_test@aquatrack.com",
            password="test123",
            username="directtest",
            full_name="Direct Test User"
        )

        # Check if test user already exists
        existing_test = user_crud.get_by_email(db, email="direct_test@aquatrack.com")
        if existing_test:
            print(f"\nTest user already exists: {existing_test.email}")
        else:
            new_user = user_crud.create(db, obj_in=test_user_data)
            print(f"\nNew test user created: {new_user.email} (ID: {new_user.id})")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_direct_auth()