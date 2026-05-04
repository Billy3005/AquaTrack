#!/usr/bin/env python3
"""
Final test with fresh session
"""

import requests
import time

def test_final_auth():
    """Test authentication with fresh session"""

    # First check if server is running
    try:
        health_response = requests.get("http://localhost:8000/health", timeout=5)
        print(f"Health check: {health_response.status_code}")
        print(f"Health response: {health_response.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
        return

    # Add delay to ensure server is ready
    time.sleep(1)

    # Test login with new session
    session = requests.Session()
    url = "http://localhost:8000/api/v1/auth/login"
    headers = {
        "Content-Type": "application/json",
        "Cache-Control": "no-cache",
        "User-Agent": "FinalTest/1.0"
    }
    data = {
        "email": "demo@aquatrack.com",
        "password": "demo123"
    }

    print(f"\nTesting: {url}")
    print(f"Data: {data}")

    try:
        response = session.post(url, json=data, headers=headers, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        print(f"Response: {response.text}")

        # Parse response
        if response.text:
            try:
                json_resp = response.json()
                if "mock_access_token" in str(json_resp):
                    print("❌ STILL MOCK RESPONSE!")
                else:
                    print("✅ REAL RESPONSE!")
            except:
                pass

    except Exception as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    test_final_auth()