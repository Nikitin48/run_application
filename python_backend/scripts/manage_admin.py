from __future__ import annotations

import argparse
import os
from typing import Any

import psycopg

def _resolve_conninfo(database_url: str | None) -> str:
    raw = (database_url or "").strip()
    if not raw:
        db_host = os.getenv("DB_HOST", "127.0.0.1")
        db_port = os.getenv("DB_PORT", "5432")
        db_name = os.getenv("DB_NAME", "run_app")
        db_user = os.getenv("DB_USER", "postgres")
        db_password = os.getenv("DB_PASSWORD", "")
        db_sslmode = os.getenv("DB_SSLMODE", "").strip().lstrip("?")
        user_pass = f"{db_user}:{db_password}" if db_password else db_user
        url = f"postgresql://{user_pass}@{db_host}:{db_port}/{db_name}"
        if db_sslmode:
            url += f"?{db_sslmode}"
        return url

    # Allow convenient shorthand: DATABASE_URL=run_app
    # psycopg accepts DSN key-value format, so convert plain dbname.
    if "://" not in raw and "=" not in raw:
        return f"dbname={raw}"

    return raw


def _resolve_user_id(cur: Any, *, email: str | None, user_id: str | None) -> str:
    if user_id:
        cur.execute("SELECT id::text FROM users WHERE id = %s", (user_id,))
        row = cur.fetchone()
        if row is None:
            raise SystemExit(f"user not found by id: {user_id}")
        return str(row[0])

    if not email:
        raise SystemExit("either --email or --user-id is required")

    cur.execute(
        """
        SELECT u.id::text
        FROM auth_identities ai
        JOIN users u ON u.id = ai.user_id
        WHERE ai.provider = 'email' AND ai.identifier = %s
        LIMIT 1
        """,
        (email.strip().lower(),),
    )
    row = cur.fetchone()
    if row is None:
        raise SystemExit(f"user not found by email: {email}")
    return str(row[0])


def _set_admin(
    conn: psycopg.Connection[Any],
    *,
    email: str | None,
    user_id: str | None,
    is_admin: bool,
) -> None:
    with conn.cursor() as cur:
        target_id = _resolve_user_id(cur, email=email, user_id=user_id)
        cur.execute(
            """
            UPDATE users
            SET is_admin = %s, updated_at = now()
            WHERE id = %s
            RETURNING id::text, username, display_name, is_admin
            """,
            (is_admin, target_id),
        )
        row = cur.fetchone()
        if row is None:
            raise SystemExit("failed to update user")
    conn.commit()
    status = "admin" if bool(row[3]) else "regular"
    print(f"updated: id={row[0]} username={row[1]} display_name={row[2]} role={status}")


def _list_admins(conn: psycopg.Connection[Any]) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              u.id::text,
              u.username,
              u.display_name,
              ai.identifier AS email,
              u.created_at
            FROM users u
            LEFT JOIN auth_identities ai
              ON ai.user_id = u.id AND ai.provider = 'email'
            WHERE u.is_admin = true
            ORDER BY u.created_at ASC
            """
        )
        rows = cur.fetchall()

    if not rows:
        print("no admin users")
        return

    print("admin users:")
    for user_id, username, display_name, email, created_at in rows:
        print(
            f"- id={user_id} username={username} display_name={display_name} "
            f"email={email or '-'} created_at={created_at.isoformat()}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage admin users.")
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL"),
        help="Postgres connection string (defaults to DATABASE_URL env var).",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    grant_parser = subparsers.add_parser("grant", help="Grant admin role.")
    grant_parser.add_argument("--email", help="User email identity.")
    grant_parser.add_argument("--user-id", help="User UUID.")

    revoke_parser = subparsers.add_parser("revoke", help="Revoke admin role.")
    revoke_parser.add_argument("--email", help="User email identity.")
    revoke_parser.add_argument("--user-id", help="User UUID.")

    subparsers.add_parser("list", help="List all admin users.")

    args = parser.parse_args()
    conninfo = _resolve_conninfo(args.database_url)

    try:
        with psycopg.connect(conninfo) as conn:
            if args.command == "grant":
                _set_admin(conn, email=args.email, user_id=args.user_id, is_admin=True)
            elif args.command == "revoke":
                _set_admin(conn, email=args.email, user_id=args.user_id, is_admin=False)
            elif args.command == "list":
                _list_admins(conn)
    except psycopg.Error as exc:
        raise SystemExit(
            f"database connection failed: {exc}\n"
            "Use a full URL like postgresql://user:pass@host:5432/dbname "
            "or a shorthand DB name like DATABASE_URL=run_app."
        )


if __name__ == "__main__":
    main()
