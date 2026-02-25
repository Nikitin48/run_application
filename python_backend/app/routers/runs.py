from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg.types.json import Jsonb

from ..db import db_conn
from ..geo import clip_interval, haversine_m, seconds_between, wkt_linestring
from ..models import RunFinishRequest, RunFinishResponse, RunHistoryItemOut
from .me import current_user_id


router = APIRouter(prefix="/runs", tags=["runs"])


def _calc_paused_s(
    *, started_at: datetime, ended_at: datetime, pauses: list[tuple[datetime, datetime]]
) -> int:
    total = 0.0
    for ps, pe in pauses:
        total += clip_interval(started_at, ended_at, ps, pe)
    return int(round(total))


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
                    updated_at = now()
                WHERE id = %s
                """,
                (float(cap_area), int(victims), run_id),
            )

    return RunFinishResponse(
        run_id=str(run_id),
        distance_m=float(distance_m),
        elapsed_s=elapsed_s,
        paused_s=paused_s,
        moving_s=moving_s,
        capture_area_m2=float(cap_area),
        victims_count=int(victims),
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
                    created_at=row[10],
                )
                for row in cur.fetchall()
            ]


