#!/usr/bin/env python3

import sqlite3
from datetime import datetime

def test_user_api_response():
    """Test API response for user with body data"""

    # First, get a user with body data from database
    conn = sqlite3.connect('aquatrack_backend/aquatrack_water_formula.db')
    cursor = conn.cursor()

    cursor.execute('''
        SELECT id, email, username, gender, age, height, weight,
               activity_level, job_type, coffee_cups_per_day, alcohol_units_per_day
        FROM users
        WHERE gender IS NOT NULL
        ORDER BY created_at DESC
        LIMIT 1
    ''')

    user_data = cursor.fetchone()
    conn.close()

    if not user_data:
        print("No users with body data found")
        return

    print("Found user with body data:")
    print(f"  Email: {user_data[1]}")
    print(f"  Gender: {user_data[3]}, Age: {user_data[4]}")
    print(f"  Height: {user_data[5]}, Weight: {user_data[6]}")
    print(f"  Activity: {user_data[7]}, Job: {user_data[8]}")
    print(f"  Coffee: {user_data[9]}, Alcohol: {user_data[10]}")

    # Now test the direct database to API simulation
    backend_data = {
        'id': user_data[0],
        'email': user_data[1],
        'username': user_data[2],
        'gender': user_data[3],
        'age': user_data[4],
        'height': user_data[5],
        'weight': user_data[6],
        'activity_level': user_data[7],
        'job_type': user_data[8],
        'coffee_cups_per_day': user_data[9],
        'alcohol_units_per_day': user_data[10],
    }

    print("\nSimulating ProfileProvider parsing...")

    # Test the Flutter display format functions
    def format_weight_height_display(weight, height):
        weight_str = str(int(weight)) if weight else '--'
        height_str = str(height) if height else '--'
        return f'{weight_str} kg · {height_str} cm'

    def format_gender_age_display(gender, age):
        gender_map = {'male': 'Nam', 'female': 'Nu', 'other': 'Khac'}
        gender_str = gender_map.get(gender, '--') if gender else '--'
        age_str = str(age) if age else '--'
        return f'{gender_str} · {age_str}'

    def format_activity_level_display(level):
        level_map = {
            'sedentary': 'It van dong',
            'light': 'Nhe nhang',
            'moderate': 'Vua phai',
            'active': 'Tich cuc',
            'very_active': 'Rat tich cuc'
        }
        return level_map.get(level, '--') if level else '--'

    def format_job_type_display(job_type):
        job_map = {
            'office': 'Van phong',
            'mixed': 'Hon hop',
            'outdoor': 'Ngoai troi',
            'manual': 'The luc'
        }
        return job_map.get(job_type, '--') if job_type else '--'

    def format_coffee_alcohol_display(coffee, alcohol):
        coffee_str = str(coffee) if coffee else '0'
        alcohol_str = str(alcohol) if alcohol else '0'
        return f'{coffee_str} coc · {alcohol_str} don vi'

    print("Display format results:")
    print(f"  Weight-Height: {format_weight_height_display(backend_data['weight'], backend_data['height'])}")
    print(f"  Gender-Age: {format_gender_age_display(backend_data['gender'], backend_data['age'])}")
    print(f"  Activity Level: {format_activity_level_display(backend_data['activity_level'])}")
    print(f"  Job Type: {format_job_type_display(backend_data['job_type'])}")
    print(f"  Coffee-Alcohol: {format_coffee_alcohol_display(backend_data['coffee_cups_per_day'], backend_data['alcohol_units_per_day'])}")

    print("\nBody data should display correctly in profile screen!")

if __name__ == "__main__":
    test_user_api_response()