#!/usr/bin/env python3
"""
Create test user for stats integration testing
"""
import requests
import json

# Configuration
BACKEND_URL = "http://127.0.0.1:8000"

def create_test_user():
    """Create a test user via registration API"""

    test_user_data = {
        "email": "giabao3052005@gmail.com",
        "username": "giabao_test",
        "password": "password123",
        "full_name": "Gia Bao Test User",
        "daily_goal_ml": 2000
    }

    try:
        print("Creating test user...")
        print(f"Email: {test_user_data['email']}")
        print(f"Username: {test_user_data['username']}")

        response = requests.post(
            f"{BACKEND_URL}/api/v1/auth/register",
            json=test_user_data,
            timeout=10
        )

        print(f"Registration status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("[PASS] Test user created successfully!")
            print(f"User ID: {result.get('user', {}).get('id')}")
            print(f"Access Token: {result.get('access_token')[:50]}...")
            return True
        else:
            print(f"[FAIL] Registration failed: {response.text}")
            return False

    except Exception as e:
        print(f"[ERROR] Registration error: {e}")
        return False

def test_login():
    """Test login with newly created user"""

    login_data = {
        "email": "giabao3052005@gmail.com",
        "password": "password123"
    }

    try:
        print("\nTesting login...")

        response = requests.post(
            f"{BACKEND_URL}/api/v1/auth/login",
            json=login_data,
            timeout=5
        )

        print(f"Login status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("[PASS] Login successful!")
            print(f"Access Token: {result.get('access_token')[:50]}...")
            return result.get('access_token')
        else:
            print(f"[FAIL] Login failed: {response.text}")
            return None

    except Exception as e:
        print(f"[ERROR] Login error: {e}")
        return None

def main():
    """Create user and test login"""
    print("=== Test User Creation ===")

    # Try registration first
    success = create_test_user()

    if success:
        # Test login
        token = test_login()
        if token:
            print("\n[SUCCESS] Test user ready for integration tests!")
        else:
            print("\n[WARN] User created but login failed")
    else:
        # If registration fails, try login (user might exist)
        print("\nRegistration failed, trying login...")
        token = test_login()
        if token:
            print("\n[SUCCESS] Existing user works for integration tests!")
        else:
            print("\n[FAIL] Neither registration nor login worked")

if __name__ == "__main__":
    main()