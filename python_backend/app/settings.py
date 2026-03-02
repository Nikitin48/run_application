import os

from pydantic_settings import BaseSettings, SettingsConfigDict

# APP_ENV выбирается до загрузки настроек (из env или .env)
# local — локальная БД, release — облачная (Yandex Managed PostgreSQL)
_APP_ENV = os.getenv("APP_ENV", "local")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", f".env.{_APP_ENV}"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = "local"
    app_host: str = "127.0.0.1"
    app_port: int = 8000

    # DATABASE_URL берётся из .env.local (при APP_ENV=local) или .env.release (при APP_ENV=release)
    database_url: str = "postgresql://postgres:postgres@127.0.0.1:5432/run_app"

    jwt_secret: str = "change_me"
    jwt_issuer: str = "run-application"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 60 * 60 * 24 * 30


settings = Settings()







