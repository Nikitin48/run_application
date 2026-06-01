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

    # Должен совпадать с APP_ENV при запуске (local / release)
    app_env: str = _APP_ENV
    app_host: str = "127.0.0.1"
    app_port: int = 8000

    # Подключение к БД: либо один DATABASE_URL, либо отдельные параметры (для release)
    database_url: str | None = None
    db_host: str = "127.0.0.1"
    db_port: int = 5432
    db_name: str = "run_app"
    db_user: str = "postgres"
    db_password: str = ""
    # Для облачной БД (Yandex): sslmode=require
    db_sslmode: str = ""

    @property
    def database_url_resolved(self) -> str:
        """Итоговый URL подключения: DATABASE_URL или собранный из host/port/database/user/password."""
        if self.database_url:
            return self.database_url
        user_pass = f"{self.db_user}:{self.db_password}" if self.db_password else self.db_user
        base = f"postgresql://{user_pass}@{self.db_host}:{self.db_port}/{self.db_name}"
        if self.db_sslmode:
            base += "?" + self.db_sslmode.strip().lstrip("?")
        return base

    jwt_secret: str = "change_me"
    jwt_issuer: str = "run-application"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 60 * 60 * 24 * 30

    fcm_enabled: bool = False
    fcm_service_account_json_path: str = ""
    media_root: str = "/app/media"
    media_url_prefix: str = "/media"
    max_avatar_size_mb: int = 5
    allowed_avatar_mime_types: list[str] = ["image/jpeg", "image/png"]

    # Background resolver for territory_contested_areas past resolve_at.
    territory_contest_resolve_enabled: bool = True
    territory_contest_resolve_interval_seconds: int = 15


settings = Settings()







