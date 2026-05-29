#!/usr/bin/env python3

import json

import requests

BASE_URL = "http://localhost:8005/api/v1"


def test_summary():
    # Register new user
    register_data = {
        "email": "summary_test2@example.com",
        "password": "testpass123",
        "full_name": "Summary Tester",
    }

    register_response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
    if register_response.status_code != 200:
        print(f"Registration failed: {register_response.text}")
        return

    auth_data = register_response.json()
    access_token = auth_data["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Update profile (complete)
    profile_data = {
        "gender": "male",
        "age": 28,
        "height": 168,
        "weight": 60.0,
        "activity_level": "moderate",
        "job_type": "office",
        "veggie_intake": "medium",
        "health_conditions": ["none"],
        "coffee_cups_per_day": 1,
        "alcohol_units_per_day": 0,
    }

    requests.put(f"{BASE_URL}/water-profile/", json=profile_data, headers=headers)

    # Test summary
    summary_response = requests.get(
        f"{BASE_URL}/water-profile/summary", headers=headers
    )
    print(f"Summary Status: {summary_response.status_code}")

    if summary_response.status_code == 200:
        summary = summary_response.json()
        print(f"Summary data: {summary}")
        print("SUCCESS: Summary endpoint working!")
    else:
        print(f"Summary error status code: {summary_response.status_code}")


if __name__ == "__main__":
    test_summary()
