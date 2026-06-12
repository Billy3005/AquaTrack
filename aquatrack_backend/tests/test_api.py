#!/usr/bin/env python3
"""
Test API endpoint directly
"""

import json

import requests


def test_login_api():
    """Test login API endpoint"""
    url = "http://localhost:8000/api/v1/auth/login"
    headers = {"Content-Type": "application/json"}
    data = {"email": "demo@aquatrack.com", "password": "demo123"}

    print(f"Testing POST {url}")
    print(f"Headers: {headers}")
    print(f"Data: {json.dumps(data, indent=2)}")

    try:
        response = requests.post(url, json=data, headers=headers, timeout=10)
        print(f"\nResponse Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")

        if response.text:
            print(f"Response Body: {response.text}")
        else:
            print("Response Body: (empty)")

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")


if __name__ == "__main__":
    test_login_api()
