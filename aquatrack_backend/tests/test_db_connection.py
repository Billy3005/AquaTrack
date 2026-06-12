"""
Test script to verify database connection and setup
Run with: python test_db_connection.py
"""

import os
import sys

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy import text

from app.core.config import settings
from app.core.database import SessionLocal, engine, init_db


def test_connection():
    """Test basic database connection"""
    print("🔍 Testing database connection...")
    print(f"Database URL: {settings.database_url}")

    try:
        # Test connection
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            print("✅ Database connection successful!")
            return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("\n💡 Make sure PostgreSQL is running and database exists:")
        print(f"   - Host: {settings.DB_HOST}")
        print(f"   - Port: {settings.DB_PORT}")
        print(f"   - Database: {settings.DB_NAME}")
        print(f"   - User: {settings.DB_USER}")
        print("\n🛠️  To create database:")
        print(f"   createuser -s {settings.DB_USER}")
        print(f"   createdb -O {settings.DB_USER} {settings.DB_NAME}")
        return False


def test_models():
    """Test model imports and table creation"""
    print("\n🔍 Testing models...")

    try:
        # Import models
        from app.models import Achievement, DailySummary, IntakeLog, User

        print("✅ Models imported successfully!")

        # Create tables
        print("🏗️  Creating tables...")
        init_db()
        print("✅ Tables created successfully!")

        return True
    except Exception as e:
        print(f"❌ Model/table creation failed: {e}")
        return False


def test_session():
    """Test database session"""
    print("\n🔍 Testing database session...")

    try:
        # Test session
        db = SessionLocal()
        result = db.execute(text("SELECT version()"))
        version = result.scalar()
        print(f"✅ PostgreSQL version: {version}")
        db.close()
        return True
    except Exception as e:
        print(f"❌ Session test failed: {e}")
        return False


if __name__ == "__main__":
    print("🧪 AquaTrack Database Connection Test\n")

    # Run tests
    connection_ok = test_connection()

    if connection_ok:
        models_ok = test_models()
        if models_ok:
            session_ok = test_session()

            if session_ok:
                print("\n🎉 All database tests passed!")
                print("✅ Backend is ready for development!")
            else:
                print("\n❌ Session test failed")
        else:
            print("\n❌ Models test failed")
    else:
        print("\n❌ Connection test failed")

    print("\n" + "=" * 50)
