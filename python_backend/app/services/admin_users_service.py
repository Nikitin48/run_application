from __future__ import annotations

from fastapi import HTTPException, status
from psycopg import Connection

from ..models import AdminUserActionOut, AdminUserOut


def _admin_user_from_row(row: tuple) -> AdminUserOut:
    return AdminUserOut(
        id=row[0],
        username=row[1],
        display_name=row[2],
        email=row[3],
        avatar_url=row[4],
        is_admin=bool(row[5]),
        is_banned=bool(row[6]),
        owned_area_m2=float(row[7] or 0),
        created_at=row[8],
    )


def _get_user(conn: Connection, user_id: str) -> AdminUserOut:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              u.id::text,
              u.username,
              u.display_name,
              (
                SELECT ai.identifier
                FROM auth_identities ai
                WHERE ai.user_id = u.id AND ai.provider = 'email'
                LIMIT 1
              ) AS email,
              u.avatar_url,
              u.is_admin,
              u.is_banned,
              COALESCE(us.owned_area_m2, territory_owned_area_m2(u.id), 0)::double precision,
              u.created_at
            FROM users u
            LEFT JOIN user_stats us ON us.user_id = u.id
            WHERE u.id = %s
            """,
            (user_id,),
        )
        row = cur.fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")
    return _admin_user_from_row(row)


def search_users(conn: Connection, *, query: str, limit: int, offset: int) -> list[AdminUserOut]:
    normalized_query = query.strip().lower()
    search = f"%{normalized_query}%"
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              u.id::text,
              u.username,
              u.display_name,
              (
                SELECT ai.identifier
                FROM auth_identities ai
                WHERE ai.user_id = u.id AND ai.provider = 'email'
                LIMIT 1
              ) AS email,
              u.avatar_url,
              u.is_admin,
              u.is_banned,
              COALESCE(us.owned_area_m2, territory_owned_area_m2(u.id), 0)::double precision,
              u.created_at
            FROM users u
            LEFT JOIN user_stats us ON us.user_id = u.id
            LEFT JOIN auth_identities ai_email
              ON ai_email.user_id = u.id AND ai_email.provider = 'email'
            WHERE %s = ''
               OR lower(u.username) LIKE %s
               OR lower(u.display_name) LIKE %s
               OR lower(ai_email.identifier) LIKE %s
            ORDER BY u.created_at DESC, u.id DESC
            LIMIT %s OFFSET %s
            """,
            (normalized_query, search, search, search, limit, offset),
        )
        return [_admin_user_from_row(row) for row in cur.fetchall()]


def set_admin(conn: Connection, *, actor_user_id: str, target_user_id: str, is_admin: bool) -> AdminUserOut:
    if actor_user_id == target_user_id and not is_admin:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="cannot revoke own admin")

    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE users
            SET is_admin = %s, updated_at = now()
            WHERE id = %s
            """,
            (is_admin, target_user_id),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")

    return _get_user(conn, target_user_id)


def ban_user(conn: Connection, *, actor_user_id: str, target_user_id: str) -> AdminUserActionOut:
    if actor_user_id == target_user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="cannot ban yourself")

    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM users WHERE id = %s", (target_user_id,))
        if cur.fetchone() is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")

        cur.execute(
            """
            UPDATE users
            SET is_banned = true, updated_at = now()
            WHERE id = %s
            """,
            (target_user_id,),
        )

        cur.execute(
            """
            UPDATE refresh_tokens
            SET revoked_at = now()
            WHERE user_id = %s AND revoked_at IS NULL
            """,
            (target_user_id,),
        )
        revoked_sessions_count = cur.rowcount

        cur.execute("SELECT count(*) FROM territories WHERE user_id = %s", (target_user_id,))
        deleted_territories_count = int(cur.fetchone()[0])

        cur.execute(
            """
            DELETE FROM territory_contested_area_participants
            WHERE user_id = %s
            """,
            (target_user_id,),
        )
        cur.execute(
            """
            UPDATE territory_contested_areas
            SET current_winner_user_id = NULL, updated_at = now()
            WHERE current_winner_user_id = %s
            """,
            (target_user_id,),
        )
        cur.execute("DELETE FROM territories WHERE user_id = %s", (target_user_id,))
        cur.execute(
            """
            INSERT INTO user_stats (user_id, owned_area_m2, updated_at)
            VALUES (%s, 0, now())
            ON CONFLICT (user_id)
            DO UPDATE SET owned_area_m2 = 0, updated_at = now()
            """,
            (target_user_id,),
        )

    return AdminUserActionOut(
        user=_get_user(conn, target_user_id),
        revoked_sessions_count=max(revoked_sessions_count, 0),
        deleted_territories_count=deleted_territories_count,
    )


def unban_user(conn: Connection, *, target_user_id: str) -> AdminUserOut:
    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE users
            SET is_banned = false, updated_at = now()
            WHERE id = %s
            """,
            (target_user_id,),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")

    return _get_user(conn, target_user_id)
