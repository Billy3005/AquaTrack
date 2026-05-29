#!/usr/bin/env python3

import json

import requests


def test_login():
    url = "http://localhost:8001/api/v1/auth/login"
    data = {"email": "test@example.com", "password": "testpass123"}

    print(f"Testing login endpoint: {url}")
    print(f"Request data: {json.dumps(data, indent=2)}")

    try:
        response = requests.post(url, json=data)
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")

        if response.status_code != 200:
            print(f"\nERROR: Expected 200, got {response.status_code}")

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")


if __name__ == "__main__":
    test_login()
