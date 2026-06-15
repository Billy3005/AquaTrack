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
        "http://localhost:3001",  # Flutter web NEW PORT
        "http://127.0.0.1:3001",
        "http://localhost:3002",  # Flutter web PORT 3002
        "http://127.0.0.1:3002",
        "http://localhost:8080",  # Flutter web
        "http://127.0.0.1:8080",
        "http://localhost:64038",  # Flutter app current port
        "http://127.0.0.1:64038",
        "capacitor://localhost",  # Capacitor mobile app
        "ionic://localhost",  # Ionic mobile app
        "http://localhost",  # Mobile dev
        "*",  # Development only - remove for production
    ]

    # Database Settings
    # Managed hosts (Railway, Render, …) inject a single DATABASE_URL — prefer it.
    # The DB_* parts below stay as a fallback for hand-rolled Postgres setups.
    DATABASE_URL: str = ""
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USER: str = "aquatrack_user"
    DB_PASSWORD: str = "aquatrack_password"
    DB_NAME: str = "aquatrack_db"

    @property
    def database_url(self) -> str:
        """Resolve the SQLAlchemy URL.

        Priority: explicit DATABASE_URL (managed Postgres) > SQLite in
        development > DB_* parts assembled into a Postgres URL.
        """
        if self.DATABASE_URL:
            # Railway/Heroku style "postgres://" is rejected by SQLAlchemy 2.x —
            # normalise to the "postgresql://" driver scheme it expects.
            if self.DATABASE_URL.startswith("postgres://"):
                return self.DATABASE_URL.replace("postgres://", "postgresql://", 1)
            return self.DATABASE_URL
        if self.ENVIRONMENT == "development":
            return "sqlite:///./aquatrack_water_formula.db"
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

    # Google Sign-In (ADR 0006): the OAuth *Web* client ID — the audience the
    # google_sign_in plugin puts in its ID tokens (serverClientId).
    GOOGLE_CLIENT_ID: str = ""

    # Smart Scan Vision Settings (ADR-0005)
    # Model is env-configurable so a retired model is a config change, not a deploy
    # Eval 2026-06-11 (n=10): Sonnet ~= Haiku accuracy at 3x cost -> Haiku.
    # 1568px: clear-water fill detection needs all the resolution it can get.
    VISION_MODEL: str = "claude-haiku-4-5"
    VISION_MAX_IMAGE_DIMENSION: int = 1568

    # Email Settings (SMTP)
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_USE_TLS: bool = True
    FROM_EMAIL: str = "noreply@aquatrack.app"
    FROM_NAME: str = "AquaTrack"

    # Frontend URLs
    FRONTEND_URL: str = "http://localhost:3000"  # Flutter web or mobile deep link base
    APP_STORE_URL: str = (
        "https://play.google.com/store/apps/details?id=com.aquatrack.app"
    )

    # Security Settings (Production)
    ENABLE_RATE_LIMITING: bool = False  # Disabled for development testing
    BCRYPT_ROUNDS: int = 12
    SESSION_COOKIE_SECURE: bool = False  # Set True in production with HTTPS
    SESSION_COOKIE_HTTPONLY: bool = True
    REQUIRE_EMAIL_VERIFICATION: bool = True

    # File Upload Settings
    MAX_FILE_SIZE_MB: int = 10
    ALLOWED_FILE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    UPLOAD_DIRECTORY: str = "./uploads"

    # Rate Limiting Settings
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = 60
    RATE_LIMIT_BURST: int = 100

    # App specific settings
    DEFAULT_DAILY_GOAL_ML: int = 2000
    MAX_DAILY_GOAL_ML: int = 5000
    MIN_DAILY_GOAL_ML: int = 1000

    # Level system settings
    BASE_XP_PER_LEVEL: int = 100
    XP_MULTIPLIER: float = 1.5
    MAX_LEVEL: int = 50

    # Monitoring Settings
    ENABLE_MONITORING: bool = True
    HEALTH_CHECK_INTERVAL_SECONDS: int = 60
    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=True
    )


# Global settings instance
settings = Settings()
