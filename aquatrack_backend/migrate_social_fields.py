#!/usr/bin/env python3
"""
Manual migration script để add social fields vào User table
- status: normal/thirsty/stressed/offline
- is_online: boolean
"""

import os
import sqlite3
from pathlib import Path


def migrate_social_fields():
    """Add social fields to users table"""
    db_path = Path(__file__).parent / "aquatrack_water_formula.db"

    if not db_path.exists():
        print(f"ERROR: Database not found at: {db_path}")
        return False

    print(f"INFO: Migrating database: {db_path}")

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Check if columns already exist
        cursor.execute("PRAGMA table_info(users)")
        columns = [row[1] for row in cursor.fetchall()]

        print(f"INFO: Existing columns: {', '.join(columns)}")

        # Add status column if not exists
        if "status" not in columns:
            print("INFO: Adding 'status' column...")
            cursor.execute("ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'normal'")
            print("SUCCESS: Added status column")
        else:
            print("INFO: Status column already exists")

        # Add is_online column if not exists
        if "is_online" not in columns:
            print("INFO: Adding 'is_online' column...")
            cursor.execute(
                "ALTER TABLE users ADD COLUMN is_online BOOLEAN DEFAULT FALSE"
            )
            print("SUCCESS: Added is_online column")
        else:
            print("INFO: is_online column already exists")

        # Commit changes
        conn.commit()

        # Verify migration
        cursor.execute("PRAGMA table_info(users)")
        new_columns = [row[1] for row in cursor.fetchall()]
        print(f"SUCCESS: Final columns: {', '.join(new_columns)}")

        # Set all existing users to online status
        cursor.execute("UPDATE users SET is_online = TRUE WHERE is_online IS NULL")
        conn.commit()

        print("SUCCESS: Social fields migration completed successfully!")
        return True

    except Exception as e:
        print(f"ERROR: Migration failed: {e}")
        return False
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    migrate_social_fields()
