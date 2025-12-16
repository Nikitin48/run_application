from __future__ import annotations

import hashlib
import secrets
import time
from dataclasses import dataclass
from typing import Any

import jwt
from passlib.context import CryptContext

from .settings import settings


# Prefer argon2 for new hashes; keep bcrypt for verifying old hashes (migration on login).
pwd_context = CryptContext(schemes=["argon2", "bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def password_hash_needs_update(password_hash: str) -> bool:
    return pwd_context.needs_update(password_hash)


def new_refresh_token() -> str:
    # 256-bit random, URL-safe
    return secrets.token_urlsafe(32)


def refresh_token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@dataclass(frozen=True)
class AccessToken:
    token: str
    expires_at: int


def create_access_token(*, user_id: str) -> AccessToken:
    now = int(time.time())
    exp = now + settings.access_token_ttl_seconds
    payload: dict[str, Any] = {
        "iss": settings.jwt_issuer,
        "sub": user_id,
        "iat": now,
        "exp": exp,
        "type": "access",
    }
    encoded = jwt.encode(payload, settings.jwt_secret, algorithm="HS256")
    return AccessToken(token=encoded, expires_at=exp)


def decode_access_token(token: str) -> dict[str, Any]:
    payload = jwt.decode(
        token,
        settings.jwt_secret,
        algorithms=["HS256"],
        issuer=settings.jwt_issuer,
        options={"require": ["exp", "iat", "iss", "sub"]},
    )
    if payload.get("type") != "access":
        raise jwt.InvalidTokenError("not an access token")
    return payload


