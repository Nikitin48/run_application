from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..db import db_conn
from ..models import (
    MeProfileOut,
    TerritoryColorOut,
    UpdateTerritoryColorRequest,
    UserOut,
    UserStatsOut,
)
from ..security import decode_access_token


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


