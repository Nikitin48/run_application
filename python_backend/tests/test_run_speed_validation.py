from __future__ import annotations

import unittest
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from app.services.run_speed_validation import RunSpeedValidationError, validate_run_speed


@dataclass(frozen=True)
class _Point:
    lat: float
    lng: float
    ts: datetime


class RunSpeedValidationTest(unittest.TestCase):
    def test_allows_fast_realistic_running_speed(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.0008, start + timedelta(seconds=12)),
            _Point(55.0, 37.0016, start + timedelta(seconds=24)),
        ]

        validate_run_speed(points, pauses=[])

    def test_ignores_single_gps_jump(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.0002, start + timedelta(seconds=1)),
            _Point(55.0, 37.0003, start + timedelta(seconds=20)),
        ]

        validate_run_speed(points, pauses=[])

    def test_rejects_short_run_with_total_average_above_30_kmh(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.0032, start + timedelta(seconds=10)),
        ]

        with self.assertRaises(RunSpeedValidationError):
            validate_run_speed(points, pauses=[])

    def test_rejects_large_distance_with_too_short_timestamp_gap(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.001, start + timedelta(milliseconds=200)),
        ]

        with self.assertRaises(RunSpeedValidationError):
            validate_run_speed(points, pauses=[])

    def test_rejects_sustained_speed_above_30_kmh(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.0016, start + timedelta(seconds=10)),
            _Point(55.0, 37.0032, start + timedelta(seconds=20)),
        ]

        with self.assertRaisesRegex(RunSpeedValidationError, "run speed invalid"):
            validate_run_speed(points, pauses=[])

    def test_pause_overlap_does_not_hide_fast_active_segment(self) -> None:
        start = datetime(2026, 6, 1, 10, 0, tzinfo=timezone.utc)
        points = [
            _Point(55.0, 37.0, start),
            _Point(55.0, 37.0032, start + timedelta(seconds=40)),
        ]
        pauses = [(start + timedelta(seconds=10), start + timedelta(seconds=30))]

        with self.assertRaises(RunSpeedValidationError):
            validate_run_speed(points, pauses=pauses)


if __name__ == "__main__":
    unittest.main()
