#!/usr/bin/env python3

import json

import requests


def test_register():
    url = "http://localhost:8004/api/v1/auth/register"
    data = {
        "email": "finaltest999@example.com",
        "password": "newpass123",
        "full_name": "New User",
    }

    print(f"Testing register endpoint: {url}")
    print(f"Request data: {json.dumps(data, indent=2)}")

    try:
        response = requests.post(url, json=data)
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")

        if response.status_code == 200:
            print(f"\n[SUCCESS] Registration successful!")
        else:
            print(f"\n[ERROR] Expected 200, got {response.status_code}")

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")


if __name__ == "__main__":
    test_register()
