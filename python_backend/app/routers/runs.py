from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from psycopg.types.json import Jsonb

from ..db import db_conn
from ..geo import clip_interval, haversine_m, seconds_between, wkt_linestring
from ..models import RunFinishRequest, RunFinishResponse
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
    if len(points) < 2:
        raise HTTPException(status_code=422, detail="at least 2 points required")

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
            cur.execute("SELECT capture_area_m2, victims_count FROM finalize_run_capture(%s)", (run_id,))
            cap_area, victims = cur.fetchone()

    return RunFinishResponse(
        run_id=str(run_id),
        distance_m=float(distance_m),
        elapsed_s=elapsed_s,
        paused_s=paused_s,
        moving_s=moving_s,
        capture_area_m2=float(cap_area),
        victims_count=int(victims),
    )


