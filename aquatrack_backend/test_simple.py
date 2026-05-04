#!/usr/bin/env python3
"""
Test simple endpoint for CORS
"""

import requests

def test_simple():
    """Test simple endpoints"""

    print("=== Testing simple login endpoint ===")
    try:
        headers = {
            "Origin": "http://localhost:3000",
            "Content-Type": "application/json",
        }
        data = {
            "email": "demo@aquatrack.com",
            "password": "demo123"
        }
        response = requests.post("http://localhost:8002/simple-login",
                               json=data, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        print(f"CORS Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"Failed: {e}")

    print("\n=== Testing CORS test endpoint ===")
    try:
        headers = {"Origin": "http://localhost:3000"}
        response = requests.get("http://localhost:8002/cors-test",
                              headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        print(f"CORS Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_simple()