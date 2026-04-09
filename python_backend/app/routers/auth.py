from __future__ import annotations

import ipaddress
import time

from fastapi import APIRouter, HTTPException, Request, status

from ..db import db_conn
from ..models import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest
from ..security import (
    create_access_token,
    hash_password,
    new_refresh_token,
    password_hash_needs_update,
    refresh_token_hash,
    verify_password,
)
from ..settings import settings


router = APIRouter(prefix="/auth", tags=["auth"])


def _safe_client_ip(request: Request) -> str | None:
    raw = request.client.host if request.client else None
    if not raw:
        return None
    try:
        return str(ipaddress.ip_address(raw))
    except ValueError:
        return None


@router.post("/register", response_model=AuthResponse)
def register(payload: RegisterRequest, request: Request) -> AuthResponse:
    email = payload.email.strip().lower()
    username = email
    display_name = payload.display_name or email.split("@", 1)[0]

    try:
        pw_hash = hash_password(payload.password)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    refresh = new_refresh_token()
    refresh_hash = refresh_token_hash(refresh)
    refresh_expires_at = int(time.time()) + settings.refresh_token_ttl_seconds

    with db_conn() as conn:
        with conn.cursor() as cur:
            # Prevent duplicates (email is unique by provider+identifier; username unique too)
            cur.execute(
                """
                SELECT 1
                FROM auth_identities ai
                WHERE ai.provider = 'email' AND ai.identifier = %s
                """,
                (email,),
            )
            if cur.fetchone() is not None:
                raise HTTPException(status_code=409, detail="email already registered")

            cur.execute(
                """
                INSERT INTO users (username, display_name)
                VALUES (%s, %s)
                RETURNING id
                """,
                (username, display_name),
            )
            user_id = cur.fetchone()[0]

            cur.execute(
                """
                INSERT INTO auth_identities (user_id, provider, identifier, password_hash)
                VALUES (%s, 'email', %s, %s)
                """,
                (user_id, email, pw_hash),
            )

            cur.execute(
                """
                INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip)
                VALUES (%s, %s, to_timestamp(%s), %s, %s)
                """,
                (
                    user_id,
                    refresh_hash,
                    refresh_expires_at,
                    request.headers.get("user-agent"),
                    _safe_client_ip(request),
                ),
            )

    access = create_access_token(user_id=str(user_id))
    return AuthResponse(
        access_token=access.token,
        access_expires_at=access.expires_at,
        refresh_token=refresh,
    )


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, request: Request) -> AuthResponse:
    email = payload.email.strip().lower()

    refresh = new_refresh_token()
    refresh_hash = refresh_token_hash(refresh)
    refresh_expires_at = int(time.time()) + settings.refresh_token_ttl_seconds

    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT u.id, ai.password_hash, u.is_banned
                FROM auth_identities ai
                JOIN users u ON u.id = ai.user_id
                WHERE ai.provider = 'email' AND ai.identifier = %s
                """,
                (email,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=401, detail="invalid credentials")

            user_id, pw_hash, is_banned = row
            if is_banned:
                raise HTTPException(status_code=403, detail="user banned")

            if not verify_password(payload.password, pw_hash):
                raise HTTPException(status_code=401, detail="invalid credentials")

            # Auto-migrate old bcrypt hashes to argon2 on successful login.
            if password_hash_needs_update(pw_hash):
                cur.execute(
                    """
                    UPDATE auth_identities
                    SET password_hash = %s, updated_at = now()
                    WHERE user_id = %s AND provider = 'email' AND identifier = %s
                    """,
                    (hash_password(payload.password), user_id, email),
                )

            cur.execute(
                """
                INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip)
                VALUES (%s, %s, to_timestamp(%s), %s, %s)
                """,
                (
                    user_id,
                    refresh_hash,
                    refresh_expires_at,
                    request.headers.get("user-agent"),
                    _safe_client_ip(request),
                ),
            )

    access = create_access_token(user_id=str(user_id))
    return AuthResponse(
        access_token=access.token,
        access_expires_at=access.expires_at,
        refresh_token=refresh,
    )


@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest, request: Request) -> AuthResponse:
    incoming_hash = refresh_token_hash(payload.refresh_token)

    new_refresh = new_refresh_token()
    new_hash = refresh_token_hash(new_refresh)
    new_expires_at = int(time.time()) + settings.refresh_token_ttl_seconds

    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT rt.user_id, rt.expires_at, rt.revoked_at
                FROM refresh_tokens rt
                WHERE rt.token_hash = %s
                """,
                (incoming_hash,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=401, detail="invalid refresh token")

            user_id, expires_at, revoked_at = row
            if revoked_at is not None:
                raise HTTPException(status_code=401, detail="refresh token revoked")
            if expires_at is not None and int(expires_at.timestamp()) < int(time.time()):
                raise HTTPException(status_code=401, detail="refresh token expired")

            # Rotate: revoke old, insert new
            cur.execute(
                """
                UPDATE refresh_tokens
                SET revoked_at = now(), replaced_by_token_hash = %s
                WHERE token_hash = %s
                """,
                (new_hash, incoming_hash),
            )
            cur.execute(
                """
                INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip)
                VALUES (%s, %s, to_timestamp(%s), %s, %s)
                """,
                (
                    user_id,
                    new_hash,
                    new_expires_at,
                    request.headers.get("user-agent"),
                    _safe_client_ip(request),
                ),
            )

    access = create_access_token(user_id=str(user_id))
    return AuthResponse(
        access_token=access.token,
        access_expires_at=access.expires_at,
        refresh_token=new_refresh,
    )


