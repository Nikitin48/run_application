from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..db import db_conn
from ..models import (
    ChangePasswordRequest,
    MeProfileOut,
    TerritoryColorOut,
    UpdateMeProfileRequest,
    UpdateTerritoryColorRequest,
    UserOut,
    UserStatsOut,
)
from ..security import decode_access_token, hash_password, verify_password


router = APIRouter(tags=["me"])
bearer = HTTPBearer(auto_error=False)
DEFAULT_TERRITORY_COLOR = "#3B82F6"


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
                SELECT id::text, username, display_name, avatar_url, territory_color, created_at
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
                territory_color=row[4] or DEFAULT_TERRITORY_COLOR,
                created_at=row[5],
            )


@router.get("/me/profile", response_model=MeProfileOut)
def me_profile(user_id: str = Depends(current_user_id)) -> MeProfileOut:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  u.id::text,
                  u.username,
                  u.display_name,
                  u.avatar_url,
                  (
                    SELECT ai.identifier
                    FROM auth_identities ai
                    WHERE ai.user_id = u.id AND ai.provider = 'email'
                    LIMIT 1
                  ) AS email,
                  u.territory_color,
                  u.created_at,
                  COALESCE(us.run_count, 0),
                  COALESCE(us.total_distance_m, 0),
                  COALESCE(us.total_elapsed_s, 0),
                  COALESCE(us.total_paused_s, 0),
                  COALESCE(us.total_moving_s, 0),
                  COALESCE(us.owned_area_m2, 0)
                FROM users u
                LEFT JOIN user_stats us ON us.user_id = u.id
                WHERE u.id = %s
                """,
                (user_id,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="user not found")
            return MeProfileOut(
                id=row[0],
                username=row[1],
                display_name=row[2],
                avatar_url=row[3],
                email=row[4],
                territory_color=row[5] or DEFAULT_TERRITORY_COLOR,
                created_at=row[6],
                stats=UserStatsOut(
                    run_count=int(row[7]),
                    total_distance_m=float(row[8]),
                    total_elapsed_s=int(row[9]),
                    total_paused_s=int(row[10]),
                    total_moving_s=int(row[11]),
                    owned_area_m2=float(row[12]),
                ),
            )


@router.patch("/me/territory-color", response_model=TerritoryColorOut)
def update_territory_color(
    payload: UpdateTerritoryColorRequest,
    user_id: str = Depends(current_user_id),
) -> TerritoryColorOut:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE users
                SET territory_color = %s, updated_at = now()
                WHERE id = %s
                RETURNING territory_color
                """,
                (payload.territory_color.upper(), user_id),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="user not found")
            return TerritoryColorOut(territory_color=row[0] or DEFAULT_TERRITORY_COLOR)


@router.patch("/me/profile", response_model=MeProfileOut)
def update_me_profile(
    payload: UpdateMeProfileRequest,
    user_id: str = Depends(current_user_id),
) -> MeProfileOut:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE users
                SET display_name = COALESCE(%s, display_name),
                    avatar_url = COALESCE(%s, avatar_url),
                    updated_at = now()
                WHERE id = %s
                """,
                (payload.display_name, payload.avatar_url, user_id),
            )
    return me_profile(user_id=user_id)


@router.patch("/me/password")
def change_password(
    payload: ChangePasswordRequest,
    user_id: str = Depends(current_user_id),
) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT ai.password_hash, u.is_banned
                FROM auth_identities ai
                JOIN users u ON u.id = ai.user_id
                WHERE ai.user_id = %s AND ai.provider = 'email'
                LIMIT 1
                """,
                (user_id,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="email identity not found")

            pw_hash, is_banned = row
            if is_banned:
                raise HTTPException(status_code=403, detail="user banned")

            if not verify_password(payload.current_password, pw_hash):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="invalid current password",
                )

            try:
                new_hash = hash_password(payload.new_password)
            except ValueError as e:
                raise HTTPException(status_code=422, detail=str(e))

            cur.execute(
                """
                UPDATE auth_identities
                SET password_hash = %s, updated_at = now()
                WHERE user_id = %s AND provider = 'email'
                """,
                (new_hash, user_id),
            )

            # Security best practice: force re-login on other sessions.
            cur.execute(
                """
                UPDATE refresh_tokens
                SET revoked_at = now()
                WHERE user_id = %s AND revoked_at IS NULL
                """,
                (user_id,),
            )

    return {"ok": True}


