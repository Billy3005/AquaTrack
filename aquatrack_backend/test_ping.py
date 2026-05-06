#!/usr/bin/env python3
"""
Test ping endpoint to verify correct server
"""

import requests


def test_ping():
    """Test ping endpoint"""
    url = "http://localhost:8000/api/v1/ping"

    try:
        response = requests.get(url, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    test_ping()
