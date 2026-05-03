from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables"""

    # App Settings
    PROJECT_NAME: str = "AquaTrack API"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"

    # CORS Settings
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",  # Flutter web debug
        "http://127.0.0.1:3000",
        "http://localhost:8080",  # Flutter web
        "http://127.0.0.1:8080",
        "capacitor://localhost",  # Capacitor mobile app
        "ionic://localhost",  # Ionic mobile app
        "http://localhost",  # Mobile dev
        "*",  # Development only - remove for production
    ]

    # Database Settings
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USER: str = "aquatrack_user"
    DB_PASSWORD: str = "aquatrack_password"
    DB_NAME: str = "aquatrack_db"

    @property
    def database_url(self) -> str:
        """Construct PostgreSQL database URL"""
        return (
            f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    # Security Settings
    SECRET_KEY: str = "your-super-secret-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # AI Settings
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""

    # App specific settings
    DEFAULT_DAILY_GOAL_ML: int = 2000
    MAX_DAILY_GOAL_ML: int = 5000
    MIN_DAILY_GOAL_ML: int = 1000

    # Level system settings
    BASE_XP_PER_LEVEL: int = 100
    XP_MULTIPLIER: float = 1.5
    MAX_LEVEL: int = 50

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=True
    )


# Global settings instance
settings = Settings()
