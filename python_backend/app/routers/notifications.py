from __future__ import annotations

from fastapi import APIRouter, Depends

from ..db import db_conn
from .me import current_user_id


router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/last")
def last_notification(user_id: str = Depends(current_user_id)) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  kind,
                  attacker_user_id::text,
                  run_id::text,
                  stolen_area_m2,
                  payload,
                  created_at
                FROM user_last_notification
                WHERE user_id = %s
                """,
                (user_id,),
            )
            row = cur.fetchone()
            if row is None:
                return {"has_notification": False}
            return {
                "has_notification": True,
                "kind": row[0],
                "attacker_user_id": row[1],
                "run_id": row[2],
                "stolen_area_m2": row[3],
                "payload": row[4],
                "created_at": row[5],
            }


