#!/usr/bin/env python3

import json
import random
import string

import requests

BASE_URL = "http://localhost:8000/api/v1"


def test_create_user_and_profile():
    """Create new user, complete onboarding, then test profile API"""

    # Generate random user
    random_suffix = "".join(random.choices(string.ascii_lowercase, k=3))
    email = f"test{random_suffix}@aquatrack.com"
    password = "123456"
    username = f"test{random_suffix}"

    print(f"Testing with new user: {email}")

    # Step 1: Register new user
    print("\n1. Registering new user...")
    register_data = {"email": email, "password": password, "username": username}

    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        print(f"   Registration status: {response.status_code}")

        if response.status_code == 200:
            auth_data = response.json()
            access_token = auth_data.get("access_token")
            print(
                f"   User registered and logged in: {auth_data.get('user', {}).get('email')}"
            )
        else:
            print(f"   Registration failed: {response.text}")
            return

    except Exception as e:
        print(f"   Registration error: {e}")
        return

    # Step 2: Submit onboarding data
    print("\n2. Submitting onboarding data...")
    headers = {"Authorization": f"Bearer {access_token}"}
    onboarding_data = {
        "gender": "male",
        "age": 25,
        "height": 175,
        "weight": 70.0,
        "activity_level": "moderate",
        "job_type": "office",
        "health_conditions": ["none"],
        "veggie_intake": "mid",
        "coffee_cups_per_day": 2,
        "alcohol_units_per_day": 1,
    }

    try:
        response = requests.put(
            f"{BASE_URL}/users/profile", json=onboarding_data, headers=headers
        )
        print(f"   Onboarding status: {response.status_code}")

        if response.status_code == 200:
            print(f"   ✅ Onboarding completed successfully")
        else:
            print(f"   ❌ Onboarding failed: {response.text}")
            return

    except Exception as e:
        print(f"   ❌ Onboarding error: {e}")
        return

    # Step 3: Test /users/profile endpoint
    print("\n3. Testing /users/profile endpoint...")

    try:
        response = requests.get(f"{BASE_URL}/users/profile", headers=headers)
        print(f"   Profile API status: {response.status_code}")

        if response.status_code == 200:
            profile_data = response.json()
            print(f"\n   ✅ Profile API Response:")
            print(
                f"   Full JSON: {json.dumps(profile_data, indent=2, ensure_ascii=False)}"
            )

            # Check body fields specifically
            print(f"\n   📊 Body Data Check:")
            print(f"   - gender: {profile_data.get('gender', 'MISSING')}")
            print(f"   - age: {profile_data.get('age', 'MISSING')}")
            print(f"   - height: {profile_data.get('height', 'MISSING')}")
            print(f"   - weight: {profile_data.get('weight', 'MISSING')}")
            print(
                f"   - activity_level: {profile_data.get('activity_level', 'MISSING')}"
            )
            print(f"   - job_type: {profile_data.get('job_type', 'MISSING')}")
            print(
                f"   - health_conditions: {profile_data.get('health_conditions', 'MISSING')}"
            )
            print(
                f"   - coffee_cups_per_day: {profile_data.get('coffee_cups_per_day', 'MISSING')}"
            )
            print(
                f"   - alcohol_units_per_day: {profile_data.get('alcohol_units_per_day', 'MISSING')}"
            )

            # Test null values
            print(f"\n   🔍 Null Check:")
            null_fields = []
            for field in [
                "gender",
                "age",
                "height",
                "weight",
                "activity_level",
                "job_type",
                "coffee_cups_per_day",
                "alcohol_units_per_day",
            ]:
                if profile_data.get(field) is None:
                    null_fields.append(field)

            if null_fields:
                print(f"   ❌ Null fields found: {null_fields}")
            else:
                print(f"   ✅ No null fields - all body data present!")

        else:
            print(f"   ❌ Profile API failed: {response.status_code}")
            print(f"   Response: {response.text}")

    except Exception as e:
        print(f"   ❌ Profile API error: {e}")


if __name__ == "__main__":
    test_create_user_and_profile()
