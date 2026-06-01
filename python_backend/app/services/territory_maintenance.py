from __future__ import annotations

import psycopg

# Session advisory lock: only one resolver tick at a time across API workers.
_TERRITORY_CONTEST_RESOLVE_LOCK_KEY = 82473301


def resolve_due_territory_contests(
    conn: psycopg.Connection,
    *,
    min_area_m2: float = 5000,
) -> int:
    """
    Applies PostGIS resolve_expired_territory_contests() for contests past resolve_at.

    Uses pg_try_advisory_lock so concurrent HTTP requests and the background loop
    do not run the same work in parallel. Returns the number of resolved contests,
    or 0 if another session holds the lock.
    """
    with conn.cursor() as cur:
        cur.execute(
            "SELECT pg_try_advisory_lock(%s)",
            (_TERRITORY_CONTEST_RESOLVE_LOCK_KEY,),
        )
        acquired = cur.fetchone()[0]
        if not acquired:
            return 0
        try:
            cur.execute(
                "SELECT resolve_expired_territory_contests(%s)",
                (min_area_m2,),
            )
            row = cur.fetchone()
            resolved = int(row[0] if row and row[0] is not None else 0)
            cur.execute(
                "SELECT territory_merge_all_vulnerable_adjacent(%s)",
                (min_area_m2,),
            )
            return resolved
        finally:
            cur.execute(
                "SELECT pg_advisory_unlock(%s)",
                (_TERRITORY_CONTEST_RESOLVE_LOCK_KEY,),
            )
