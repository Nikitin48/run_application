from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..db import db_conn
from ..models import UserOut
from ..security import decode_access_token


router = APIRouter(tags=["me"])
bearer = HTTPBearer(auto_error=False)


def current_user_id(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> str:
    if creds is None or not creds.credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing token")
    try:
        payload = decode_access_token(creds.credentials)
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid token")
    return str(payload["sub"])


@router.get("/me", response_model=UserOut)
def me(user_id: str = Depends(current_user_id)) -> UserOut:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id::text, username, display_name, avatar_url, created_at
                FROM users
                WHERE id = %s
                """,
                (user_id,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="user not found")
            return UserOut(
                id=row[0],
                username=row[1],
                display_name=row[2],
                avatar_url=row[3],
                created_at=row[4],
            )


