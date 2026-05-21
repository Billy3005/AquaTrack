#!/usr/bin/env python3
"""
Test script for streak functionality
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'aquatrack_backend'))

import requests
import json
from datetime import date, datetime

BASE_URL = "http://localhost:8001/api/v1"

def test_user_stats_api():
    """Test /users/stats endpoint to see current streak"""
    # First register user (ignore if already exists)
    register_data = {
        "email": "test@example.com",
        "password": "password123",
        "username": "testuser",
        "daily_goal_ml": 2000
    }

    try:
        # Try to register (ignore if user already exists)
        requests.post(f"{BASE_URL}/auth/register", json=register_data)

        # Then login to get token
        login_data = {
            "email": "test@example.com",
            "password": "password123"
        }

        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_response.status_code == 200:
            token_data = login_response.json()
            access_token = token_data.get("access_token")

            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }

            # Get user stats
            stats_response = requests.get(f"{BASE_URL}/users/stats", headers=headers)
            if stats_response.status_code == 200:
                stats = stats_response.json()
                print("OK User Stats API Response:")
                print(f"   Current Streak: {stats.get('current_streak', 0)} days")
                print(f"   Longest Streak: {stats.get('longest_streak', 0)} days")
                print(f"   Total XP: {stats.get('total_xp', 0)}")
                print(f"   Current Level: {stats.get('current_level', 1)}")
                return True
            else:
                print(f"FAIL Failed to get stats: {stats_response.status_code}")
                print(f"   Response: {stats_response.text}")
                return False
        else:
            print(f"FAIL Login failed: {login_response.status_code}")
            print(f"   Response: {login_response.text}")
            return False
    except requests.exceptions.ConnectionError:
        print("FAIL Cannot connect to backend server. Make sure it's running on http://localhost:8001")
        return False
    except Exception as e:
        print(f"FAIL Error: {e}")
        return False

def test_create_intake_log():
    """Test creating intake log and check if streak updates"""
    # Register user first
    register_data = {
        "email": "test@example.com",
        "password": "password123",
        "username": "testuser",
        "daily_goal_ml": 2000
    }

    try:
        # Try to register (ignore if user already exists)
        requests.post(f"{BASE_URL}/auth/register", json=register_data)

        # Then login
        login_data = {
            "email": "test@example.com",
            "password": "password123"
        }

        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_response.status_code != 200:
            print(f"FAIL Login failed: {login_response.status_code}")
            return False

        token_data = login_response.json()
        access_token = token_data.get("access_token")

        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        # Get current stats
        print("\n Getting current user stats...")
        stats_response = requests.get(f"{BASE_URL}/users/stats", headers=headers)
        if stats_response.status_code == 200:
            before_stats = stats_response.json()
            print(f"   Before - Streak: {before_stats.get('current_streak', 0)} days")

        # Create new intake log
        print("\n Creating intake log...")
        intake_data = {
            "volume_ml": 500,
            "liquid_type": "water",
            "temperature": "room",
            "location": "home",
            "mood_before": "normal",
            "source": "manual"
        }

        intake_response = requests.post(f"{BASE_URL}/intake/", json=intake_data, headers=headers)
        if intake_response.status_code == 201:
            intake_result = intake_response.json()
            print("OK Intake log created successfully")

            # Check level progress for streak info
            if intake_result.get("level_progress"):
                level_progress = intake_result["level_progress"]
                print(f"   Goal achieved today: {level_progress.get('goal_achieved_today', False)}")
                print(f"   Today total: {level_progress.get('today_total_ml', 0)}ml")
                print(f"   Daily goal: {level_progress.get('daily_goal_ml', 2000)}ml")
                print(f"   Current streak: {level_progress.get('current_streak', 0)} days")
        else:
            print(f"FAIL Failed to create intake log: {intake_response.status_code}")
            print(f"   Response: {intake_response.text}")
            return False

        # Get updated stats
        print("\n Getting updated user stats...")
        stats_response = requests.get(f"{BASE_URL}/users/stats", headers=headers)
        if stats_response.status_code == 200:
            after_stats = stats_response.json()
            print(f"   After - Streak: {after_stats.get('current_streak', 0)} days")

            # Check if streak changed
            before_streak = before_stats.get('current_streak', 0)
            after_streak = after_stats.get('current_streak', 0)

            if after_streak != before_streak:
                print(f"OK Streak updated: {before_streak} to {after_streak}")
            else:
                print(f"INFO Streak unchanged: {after_streak} (expected if goal not reached)")

        return True

    except Exception as e:
        print(f"FAIL Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing AquaTrack Streak Functionality")
    print("=" * 50)

    print("\n1. Testing User Stats API...")
    test_user_stats_api()

    print("\n2. Testing Intake Log Creation + Streak Update...")
    test_create_intake_log()

    print("\n" + "=" * 50)
    print("Test completed")