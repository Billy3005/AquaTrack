#!/usr/bin/env python3

import json

import requests

BASE_URL = "http://localhost:8000/api/v1"


def test_login():
    """Test login API with existing users"""

    # Test users from database
    test_accounts = [
        {"email": "aaaaa@gmail.com", "password": "123456"},
        {"email": "3q@gamil.com", "password": "123456"},
        {"email": "md@gmail.com", "password": "123456"},
    ]

    for account in test_accounts:
        print(f"\n=== Testing login: {account['email']} ===")

        try:
            response = requests.post(f"{BASE_URL}/auth/login", json=account)
            print(f"Status: {response.status_code}")

            if response.status_code == 200:
                data = response.json()
                print(f"[OK] Login successful!")
                print(f"   Access token: {data.get('access_token', 'Missing')[:50]}...")
                print(f"   User: {data.get('user', {}).get('email', 'Missing')}")
                return True
            else:
                print(f"[FAIL] Login failed: {response.text}")

        except Exception as e:
            print(f"[FAIL] Error: {e}")

    return False


def test_register():
    """Test registration API"""
    print(f"\n=== Testing registration ===")

    # Generate unique username
    import random

    random_suffix = random.randint(1000, 9999)
    register_data = {
        "email": f"debug{random_suffix}@test.com",
        "password": "123456",
        "username": f"debug{random_suffix}",
    }

    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        print(f"Status: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Registration successful!")
            print(f"   Access token: {data.get('access_token', 'Missing')[:50]}...")
            return True
        else:
            print(f"[FAIL] Registration failed: {response.text}")

    except Exception as e:
        print(f"[FAIL] Error: {e}")

    return False


if __name__ == "__main__":
    print("Testing AquaTrack Authentication...")

    # Test login first
    login_success = test_login()

    if not login_success:
        # Try registration if login fails
        register_success = test_register()

        if register_success:
            print(f"\n[OK] Use newly registered account: testuser@test.com / 123456")
        else:
            print(f"\n[FAIL] Both login and registration failed!")
    else:
        print(f"\n[OK] Authentication is working!")
