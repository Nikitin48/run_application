from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

import psycopg

from .settings import settings


@contextmanager
def db_conn() -> Iterator[psycopg.Connection]:
    """
    Small helper to keep DB access explicit and simple.
    Later we can replace with a pool or async driver if needed.
    """
    conn = psycopg.connect(settings.database_url_resolved)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


