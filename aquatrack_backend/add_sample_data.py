#!/usr/bin/env python3
"""
Add sample intake logs to demo user for testing stats screen
"""

import random
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Add app directory to path
app_dir = Path(__file__).parent / "app"
sys.path.append(str(app_dir))

from sqlalchemy.orm import Session

from app.core.database import SessionLocal, init_db
from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud
from app.schemas.intake_log import IntakeLogCreate


def add_sample_intake_logs():
    """Add sample intake logs to demo user"""
    print("Initializing database...")
    init_db()

    db: Session = SessionLocal()

    try:
        # Get demo user
        demo_user = user_crud.get_by_email(db, email="demo@aquatrack.com")
        if not demo_user:
            print("Demo user not found! Please create demo user first.")
            return

        print(f"Found demo user: {demo_user.email} (ID: {demo_user.id})")

        # Generate sample logs for the past 7 days
        print("Adding sample intake logs...")
        today = datetime.now()

        liquid_types = ["water", "tea", "coffee", "juice"]

        total_logs = 0
        for i in range(7):  # Past 7 days
            log_date = today - timedelta(days=i)

            # Generate 3-8 logs per day
            logs_per_day = random.randint(3, 8)

            for j in range(logs_per_day):
                # Spread logs throughout the day
                hour = random.randint(7, 22)  # 7am to 10pm
                minute = random.randint(0, 59)

                log_time = log_date.replace(
                    hour=hour, minute=minute, second=0, microsecond=0
                )

                # Random volume between 150ml - 500ml
                volume = random.randint(150, 500)

                # Random liquid type
                liquid_type = random.choice(liquid_types)

                # Create intake log
                log_create = IntakeLogCreate(
                    volume_ml=volume,
                    liquid_type=liquid_type,
                    logged_at=log_time,
                    note=f"Sample log {j+1}",
                )

                intake_log_crud.create(db, obj_in=log_create, user_id=demo_user.id)
                total_logs += 1

        db.commit()
        print(f"Successfully added {total_logs} sample intake logs!")
        print("Sample data setup complete!")

    except Exception as e:
        print(f"❌ Error adding sample data: {e}")
        import traceback

        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    add_sample_intake_logs()
