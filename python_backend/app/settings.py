from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",  # optional local file (not committed)
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = "local"
    app_host: str = "127.0.0.1"
    app_port: int = 8000

    database_url: str = "postgresql://postgres:postgres@127.0.0.1:5432/run_app"

    jwt_secret: str = "change_me"
    jwt_issuer: str = "run-application"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 60 * 60 * 24 * 30


settings = Settings()







