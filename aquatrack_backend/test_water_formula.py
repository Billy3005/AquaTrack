#!/usr/bin/env python3

import requests
import json

BASE_URL = "http://localhost:8005/api/v1"

def test_water_formula_flow():
    """Test complete water formula flow"""

    # Step 1: Register a test user
    print("[INFO] Step 1: Registering test user...")
    register_data = {
        "email": "waterformula_test@example.com",
        "password": "testpass123",
        "full_name": "Water Formula Tester"
    }

    try:
        register_response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        print(f"Registration Status: {register_response.status_code}")

        if register_response.status_code == 200:
            auth_data = register_response.json()
            access_token = auth_data["access_token"]
            print(f"[SUCCESS] Registration successful! Token: {access_token[:20]}...")
        else:
            print(f"[ERROR] Registration failed: {register_response.text}")
            return
    except Exception as e:
        print(f"[ERROR] Registration error: {e}")
        return

    headers = {"Authorization": f"Bearer {access_token}"}

    # Step 2: Get water profile enums
    print("\n[INFO] Step 2: Getting water profile enums...")
    try:
        enums_response = requests.get(f"{BASE_URL}/water-profile/enums")
        print(f"Enums Status: {enums_response.status_code}")
        if enums_response.status_code == 200:
            enums = enums_response.json()
            print(f"[SUCCESS] Enums available: {list(enums.keys())}")
        else:
            print(f"[ERROR] Enums failed: {enums_response.text}")
    except Exception as e:
        print(f"[ERROR] Enums error: {e}")

    # Step 3: Get current water profile (should be empty)
    print("\n[INFO] Step 3: Getting current water profile...")
    try:
        profile_response = requests.get(f"{BASE_URL}/water-profile/", headers=headers)
        print(f"Profile Status: {profile_response.status_code}")
        if profile_response.status_code == 200:
            profile = profile_response.json()
            print(f"[SUCCESS] Current profile complete: {profile.get('profile_complete', False)}")
        else:
            print(f"[ERROR] Profile get failed: {profile_response.text}")
    except Exception as e:
        print(f"[ERROR] Profile get error: {e}")

    # Step 4: Update water profile with test data (from formula example)
    print("\n[INFO] Step 4: Updating water profile...")
    profile_data = {
        "gender": "male",
        "age": 28,
        "height": 168,
        "weight": 60.0,
        "activity_level": "moderate",
        "job_type": "office",
        "health_conditions": ["none"],
        "veggie_intake": "medium",
        "coffee_cups_per_day": 1,
        "alcohol_units_per_day": 0
    }

    try:
        update_response = requests.put(f"{BASE_URL}/water-profile/",
                                     json=profile_data, headers=headers)
        print(f"Update Status: {update_response.status_code}")
        if update_response.status_code == 200:
            updated_profile = update_response.json()
            print(f"[SUCCESS] Profile updated! Complete: {updated_profile.get('profile_complete', False)}")
            print(f"[CALC] Calculated goal: {updated_profile.get('calculated_daily_goal_ml', 'N/A')}ml")
        else:
            print(f"[ERROR] Profile update failed: {update_response.text}")
            return
    except Exception as e:
        print(f"[ERROR] Profile update error: {e}")
        return

    # Step 5: Calculate water intake manually
    print("\n[INFO] Step 5: Manual water calculation...")
    try:
        calc_response = requests.post(f"{BASE_URL}/water-profile/calculate", headers=headers)
        print(f"Calculation Status: {calc_response.status_code}")
        if calc_response.status_code == 200:
            calc_result = calc_response.json()
            print(f"[SUCCESS] Manual calculation successful!")
            print(f"[CALC] Total: {calc_result['total_ml']}ml")
            print(f"[CUPS] Cups: {calc_result['daily_goal_cups']} cups")
            print(f"[LITERS] Liters: {calc_result['daily_goal_l']}L")

            # Show breakdown
            breakdown = calc_result['breakdown']
            print(f"[BREAKDOWN] Breakdown:")
            print(f"  - Base: {breakdown['base_ml']}ml")
            print(f"  - Activity: {breakdown['activity_add']}ml")
            print(f"  - Job: {breakdown['job_add']}ml")
            print(f"  - Health: {breakdown['health_add']}ml")
            print(f"  - Veggie: {breakdown['veggie_add']}ml")
            print(f"  - Coffee: {breakdown['coffee_add']}ml")
            print(f"  - Alcohol: {breakdown['alcohol_add']}ml")

            if calc_result.get('has_warnings'):
                print(f"[WARNING] Warning: {calc_result.get('warning_message')}")

        else:
            print(f"[ERROR] Calculation failed: {calc_response.text}")
    except Exception as e:
        print(f"[ERROR] Calculation error: {e}")

    # Step 6: Get user summary
    print("\n[INFO] Step 6: Getting user summary...")
    try:
        summary_response = requests.get(f"{BASE_URL}/water-profile/summary", headers=headers)
        print(f"Summary Status: {summary_response.status_code}")
        if summary_response.status_code == 200:
            summary = summary_response.json()
            print(f"[SUCCESS] User summary for B5 screen:")
            print(f"  [USER] {summary['gender_age']}")
            print(f"  [SIZE] {summary['height_weight']}")
            print(f"  [ACTIVITY] {summary['activity']}")
            print(f"  [JOB] {summary['job']}")
        else:
            print(f"[ERROR] Summary failed: {summary_response.text}")
    except Exception as e:
        print(f"[ERROR] Summary error: {e}")

if __name__ == "__main__":
    print("Testing AquaTrack Water Formula API")
    print("=" * 50)
    test_water_formula_flow()