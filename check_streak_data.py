#!/usr/bin/env python3
"""
Check streak data in database and API
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'aquatrack_backend'))

import requests
from datetime import date, datetime

def check_backend_data():
    """Check what data exists in backend"""
    BASE_URL = "http://localhost:8001/api/v1"

    # Login with existing user
    login_data = {
        "email": "test@example.com",
        "password": "password123"
    }

    try:
        login_resp = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_resp.status_code != 200:
            print("FAIL Cannot login - no test user exists")
            return

        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        print("=== BACKEND DATA CHECK ===")

        # 1. Check user stats (includes streak)
        stats_resp = requests.get(f"{BASE_URL}/users/stats", headers=headers)
        if stats_resp.status_code == 200:
            stats = stats_resp.json()
            print(f"OK User Stats:")
            print(f"   Current Streak: {stats.get('current_streak', 'N/A')} days")
            print(f"   Longest Streak: {stats.get('longest_streak', 'N/A')} days")
            print(f"   Total Logs: {stats.get('total_logs_count', 'N/A')}")
            print(f"   Total Volume: {stats.get('total_volume_ml', 'N/A')}ml")
        else:
            print(f"FAIL Failed to get user stats: {stats_resp.status_code}")

        # 2. Check today's intake logs
        today_resp = requests.get(f"{BASE_URL}/intake/today", headers=headers)
        if today_resp.status_code == 200:
            today_logs = today_resp.json()
            print(f"\nOK Today's Intake Logs ({len(today_logs)} entries):")
            total_today = 0
            for log in today_logs:
                volume = log.get('effective_volume_ml', log.get('volume_ml', 0))
                total_today += volume
                print(f"   - {log.get('volume_ml')}ml {log.get('liquid_type')} -> {volume}ml effective")
            print(f"   TOTAL Today Total Effective: {total_today}ml")
        else:
            print(f"FAIL Failed to get today's logs: {today_resp.status_code}")

        # 3. Check user profile (daily goal)
        profile_resp = requests.get(f"{BASE_URL}/users/profile", headers=headers)
        if profile_resp.status_code == 200:
            profile = profile_resp.json()
            daily_goal = profile.get('daily_goal_ml', 2000)
            print(f"\nOK User Profile:")
            print(f"   Daily Goal: {daily_goal}ml")
            if 'total_today' in locals():
                progress_pct = (total_today / daily_goal * 100) if daily_goal > 0 else 0
                print(f"   Progress: {progress_pct:.1f}% ({total_today}/{daily_goal}ml)")
                print(f"   Goal Achieved: {'YES' if progress_pct >= 80 else 'NO (need 80%)'}")
        else:
            print(f"FAIL Failed to get profile: {profile_resp.status_code}")

        # 4. Test creating new intake log to trigger streak update
        print(f"\n=== TESTING STREAK UPDATE ===")
        print("Creating new intake log to test streak calculation...")

        new_log_data = {
            "volume_ml": 500,
            "liquid_type": "water",
            "source": "manual"
        }

        intake_resp = requests.post(f"{BASE_URL}/intake/", json=new_log_data, headers=headers)
        print(f"Intake creation: {intake_resp.status_code}")
        if intake_resp.status_code == 201:
            print("OK Intake log created successfully")

            # Check updated stats
            new_stats_resp = requests.get(f"{BASE_URL}/users/stats", headers=headers)
            if new_stats_resp.status_code == 200:
                new_stats = new_stats_resp.json()
                print(f"UPDATED Updated Stats:")
                print(f"   Current Streak: {new_stats.get('current_streak', 'N/A')} days")
                print(f"   Longest Streak: {new_stats.get('longest_streak', 'N/A')} days")
        else:
            print(f"FAIL Failed to create intake: {intake_resp.text[:200]}")

    except Exception as e:
        print(f"FAIL Error: {e}")

def check_flutter_app():
    """Check Flutter app API calls"""
    print("\n=== FLUTTER APP CHECK ===")
    print("FLUTTER To debug Flutter app:")
    print("1. Open Flutter app va check console logs")
    print("2. Look for API calls to /users/stats")
    print("3. Check UserStatsProvider state")
    print("4. Check HomeProvider streak data sync")

    print("\nFlutter Debug Commands:")
    print("flutter logs --verbose")
    print("flutter run -d windows --verbose")

if __name__ == "__main__":
    print("AquaTrack Streak Debug")
    print("=" * 50)

    check_backend_data()
    check_flutter_app()

    print("\n" + "=" * 50)
    print("Debug completed")