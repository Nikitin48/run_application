"""
Yandex Cloud Function: очистка устаревших и отозванных refresh-токенов.
Точка входа: handler(event, context).
Переменные окружения: DATABASE_URL либо DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSLMODE.
"""
from __future__ import annotations

import os


def _database_url() -> str:
    """Собирает URL подключения к PostgreSQL из env (как в python_backend/app/settings.py)."""
    url = os.environ.get("DATABASE_URL")
    if url:
        return url
    host = os.environ.get("DB_HOST", "127.0.0.1")
    port = os.environ.get("DB_PORT", "5432")
    name = os.environ.get("DB_NAME", "run_app")
    user = os.environ.get("DB_USER", "postgres")
    password = os.environ.get("DB_PASSWORD", "")
    sslmode = os.environ.get("DB_SSLMODE", "").strip().lstrip("?")
    user_pass = f"{user}:{password}" if password else user
    base = f"postgresql://{user_pass}@{host}:{port}/{name}"
    if sslmode:
        base += "?" + sslmode
    return base


def handler(event: dict, context: object) -> dict:
    """
    Удаляет из refresh_tokens строки с expires_at < now() или revoked_at IS NOT NULL.
    Возвращает {"ok": True, "deleted": N} или {"ok": False, "error": "..."}.
    """
    import psycopg

    try:
        conn = psycopg.connect(_database_url())
    except Exception as e:
        msg = f"DB connect failed: {e}"
        print(msg)
        return {"ok": False, "error": msg}

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM refresh_tokens
                WHERE expires_at < now() OR revoked_at IS NOT NULL
                """
            )
            deleted = cur.rowcount
        conn.commit()
    except Exception as e:
        conn.rollback()
        msg = f"DELETE failed: {e}"
        print(msg)
        return {"ok": False, "error": msg}
    finally:
        conn.close()

    print(f"token_cleanup: deleted={deleted}")
    return {"ok": True, "deleted": deleted}
