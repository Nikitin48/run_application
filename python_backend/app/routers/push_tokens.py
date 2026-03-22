from __future__ import annotations

from fastapi import APIRouter, Depends

from ..db import db_conn
from ..models import PushTokenDeleteRequest, PushTokenUpsertRequest
from .me import current_user_id

router = APIRouter(prefix="/push-tokens", tags=["push-tokens"])


@router.post("")
def upsert_push_token(
    payload: PushTokenUpsertRequest,
    user_id: str = Depends(current_user_id),
) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO user_push_tokens (
                  user_id, platform, token, app_version, device_id, created_at, updated_at
                )
                VALUES (%s, %s, %s, %s, %s, now(), now())
                ON CONFLICT (token)
                DO UPDATE SET
                  user_id = EXCLUDED.user_id,
                  platform = EXCLUDED.platform,
                  app_version = EXCLUDED.app_version,
                  device_id = EXCLUDED.device_id,
                  updated_at = now()
                """,
                (
                    user_id,
                    payload.platform,
                    payload.token,
                    payload.app_version,
                    payload.device_id,
                ),
            )
    return {"ok": True}


@router.delete("")
def delete_push_token(
    payload: PushTokenDeleteRequest,
    user_id: str = Depends(current_user_id),
) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM user_push_tokens WHERE user_id = %s AND token = %s",
                (user_id, payload.token),
            )
    return {"ok": True}

