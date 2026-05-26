#!/usr/bin/env python3

import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_profile_api_for_user():
    """Test /users/profile API endpoint for user dcd@gmail.com"""

    print("Testing /users/profile API for user dcd@gmail.com...")

    # Step 1: Login to get access token
    print("\n1. Login to get access token...")
    login_data = {
        "email": "lkj@gmail.com",
        "password": "123456"
    }

    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        print(f"   Login status: {response.status_code}")

        if response.status_code == 200:
            auth_data = response.json()
            access_token = auth_data.get("access_token")
            print(f"   Login successful, got token")
        else:
            print(f"   Login failed: {response.text}")
            return

    except Exception as e:
        print(f"   Login error: {e}")
        return

    # Step 2: Test /users/profile endpoint
    print("\n2. Testing /users/profile endpoint...")
    headers = {"Authorization": f"Bearer {access_token}"}

    try:
        response = requests.get(f"{BASE_URL}/users/profile", headers=headers)
        print(f"   Profile API status: {response.status_code}")

        if response.status_code == 200:
            profile_data = response.json()
            print(f"\n   ✅ Profile API Response:")
            print(f"   Full JSON: {json.dumps(profile_data, indent=2, ensure_ascii=False)}")

            # Check body fields specifically
            print(f"\n   📊 Body Data Check:")
            print(f"   - gender: {profile_data.get('gender', 'MISSING')}")
            print(f"   - age: {profile_data.get('age', 'MISSING')}")
            print(f"   - height: {profile_data.get('height', 'MISSING')}")
            print(f"   - weight: {profile_data.get('weight', 'MISSING')}")
            print(f"   - activity_level: {profile_data.get('activity_level', 'MISSING')}")
            print(f"   - job_type: {profile_data.get('job_type', 'MISSING')}")
            print(f"   - health_conditions: {profile_data.get('health_conditions', 'MISSING')}")
            print(f"   - coffee_cups_per_day: {profile_data.get('coffee_cups_per_day', 'MISSING')}")
            print(f"   - alcohol_units_per_day: {profile_data.get('alcohol_units_per_day', 'MISSING')}")

        else:
            print(f"   ❌ Profile API failed: {response.status_code}")
            print(f"   Response: {response.text}")

    except Exception as e:
        print(f"   ❌ Profile API error: {e}")

if __name__ == "__main__":
    test_profile_api_for_user()