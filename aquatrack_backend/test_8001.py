#!/usr/bin/env python3
"""
Test authentication on port 8001
"""

import requests


def test_auth_8001():
    """Test on port 8001"""

    # Test login
    url = "http://localhost:8001/api/v1/auth/login"
    data = {"email": "demo@aquatrack.com", "password": "demo123"}

    print(f"Testing: {url}")

    try:
        response = requests.post(url, json=data, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")

        if "NEW_REAL_TOKEN_123" in response.text:
            print("SUCCESS! NEW ENDPOINT WORKING!")
        elif "mock_access_token" in response.text:
            print("STILL MOCK!")
        else:
            print("UNKNOWN RESPONSE")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    test_auth_8001()
