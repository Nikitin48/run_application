from __future__ import annotations

from datetime import datetime, timezone
from typing import Protocol, Sequence

from ..geo import clip_interval, haversine_m

MAX_RUN_SPEED_MPS = 30.0 / 3.6
MIN_OVERSPEED_DISTANCE_M = 30.0
TOTAL_SPEED_MIN_DISTANCE_M = 30.0
MIN_SEGMENT_ACTIVE_SECONDS = 0.5
RUN_SPEED_INVALID_DETAIL = "run speed invalid"


class RunSpeedValidationError(ValueError):
    pass


class RunSpeedPoint(Protocol):
    lat: float
    lng: float
    ts: datetime


def _timestamp(dt: datetime) -> float:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.timestamp()


def validate_run_speed(
    points: Sequence[RunSpeedPoint],
    *,
    pauses: Sequence[tuple[datetime, datetime]],
) -> None:
    total_active_seconds = 0.0
    total_distance_m = 0.0

    for prev, current in zip(points, points[1:], strict=False):
        distance_m = haversine_m(prev.lat, prev.lng, current.lat, current.lng)
        segment_seconds = _timestamp(current.ts) - _timestamp(prev.ts)
        if segment_seconds <= MIN_SEGMENT_ACTIVE_SECONDS:
            if distance_m >= MIN_OVERSPEED_DISTANCE_M:
                raise RunSpeedValidationError(RUN_SPEED_INVALID_DETAIL)
            continue

        paused_seconds = sum(
            clip_interval(prev.ts, current.ts, pause_start, pause_end)
            for pause_start, pause_end in pauses
        )
        active_seconds = segment_seconds - paused_seconds
        if active_seconds <= MIN_SEGMENT_ACTIVE_SECONDS:
            if distance_m >= MIN_OVERSPEED_DISTANCE_M:
                raise RunSpeedValidationError(RUN_SPEED_INVALID_DETAIL)
            continue

        total_active_seconds += active_seconds
        total_distance_m += distance_m
        if (
            distance_m >= MIN_OVERSPEED_DISTANCE_M
            and distance_m / active_seconds > MAX_RUN_SPEED_MPS
        ):
            raise RunSpeedValidationError(RUN_SPEED_INVALID_DETAIL)

    if (
        total_active_seconds > MIN_SEGMENT_ACTIVE_SECONDS
        and total_distance_m >= TOTAL_SPEED_MIN_DISTANCE_M
        and total_distance_m / total_active_seconds > MAX_RUN_SPEED_MPS
    ):
        raise RunSpeedValidationError(RUN_SPEED_INVALID_DETAIL)
