#!/usr/bin/env python3
"""
Test CORS configuration
"""

import requests


def test_cors():
    """Test CORS with proper headers"""

    # Test simple GET first
    print("=== Testing GET request ===")
    try:
        response = requests.get("http://localhost:8001/cors-test", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        print(f"Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"GET failed: {e}")

    print("\n=== Testing OPTIONS preflight ===")
    try:
        # Test preflight request
        headers = {
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type,Authorization",
        }
        response = requests.options(
            "http://localhost:8001/api/v1/auth/login", headers=headers, timeout=10
        )
        print(f"OPTIONS Status: {response.status_code}")
        print(f"CORS Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"OPTIONS failed: {e}")

    print("\n=== Testing POST login with CORS ===")
    try:
        # Test actual login with CORS headers
        headers = {
            "Origin": "http://localhost:3000",
            "Content-Type": "application/json",
        }
        data = {"email": "demo@aquatrack.com", "password": "demo123"}
        response = requests.post(
            "http://localhost:8001/api/v1/auth/login",
            json=data,
            headers=headers,
            timeout=10,
        )
        print(f"POST Status: {response.status_code}")
        print(f"Response: {response.text[:200]}...")
        print(f"CORS Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"POST failed: {e}")


if __name__ == "__main__":
    test_cors()
