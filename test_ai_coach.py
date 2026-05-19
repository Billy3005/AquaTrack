#!/usr/bin/env python3
"""Test script for AI Coach enhanced functionality"""

import json
import requests
import sys

BASE_URL = "http://127.0.0.1:8000"

def test_ai_coach_chat():
    """Test AI Coach chat functionality"""

    print("=== TESTING AI COACH ===")

    # Test different conversation scenarios
    test_cases = [
        {
            "name": "Greeting Morning",
            "message": "Chào buổi sáng",
            "context": {"current_hour": 8}
        },
        {
            "name": "Progress Check",
            "message": "Tiến độ của tôi thế nào?",
            "context": {"total_today": 1200}
        },
        {
            "name": "Motivation Request",
            "message": "Tôi cần động lực",
            "context": {"total_today": 800}
        },
        {
            "name": "Energy Question",
            "message": "Tôi cảm thấy mệt",
            "context": {"total_today": 500}
        },
        {
            "name": "Evening Greeting",
            "message": "Chào buổi tối",
            "context": {"current_hour": 20, "total_today": 1800}
        }
    ]

    for test_case in test_cases:
        print(f"\n--- {test_case['name']} ---")

        # Prepare request
        chat_data = {
            "message": test_case["message"],
            "context": test_case["context"]
        }

        try:
            # Send request to AI Coach
            response = requests.post(
                f"{BASE_URL}/api/v1/coach/chat",
                json=chat_data,
                headers={"Content-Type": "application/json"},
                timeout=10
            )

            if response.status_code == 200:
                result = response.json()
                print(f"[OK] Response: {result.get('response', 'No response')}")
                print(f"   Coaching Type: {result.get('coaching_type', 'N/A')}")
                print(f"   Motivation Level: {result.get('motivation_level', 'N/A')}")

                if result.get('suggestions'):
                    print(f"   Suggestions: {result.get('suggestions')}")

                if result.get('action_items'):
                    print(f"   Action Items: {result.get('action_items')}")

            else:
                print(f"[ERROR] Error: {response.status_code} - {response.text}")

        except Exception as e:
            print(f"[ERROR] Request failed: {str(e)}")

        print("-" * 50)

def test_proactive_suggestions():
    """Test proactive suggestions endpoint"""

    print("\n=== TESTING PROACTIVE SUGGESTIONS ===")

    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/coach/suggestions",
            timeout=10
        )

        if response.status_code == 200:
            suggestions = response.json()
            print("[OK] Proactive Suggestions:")
            for i, suggestion in enumerate(suggestions, 1):
                print(f"{i}. {suggestion.get('title', 'No title')}")
                print(f"   Message: {suggestion.get('message', 'No message')}")
                print(f"   Priority: {suggestion.get('priority', 'N/A')}")
                print(f"   Category: {suggestion.get('category', 'N/A')}")
                print()
        else:
            print(f"[ERROR] Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"[ERROR] Request failed: {str(e)}")

def test_smart_nudges():
    """Test smart nudges endpoint"""

    print("\n=== TESTING SMART NUDGES ===")

    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/coach/nudges",
            timeout=10
        )

        if response.status_code == 200:
            result = response.json()
            nudges = result.get('nudges', [])
            print("[OK] Smart Nudges:")
            for nudge in nudges:
                print(f"- {nudge.get('title', 'No title')}")
                print(f"  Message: {nudge.get('message', 'No message')}")
                print(f"  Type: {nudge.get('type', 'N/A')}")
                print(f"  Timing: {nudge.get('timing', 'N/A')}")
                print()
        else:
            print(f"[ERROR] Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"[ERROR] Request failed: {str(e)}")

if __name__ == "__main__":
    print("AquaTrack AI Coach Test Suite")
    print("=" * 60)

    # Test AI Coach functionality
    test_ai_coach_chat()
    test_proactive_suggestions()
    test_smart_nudges()

    print("\nAI Coach testing completed!")
    print("\nNote: AI Coach is running in Enhanced Rule-based mode")
    print("To enable Ollama AI: Install Ollama and run 'ollama pull llama3.2:1b'")