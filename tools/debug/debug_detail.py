#!/usr/bin/env python3
"""
Detailed debug for intake API
"""

import requests
import json

BASE_URL = "http://localhost:8001/api/v1"

def register_and_login():
    """Register and login to get valid token"""
    register_data = {
        "email": "detail@example.com",
        "password": "password123",
        "username": "detailuser"
    }

    # Register user
    reg_response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
    print(f"Register status: {reg_response.status_code}")
    if reg_response.status_code not in [200, 201, 409]:  # 409 = user exists
        print(f"Register response: {reg_response.text}")

    # Login
    login_data = {
        "email": "detail@example.com",
        "password": "password123"
    }

    login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Login status: {login_response.status_code}")

    if login_response.status_code == 200:
        token_data = login_response.json()
        return token_data.get("access_token")
    else:
        print(f"Login failed: {login_response.text}")
        return None

def test_minimal_intake_creation():
    """Test creating intake with minimal data"""
    token = register_and_login()
    if not token:
        return False

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Test 1: Minimal required data only
    print("\n=== Test 1: Minimal data ===")
    minimal_data = {
        "volume_ml": 250,
        "liquid_type": "water"
    }

    try:
        response = requests.post(f"{BASE_URL}/intake/", json=minimal_data, headers=headers)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:500]}")

        if response.status_code == 201:
            print("SUCCESS: Minimal intake created")
            return True
        else:
            print("FAIL: Minimal intake creation failed")

    except Exception as e:
        print(f"ERROR: {e}")

    # Test 2: Full data
    print("\n=== Test 2: Full data ===")
    full_data = {
        "volume_ml": 500,
        "liquid_type": "water",
        "temperature": "room",
        "location": "home",
        "mood_before": "normal",
        "source": "manual"
    }

    try:
        response = requests.post(f"{BASE_URL}/intake/", json=full_data, headers=headers)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:500]}")

        if response.status_code == 201:
            print("SUCCESS: Full intake created")
            return True
        else:
            print("FAIL: Full intake creation failed")

    except Exception as e:
        print(f"ERROR: {e}")

    return False

def test_other_endpoints():
    """Test other endpoints to verify API is working"""
    token = register_and_login()
    if not token:
        return

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    print("\n=== Testing other endpoints ===")

    # Test user profile
    response = requests.get(f"{BASE_URL}/users/profile", headers=headers)
    print(f"User profile: {response.status_code}")

    # Test user stats
    response = requests.get(f"{BASE_URL}/users/stats", headers=headers)
    print(f"User stats: {response.status_code}")

    # Test today's intake logs
    response = requests.get(f"{BASE_URL}/intake/today", headers=headers)
    print(f"Today's logs: {response.status_code}")

    # Test today's summary
    response = requests.get(f"{BASE_URL}/intake/summary/today", headers=headers)
    print(f"Today's summary: {response.status_code}")

if __name__ == "__main__":
    print("Detailed Intake API Debug")
    print("=" * 40)

    test_other_endpoints()
    test_minimal_intake_creation()

    print("\nDebug completed")