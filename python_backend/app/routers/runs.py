from __future__ import annotations

from datetime import datetime
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg.types.json import Jsonb

from ..db import db_conn
from ..geo import clip_interval, haversine_m, seconds_between, wkt_linestring
from ..models import AchievementUnlockedOut, LevelUpOut, RunFinishRequest, RunFinishResponse, RunHistoryItemOut
from ..push import send_territory_attacked_pushes
from ..services.achievements_service import evaluate_user_achievements
from .me import current_user_id


router = APIRouter(prefix="/runs", tags=["runs"])
log = logging.getLogger(__name__)


def _collect_push_targets_for_run(run_id: str) -> list[tuple[str, str, str]]:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT DISTINCT
                  upt.token,
                  COALESCE(att.display_name, 'Игрок') AS attacker_name,
                  un.kind
                FROM user_notifications un
                JOIN user_push_tokens upt ON upt.user_id = un.user_id
                LEFT JOIN users att ON att.id = un.attacker_user_id
                WHERE un.run_id = %s
                """,
                (run_id,),
            )
            rows = cur.fetchall()
            log.info("Push targets loaded for run %s: %d rows", run_id, len(rows))
            return [(str(row[0]), str(row[1]), str(row[2])) for row in rows]


def _delete_invalid_tokens(tokens: list[str]) -> None:
    if not tokens:
        return
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM user_push_tokens WHERE token = ANY(%s)", (tokens,))
    log.info("Deleted invalid push tokens: %d", len(tokens))


def _calc_paused_s(
    *, started_at: datetime, ended_at: datetime, pauses: list[tuple[datetime, datetime]]
) -> int:
    total = 0.0
    for ps, pe in pauses:
        total += clip_interval(started_at, ended_at, ps, pe)
    return int(round(total))


def _track_geojson_from_coords(coords: list[tuple[float, float]]) -> dict[str, object] | None:
    if len(coords) < 2:
        return None
    return {
        "type": "LineString",
        "coordinates": [[lng, lat] for lat, lng in coords],
    }


@router.post("/finish", response_model=RunFinishResponse)
def finish_run(payload: RunFinishRequest, user_id: str = Depends(current_user_id)) -> RunFinishResponse:
    if payload.ended_at <= payload.started_at:
        raise HTTPException(status_code=422, detail="ended_at must be after started_at")

    points = payload.points

    # Normalize pauses: close open pauses at ended_at.
    pauses: list[tuple[datetime, datetime]] = []
    for p in payload.pauses:
        ps = p.started_at
        pe = p.ended_at or payload.ended_at
        if pe <= ps:
            continue
        pauses.append((ps, pe))

    elapsed_s = seconds_between(payload.started_at, payload.ended_at)
    paused_s = _calc_paused_s(started_at=payload.started_at, ended_at=payload.ended_at, pauses=pauses)
    moving_s = max(0, elapsed_s - paused_s)

    # Distance: sum segment distances; MVP ignores pause masking of segments
    # (we rely on the client not recording points while paused).
    distance_m = 0.0
    coords: list[tuple[float, float]] = []
    for pt in points:
        coords.append((pt.lat, pt.lng))
    for (lat1, lng1), (lat2, lng2) in zip(coords, coords[1:], strict=False):
        distance_m += haversine_m(lat1, lng1, lat2, lng2)

    # Don't store "empty" activities in DB/history.
    # We still return a successful response so UI can close the run flow gracefully.
    if len(coords) < 2:
        return RunFinishResponse(
            run_id="",
            distance_m=float(distance_m),
            elapsed_s=elapsed_s,
            paused_s=paused_s,
            moving_s=moving_s,
            capture_area_m2=0.0,
            victims_count=0,
        )

    track_wkt = wkt_linestring(coords)
    track_geojson = _track_geojson_from_coords(coords)
    points_jsonb = Jsonb([p.model_dump(mode="json") for p in points])

    with db_conn() as conn:
        with conn.cursor() as cur:
            # Insert run
            cur.execute(
                """
                INSERT INTO runs (user_id, status, started_at, ended_at, distance_m, elapsed_s, paused_s, moving_s, points, track_line)
                VALUES (%s, 'finished', %s, %s, %s, %s, %s, %s, %s, ST_SetSRID(ST_GeomFromText(%s), 4326))
                RETURNING id
                """,
                (
                    user_id,
                    payload.started_at,
                    payload.ended_at,
                    float(distance_m),
                    int(elapsed_s),
                    int(paused_s),
                    int(moving_s),
                    points_jsonb,
                    track_wkt,
                ),
            )
            run_id = cur.fetchone()[0]  # uuid

            # Insert points (ordered)
            for i, p in enumerate(points):
                cur.execute(
                    """
                    INSERT INTO run_points (run_id, seq, ts, lat, lng, altitude_m, accuracy_m, speed_mps)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        run_id,
                        i,
                        p.ts,
                        p.lat,
                        p.lng,
                        p.altitude_m,
                        p.accuracy_m,
                        p.speed_mps,
                    ),
                )

            # Insert pauses
            for pause in payload.pauses:
                cur.execute(
                    """
                    INSERT INTO run_pauses (run_id, started_at, ended_at, reason)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        run_id,
                        pause.started_at,
                        pause.ended_at,
                        pause.reason,
                    ),
                )

            # Finalize capture (repaint territories, stats, notifications).
            cur.execute(
                "SELECT capture_area_m2, victims_count FROM finalize_run_capture(%s)",
                (run_id,),
            )
            cap_area, victims = cur.fetchone()
            cur.execute(
                """
                UPDATE runs
                SET capture_area_m2 = %s,
                    victims_count = %s,
                    capture_geom = compute_capture_polygons(track_line),
                    updated_at = now()
                WHERE id = %s
                """,
                (float(cap_area), int(victims), run_id),
            )
            cur.execute(
                """
                SELECT ST_AsGeoJSON(capture_geom)::jsonb
                FROM runs
                WHERE id = %s
                """,
                (run_id,),
            )
            capture_geojson = cur.fetchone()[0]
        achievements_result = evaluate_user_achievements(
            conn,
            user_id=user_id,
            run_id=str(run_id),
        )

    push_targets = _collect_push_targets_for_run(str(run_id))
    if not push_targets:
        log.info("No push targets for run %s", run_id)
    by_message: dict[tuple[str, str], list[str]] = {}
    for token, attacker_name, kind in push_targets:
        by_message.setdefault((attacker_name, kind), []).append(token)
    invalid_tokens: list[str] = []
    for (attacker_name, kind), tokens in by_message.items():
        log.info(
            "Sending territory attacked push for run %s attacker=%s tokens=%d",
            run_id,
            attacker_name,
            len(tokens),
        )
        result = send_territory_attacked_pushes(
            tokens=tokens,
            attacker_name=attacker_name,
            kind=kind,
        )
        invalid_tokens.extend(result.invalid_tokens)
        if result.invalid_tokens:
            log.warning(
                "Push send reported invalid tokens for run %s attacker=%s invalid=%d",
                run_id,
                attacker_name,
                len(result.invalid_tokens),
            )
    _delete_invalid_tokens(invalid_tokens)

    return RunFinishResponse(
        run_id=str(run_id),
        started_at=payload.started_at,
        ended_at=payload.ended_at,
        distance_m=float(distance_m),
        elapsed_s=elapsed_s,
        paused_s=paused_s,
        moving_s=moving_s,
        capture_area_m2=float(cap_area),
        victims_count=int(victims),
        capture_geojson=capture_geojson,
        track_geojson=track_geojson,
        new_achievements=[
            AchievementUnlockedOut(
                code=item.code,
                title=item.title,
                description=item.description,
                category=item.category,
                icon_key=item.icon_key,
                xp=item.xp,
                unlocked_at=item.unlocked_at,
            )
            for item in achievements_result.new_achievements
        ],
        level_up=(
            LevelUpOut(
                old_level=achievements_result.old_level,
                new_level=achievements_result.profile_level,
            )
            if achievements_result.profile_level > achievements_result.old_level
            else None
        ),
        profile_xp=achievements_result.profile_xp,
        profile_level=achievements_result.profile_level,
    )


@router.get("/history", response_model=list[RunHistoryItemOut])
def runs_history(
    user_id: str = Depends(current_user_id),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[RunHistoryItemOut]:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  r.id::text,
                  r.status,
                  r.started_at,
                  r.ended_at,
                  COALESCE(r.distance_m, 0),
                  COALESCE(r.elapsed_s, 0),
                  COALESCE(r.paused_s, 0),
                  COALESCE(r.moving_s, 0),
                  COALESCE(r.capture_area_m2, 0),
                  COALESCE(r.victims_count, 0),
                  ST_AsGeoJSON(r.capture_geom)::jsonb,
                  ST_AsGeoJSON(r.track_line)::jsonb,
                  r.created_at
                FROM runs r
                WHERE r.user_id = %s
                ORDER BY COALESCE(r.ended_at, r.created_at) DESC
                LIMIT %s OFFSET %s
                """,
                (user_id, limit, offset),
            )
            return [
                RunHistoryItemOut(
                    run_id=row[0],
                    status=row[1],
                    started_at=row[2],
                    ended_at=row[3],
                    distance_m=float(row[4]),
                    elapsed_s=int(row[5]),
                    paused_s=int(row[6]),
                    moving_s=int(row[7]),
                    capture_area_m2=float(row[8]),
                    victims_count=int(row[9]),
                    capture_geojson=row[10],
                    track_geojson=row[11],
                    created_at=row[12],
                )
                for row in cur.fetchall()
            ]


