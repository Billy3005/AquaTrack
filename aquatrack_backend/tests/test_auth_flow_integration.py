#!/usr/bin/env python3

import json

import requests

BASE_URL = "http://localhost:8000/api/v1"


def test_complete_flow():
    """Test complete registration -> onboarding -> profile flow"""

    print("Testing complete auth + profile flow...")

    # Step 1: Register new user
    print("\n1. Registering new user...")
    register_data = {
        "email": "test@aquatrack.com",
        "password": "123456",
        "username": "testuser",
    }

    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        print(f"   Registration status: {response.status_code}")

        if response.status_code == 200:
            auth_data = response.json()
            access_token = auth_data.get("access_token")
            user_data = auth_data.get("user", {})

            print(f"   User registered: {user_data.get('email')}")
            print(
                f"   Body info: gender={user_data.get('gender')}, age={user_data.get('age')}"
            )

            if not access_token:
                print("   ERROR: No access token returned")
                return

        else:
            print(f"   Registration failed: {response.text}")
            # Try to get existing user token if already registered
            print("\n   Trying login instead...")
            login_response = requests.post(
                f"{BASE_URL}/auth/login",
                json={
                    "email": register_data["email"],
                    "password": register_data["password"],
                },
            )
            if login_response.status_code == 200:
                auth_data = login_response.json()
                access_token = auth_data.get("access_token")
                print(f"   Login successful, got token")
            else:
                print(f"   Login also failed: {login_response.text}")
                return
    except Exception as e:
        print(f"   Registration error: {e}")
        return

    # Step 2: Update profile with body info (simulate onboarding)
    print("\n2. Submitting onboarding data...")
    headers = {"Authorization": f"Bearer {access_token}"}
    onboarding_data = {
        "gender": "male",
        "age": 30,
        "height": 175,
        "weight": 70.0,
        "activity_level": "moderate",
        "job_type": "office",
        "health_conditions": ["none"],
        "veggie_intake": "mid",
        "coffee_cups_per_day": 1,
        "alcohol_units_per_day": 0,
    }

    try:
        response = requests.put(
            f"{BASE_URL}/users/profile", json=onboarding_data, headers=headers
        )
        print(f"   Onboarding status: {response.status_code}")

        if response.status_code == 200:
            profile_data = response.json()
            print(f"   Profile updated: {profile_data.get('email')}")
            print(
                f"   Body info: gender={profile_data.get('gender')}, age={profile_data.get('age')}, height={profile_data.get('height')}"
            )
        else:
            print(f"   Onboarding failed: {response.text}")

    except Exception as e:
        print(f"   Onboarding error: {e}")

    # Step 3: Get profile data (simulate ProfileProvider)
    print("\n3. Getting profile data...")
    try:
        response = requests.get(f"{BASE_URL}/users/profile", headers=headers)
        print(f"   Profile fetch status: {response.status_code}")

        if response.status_code == 200:
            profile_data = response.json()
            print(f"   Profile data:")
            print(f"     Email: {profile_data.get('email')}")
            print(f"     Username: {profile_data.get('username')}")
            print(f"     Gender: {profile_data.get('gender')}")
            print(f"     Age: {profile_data.get('age')}")
            print(f"     Height: {profile_data.get('height')}")
            print(f"     Weight: {profile_data.get('weight')}")
            print(f"     Activity: {profile_data.get('activity_level')}")
            print(f"     Job: {profile_data.get('job_type')}")
            print(f"     Coffee: {profile_data.get('coffee_cups_per_day')}")
            print(f"     Alcohol: {profile_data.get('alcohol_units_per_day')}")
            print(f"     Complete Profile: {profile_data.get('profile_complete')}")

            # Test display formatting
            print(f"\n   Display formatting (Flutter style):")
            weight = profile_data.get("weight", 0)
            height = profile_data.get("height", 0)
            gender = profile_data.get("gender", "")
            age = profile_data.get("age", 0)
            activity = profile_data.get("activity_level", "")
            job = profile_data.get("job_type", "")
            coffee = profile_data.get("coffee_cups_per_day", 0)
            alcohol = profile_data.get("alcohol_units_per_day", 0)

            # Format like Flutter ProfileProvider
            weight_height = (
                f"{int(weight)} kg · {height} cm"
                if weight and height
                else "-- kg · -- cm"
            )
            gender_age_map = {"male": "Nam", "female": "Nu", "other": "Khac"}
            gender_age = (
                f"{gender_age_map.get(gender, '--')} · {age}"
                if gender and age
                else "-- · --"
            )
            activity_map = {
                "sedentary": "It van dong",
                "light": "Nhe nhang",
                "moderate": "Vua phai",
                "active": "Tich cuc",
                "very_active": "Rat tich cuc",
            }
            activity_display = activity_map.get(activity, "--")
            job_map = {
                "office": "Van phong",
                "mixed": "Hon hop",
                "outdoor": "Ngoai troi",
                "manual": "The luc",
            }
            job_display = job_map.get(job, "--")
            coffee_alcohol = f"{coffee} coc · {alcohol} don vi"

            print(f"     Weight-Height: {weight_height}")
            print(f"     Gender-Age: {gender_age}")
            print(f"     Activity Level: {activity_display}")
            print(f"     Job Type: {job_display}")
            print(f"     Coffee-Alcohol: {coffee_alcohol}")

        else:
            print(f"   Profile fetch failed: {response.text}")

    except Exception as e:
        print(f"   Profile fetch error: {e}")


if __name__ == "__main__":
    test_complete_flow()
