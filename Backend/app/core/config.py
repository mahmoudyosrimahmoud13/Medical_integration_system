from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    """All runtime settings. Values come from environment variables or a .env file."""

    model_config = SettingsConfigDict(env_file=BASE_DIR / ".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "HealthHub API"
    environment: str = "development"
    debug: bool = True

    # Database. SQLite by default so the project runs with zero setup.
    # For PostgreSQL: postgresql+asyncpg://user:pass@host:5432/healthhub
    database_url: str = f"sqlite+aiosqlite:///{BASE_DIR / 'healthhub.db'}"

    # JWT
    jwt_secret: str = Field(default="change-me-in-production-please-use-a-long-random-string", min_length=16)
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24  # one day

    # Media (uploaded images). Served under /Image/... to stay compatible with the old API.
    media_dir: Path = BASE_DIR / "media"
    public_base_url: str = ""  # e.g. https://api.example.com ; empty = build from request

    # Email. If smtp_host is empty, emails are logged to the console instead of sent.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "no-reply@healthhub.local"
    require_email_confirmation: bool = False

    # ML service (drug interaction / CT). Empty = interaction checks are disabled and return "unknown".
    ml_service_url: str = ""

    # Pagination
    page_size: int = 10

    # Local time zone used for "is this appointment in the past?" checks
    timezone: str = "Africa/Cairo"

    # Upload limits
    max_upload_mb: int = 5

    # First admin created by the seed command
    admin_email: str = "admin@healthhub.local"
    admin_password: str = "Admin@12345"

    cors_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
