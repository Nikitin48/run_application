from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from ..db import db_conn
from ..dependencies.auth import CurrentUser, require_admin
from ..models import AdminUserActionOut, AdminUserOut
from ..services.admin_users_service import ban_user, search_users, set_admin, unban_user

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users", response_model=list[AdminUserOut])
def admin_search_users(
    query: str = Query(default="", max_length=120),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    admin: CurrentUser = Depends(require_admin),
) -> list[AdminUserOut]:
    _ = admin
    with db_conn() as conn:
        return search_users(conn, query=query, limit=limit, offset=offset)


@router.post("/users/{user_id}/ban", response_model=AdminUserActionOut)
def admin_ban_user(
    user_id: str,
    admin: CurrentUser = Depends(require_admin),
) -> AdminUserActionOut:
    with db_conn() as conn:
        return ban_user(conn, actor_user_id=admin.id, target_user_id=user_id)


@router.post("/users/{user_id}/unban", response_model=AdminUserOut)
def admin_unban_user(
    user_id: str,
    admin: CurrentUser = Depends(require_admin),
) -> AdminUserOut:
    _ = admin
    with db_conn() as conn:
        return unban_user(conn, target_user_id=user_id)


@router.post("/users/{user_id}/grant-admin", response_model=AdminUserOut)
def admin_grant_admin(
    user_id: str,
    admin: CurrentUser = Depends(require_admin),
) -> AdminUserOut:
    with db_conn() as conn:
        return set_admin(conn, actor_user_id=admin.id, target_user_id=user_id, is_admin=True)


@router.post("/users/{user_id}/revoke-admin", response_model=AdminUserOut)
def admin_revoke_admin(
    user_id: str,
    admin: CurrentUser = Depends(require_admin),
) -> AdminUserOut:
    with db_conn() as conn:
        return set_admin(conn, actor_user_id=admin.id, target_user_id=user_id, is_admin=False)
