#!/usr/bin/env python3
"""
Test register endpoint
"""

import json

import requests


def test_register_api():
    """Test register API endpoint"""
    url = "http://localhost:8000/api/v1/auth/register"
    headers = {"Content-Type": "application/json"}
    data = {
        "email": "test@aquatrack.com",
        "password": "test123",
        "username": "testuser",
        "full_name": "Test User",
    }

    print(f"Testing POST {url}")
    print(f"Data: {json.dumps(data, indent=2)}")

    try:
        response = requests.post(url, json=data, headers=headers, timeout=10)
        print(f"\nResponse Status: {response.status_code}")

        if response.text:
            print(f"Response Body: {response.text}")
        else:
            print("Response Body: (empty)")

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")


if __name__ == "__main__":
    test_register_api()
