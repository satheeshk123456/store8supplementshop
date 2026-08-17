"""
Central app configuration. Everything comes from environment variables (.env in dev,
real env vars on the host in production) — nothing here is ever hardcoded, so the same
code runs unchanged across dev/staging/prod with different .env files.
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    env: str = "development"
    app_name: str = "Store 8 Supplement Shop API"
    cors_origins: str = "http://localhost:5173"

    # Firebase
    firebase_service_account_file: str = "./secrets/firebase-service-account.json"
    firebase_service_account_b64: str = ""
    # Exact bucket name from Firebase Console -> Storage -> Files (top of page, after "gs://").
    # e.g. "store8-tech.firebasestorage.app" — no hardcoded default since it's project-specific.
    firebase_storage_bucket: str = ""

    # Security
    secret_key: str = "change-me"
    order_rate_limit: str = "6/minute"

    @property
    def is_production(self) -> bool:
        return self.env.lower() == "production"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
