from __future__ import annotations

from pathlib import Path
from urllib.parse import unquote, urlparse
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..db import db_conn
from ..models import (
    AchievementsResponseOut,
    AchievementItemOut,
    AchievementUnlockedOut,
    AvatarOut,
    ChangePasswordRequest,
    MeProfileOut,
    TerritoryColorOut,
    UpdateMeProfileRequest,
    UpdateTerritoryColorRequest,
    UserOut,
    UserStatsOut,
)
from ..services.achievements_service import list_user_achievements
from ..settings import settings
from ..security import decode_access_token, hash_password, verify_password


router = APIRouter(tags=["me"])
bearer = HTTPBearer(auto_error=False)
DEFAULT_TERRITORY_COLOR = "#3B82F6"
AVATAR_SUBDIR = "avatars"
MIME_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
}


def _safe_media_path(relative_path: str) -> Path:
    media_root = Path(settings.media_root).resolve()
    candidate = (media_root / relative_path.lstrip("/")).resolve()
    if media_root not in candidate.parents and candidate != media_root:
        raise HTTPException(status_code=400, detail="invalid media path")
    return candidate


def _extract_local_avatar_path(avatar_url: str | None) -> Path | None:
    if not avatar_url:
        return None
    parsed = urlparse(avatar_url)
    if parsed.scheme in {"http", "https"}:
        raw_path = parsed.path
    else:
        raw_path = avatar_url
    if not raw_path.startswith(settings.media_url_prefix):
        return None
    relative = raw_path[len(settings.media_url_prefix) :].lstrip("/")
    if not relative.startswith(f"{AVATAR_SUBDIR}/"):
        return None
    return _safe_media_path(unquote(relative))


def _build_avatar_url(request: Request, filename: str) -> str:
    base = str(request.base_url).rstrip("/")
    return f"{base}{settings.media_url_prefix}/{AVATAR_SUBDIR}/{filename}"


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
                  u.country_code,
                  c.name AS country_name,
                  u.region_code,
                  r.name AS region_name,
                  u.city_code,
                  ct.name AS city_name,
                  u.created_at,
                  COALESCE(us.run_count, 0),
                  COALESCE(us.total_distance_m, 0),
                  COALESCE(us.total_elapsed_s, 0),
                  COALESCE(us.total_paused_s, 0),
                  COALESCE(us.total_moving_s, 0),
                  COALESCE(us.successful_captures_count, 0),
                  COALESCE(us.total_captured_area_m2, 0),
                  COALESCE(us.total_victims_count, 0),
                  COALESCE(us.owned_area_m2, 0),
                  COALESCE(us.profile_xp, 0),
                  COALESCE(us.profile_level, 1)
                FROM users u
                JOIN ref_countries c ON c.code = u.country_code
                LEFT JOIN ref_regions r ON r.code = u.region_code
                LEFT JOIN ref_cities ct ON ct.code = u.city_code
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
                country_code=row[6],
                country_name=row[7],
                region_code=row[8],
                region_name=row[9],
                city_code=row[10],
                city_name=row[11],
                created_at=row[12],
                stats=UserStatsOut(
                    run_count=int(row[13]),
                    total_distance_m=float(row[14]),
                    total_elapsed_s=int(row[15]),
                    total_paused_s=int(row[16]),
                    total_moving_s=int(row[17]),
                    successful_captures_count=int(row[18]),
                    total_captured_area_m2=float(row[19]),
                    total_victims_count=int(row[20]),
                    owned_area_m2=float(row[21]),
                    profile_xp=int(row[22]),
                    profile_level=int(row[23]),
                ),
            )


@router.get("/me/achievements", response_model=AchievementsResponseOut)
def my_achievements(user_id: str = Depends(current_user_id)) -> AchievementsResponseOut:
    with db_conn() as conn:
        try:
            profile_xp, profile_level, items = list_user_achievements(conn, user_id=user_id)
        except ValueError:
            raise HTTPException(status_code=404, detail="user not found")
        return AchievementsResponseOut(
            profile_xp=profile_xp,
            profile_level=profile_level,
            items=[
                AchievementItemOut(
                    code=item.code,
                    title=item.title,
                    description=item.description,
                    category=item.category,
                    icon_key=item.icon_key,
                    xp=item.xp,
                    sort_order=item.sort_order,
                    is_unlocked=item.is_unlocked,
                    unlocked_at=item.unlocked_at,
                )
                for item in items
            ],
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
                SELECT country_code, region_code, city_code
                FROM users
                WHERE id = %s
                """,
                (user_id,),
            )
            current_row = cur.fetchone()
            if current_row is None:
                raise HTTPException(status_code=404, detail="user not found")

            current_country, current_region, current_city = current_row
            has_country = "country_code" in payload.model_fields_set
            has_region = "region_code" in payload.model_fields_set
            has_city = "city_code" in payload.model_fields_set

            next_country = payload.country_code if has_country else current_country
            next_region = payload.region_code if has_region else current_region
            next_city = payload.city_code if has_city else current_city

            if has_region and next_region is None:
                next_city = None
            elif has_region and next_region != current_region and not has_city:
                next_city = None

            if next_country != "RU":
                raise HTTPException(status_code=422, detail="only RU country is supported")

            cur.execute(
                """
                SELECT 1
                FROM ref_countries
                WHERE code = %s AND is_active = true
                """,
                (next_country,),
            )
            if cur.fetchone() is None:
                raise HTTPException(status_code=422, detail="invalid country_code")

            if next_region is not None:
                cur.execute(
                    """
                    SELECT 1
                    FROM ref_regions
                    WHERE code = %s
                      AND country_code = %s
                      AND is_active = true
                    """,
                    (next_region, next_country),
                )
                if cur.fetchone() is None:
                    raise HTTPException(status_code=422, detail="invalid region_code")

            if next_city is not None:
                if next_region is None:
                    raise HTTPException(status_code=422, detail="region_code is required for city_code")
                cur.execute(
                    """
                    SELECT 1
                    FROM ref_cities
                    WHERE code = %s
                      AND country_code = %s
                      AND region_code = %s
                      AND is_active = true
                    """,
                    (next_city, next_country, next_region),
                )
                if cur.fetchone() is None:
                    raise HTTPException(status_code=422, detail="invalid city_code")

            cur.execute(
                """
                UPDATE users
                SET display_name = COALESCE(%s, display_name),
                    avatar_url = COALESCE(%s, avatar_url),
                    country_code = %s,
                    region_code = %s,
                    city_code = %s,
                    updated_at = now()
                WHERE id = %s
                """,
                (
                    payload.display_name,
                    payload.avatar_url,
                    next_country,
                    next_region,
                    next_city,
                    user_id,
                ),
            )
    return me_profile(user_id=user_id)


@router.post("/me/avatar", response_model=AvatarOut)
def upload_avatar(
    request: Request,
    file: UploadFile = File(...),
    user_id: str = Depends(current_user_id),
) -> AvatarOut:
    content_type = (file.content_type or "").lower()
    allowed_mime_types = {item.lower() for item in settings.allowed_avatar_mime_types}
    if content_type not in allowed_mime_types:
        raise HTTPException(status_code=415, detail="unsupported avatar file type")

    extension = MIME_EXTENSIONS.get(content_type)
    if extension is None:
        raise HTTPException(status_code=415, detail="unsupported avatar file type")

    avatar_dir = _safe_media_path(AVATAR_SUBDIR)
    avatar_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid4().hex}{extension}"
    destination = avatar_dir / filename

    max_size_bytes = settings.max_avatar_size_mb * 1024 * 1024
    bytes_written = 0
    try:
        with destination.open("wb") as out:
            while True:
                chunk = file.file.read(1024 * 1024)
                if not chunk:
                    break
                bytes_written += len(chunk)
                if bytes_written > max_size_bytes:
                    raise HTTPException(status_code=413, detail="avatar file is too large")
                out.write(chunk)
    except HTTPException:
        if destination.exists():
            destination.unlink()
        raise
    finally:
        file.file.close()

    avatar_url = _build_avatar_url(request, filename)
    old_avatar_path: Path | None = None
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT avatar_url FROM users WHERE id = %s", (user_id,))
            row = cur.fetchone()
            if row is None:
                if destination.exists():
                    destination.unlink()
                raise HTTPException(status_code=404, detail="user not found")
            old_avatar_path = _extract_local_avatar_path(row[0])
            cur.execute(
                """
                UPDATE users
                SET avatar_url = %s, updated_at = now()
                WHERE id = %s
                """,
                (avatar_url, user_id),
            )

    if old_avatar_path is not None and old_avatar_path.exists():
        old_avatar_path.unlink(missing_ok=True)

    return AvatarOut(avatar_url=avatar_url)


@router.delete("/me/avatar", response_model=AvatarOut)
def delete_avatar(user_id: str = Depends(current_user_id)) -> AvatarOut:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT avatar_url FROM users WHERE id = %s", (user_id,))
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="user not found")
            old_avatar_path = _extract_local_avatar_path(row[0])
            cur.execute(
                """
                UPDATE users
                SET avatar_url = NULL, updated_at = now()
                WHERE id = %s
                """,
                (user_id,),
            )

    if old_avatar_path is not None and old_avatar_path.exists():
        old_avatar_path.unlink(missing_ok=True)

    return AvatarOut(avatar_url=None)


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


