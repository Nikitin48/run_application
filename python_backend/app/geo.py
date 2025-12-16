from __future__ import annotations

import math
from datetime import datetime, timezone


def _to_ts(dt: datetime) -> float:
    if dt.tzinfo is None:
        # treat naive as UTC for MVP
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.timestamp()


def haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Great-circle distance between two points (meters).
    Good enough for MVP stats.
    """
    r = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return r * c


def wkt_linestring(points: list[tuple[float, float]]) -> str:
    """
    WKT LineString in (lng lat) order for SRID 4326.
    """
    coords = ", ".join(f"{lng} {lat}" for lat, lng in points)
    return f"LINESTRING({coords})"


def clip_interval(a_start: datetime, a_end: datetime, b_start: datetime, b_end: datetime) -> float:
    """
    Returns overlap duration seconds between [a_start,a_end] and [b_start,b_end].
    """
    s = max(_to_ts(a_start), _to_ts(b_start))
    e = min(_to_ts(a_end), _to_ts(b_end))
    return max(0.0, e - s)


def seconds_between(started_at: datetime, ended_at: datetime) -> int:
    return max(0, int(round(_to_ts(ended_at) - _to_ts(started_at))))


