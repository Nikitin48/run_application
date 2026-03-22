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
                  n.id::text,
                  n.kind,
                  n.attacker_user_id::text,
                  au.display_name,
                  n.run_id::text,
                  n.stolen_area_m2,
                  n.payload,
                  n.created_at
                FROM user_notifications n
                LEFT JOIN users au ON au.id = n.attacker_user_id
                WHERE n.user_id = %s
                ORDER BY n.created_at DESC, n.id DESC
                LIMIT 1
                """,
                (user_id,),
            )
            row = cur.fetchone()
            if row is None:
                return {"has_notification": False}
            return {
                "has_notification": True,
                "id": row[0],
                "kind": row[1],
                "attacker_user_id": row[2],
                "attacker_display_name": row[3],
                "run_id": row[4],
                "stolen_area_m2": row[5],
                "payload": row[6],
                "created_at": row[7],
            }


@router.get("")
def notifications_history(user_id: str = Depends(current_user_id), limit: int = 10) -> dict:
    safe_limit = 10 if limit > 10 else (1 if limit < 1 else limit)
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  n.id::text,
                  kind,
                  n.attacker_user_id::text,
                  au.display_name,
                  n.run_id::text,
                  n.stolen_area_m2,
                  n.payload,
                  n.created_at
                FROM user_notifications n
                LEFT JOIN users au ON au.id = n.attacker_user_id
                WHERE n.user_id = %s
                ORDER BY n.created_at DESC, n.id DESC
                LIMIT %s
                """,
                (user_id, safe_limit),
            )
            rows = cur.fetchall()
            items = [
                {
                    "id": row[0],
                    "kind": row[1],
                    "attacker_user_id": row[2],
                    "attacker_display_name": row[3],
                    "run_id": row[4],
                    "stolen_area_m2": row[5],
                    "payload": row[6],
                    "created_at": row[7],
                }
                for row in rows
            ]
            return {
                "items": items,
            }


