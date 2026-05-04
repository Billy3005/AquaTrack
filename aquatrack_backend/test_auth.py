#!/usr/bin/env python3
"""
Test authentication directly without API
"""

import sys
from pathlib import Path

# Add app directory to path
app_dir = Path(__file__).parent / "app"
sys.path.append(str(app_dir))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.crud.user import user_crud
from app.core.security import create_access_token, verify_password
from app.schemas.user import UserLogin

def test_authentication():
    """Test authentication logic directly"""
    print("Testing authentication logic...")
    db: Session = SessionLocal()

    try:
        # Test user exists
        user = user_crud.get_by_email(db, email="demo@aquatrack.com")
        if not user:
            print("FAIL: Demo user not found")
            return

        print(f"SUCCESS: User found: {user.email}")
        print(f"   ID: {user.id}")
        print(f"   Active: {user.is_active}")

        # Test password verification
        password = "demo123"
        print(f"\nTesting password verification...")
        print(f"   Plain password: {password}")
        print(f"   Hashed password: {user.hashed_password[:50]}...")

        password_valid = verify_password(password, user.hashed_password)
        print(f"   Password valid: {password_valid}")

        if password_valid:
            # Test token creation
            print(f"\nTesting JWT token creation...")
            access_token = create_access_token(subject=user.id)
            print(f"   Access token created: {access_token[:50]}...")
            print("SUCCESS: Authentication test passed!")
        else:
            print("FAIL: Password verification failed!")

    except Exception as e:
        print(f"ERROR: Authentication test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_authentication()