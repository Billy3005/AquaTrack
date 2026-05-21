#!/usr/bin/env python3
"""
Debug StreakService directly
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'aquatrack_backend'))

def test_streak_service():
    """Test StreakService import and basic functionality"""
    try:
        from app.services.streak_service import StreakService
        print("OK StreakService imported successfully")

        # Test basic methods
        print("OK StreakService class created")
        return True
    except Exception as e:
        print(f"FAIL Import error: {e}")
        return False

def test_create_intake_log_without_streak():
    """Test creating intake log without streak logic to isolate the problem"""
    try:
        # Test basic intake log creation without streak
        import requests

        # Register user first
        register_data = {
            "email": "debug@example.com",
            "password": "password123",
            "username": "debuguser",
            "daily_goal_ml": 2000
        }

        BASE_URL = "http://localhost:8001/api/v1"

        # Try to register (ignore if user already exists)
        requests.post(f"{BASE_URL}/auth/register", json=register_data)

        # Then login
        login_data = {
            "email": "debug@example.com",
            "password": "password123"
        }

        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_response.status_code != 200:
            print(f"FAIL Login failed: {login_response.status_code}")
            return False

        token_data = login_response.json()
        access_token = token_data.get("access_token")

        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        # Test simple intake log creation (basic fields only)
        intake_data = {
            "volume_ml": 250,
            "liquid_type": "water",
            "source": "manual"
        }

        intake_response = requests.post(f"{BASE_URL}/intake/", json=intake_data, headers=headers)
        print(f"Intake log creation status: {intake_response.status_code}")

        if intake_response.status_code == 201:
            print("OK Basic intake log created successfully")
            result = intake_response.json()

            # Check if level_progress contains streak info
            if result.get("level_progress"):
                level_progress = result["level_progress"]
                print(f"Level progress: {level_progress}")

            return True
        else:
            print(f"FAIL Response: {intake_response.text}")
            return False

    except Exception as e:
        print(f"FAIL Error: {e}")
        return False

if __name__ == "__main__":
    print("Debug StreakService")
    print("=" * 30)

    print("\n1. Testing StreakService import...")
    test_streak_service()

    print("\n2. Testing intake log creation...")
    test_create_intake_log_without_streak()

    print("\n" + "=" * 30)
    print("Debug completed")