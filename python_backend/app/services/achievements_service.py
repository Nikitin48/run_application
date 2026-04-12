from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any


LEVEL_THRESHOLDS: tuple[tuple[int, int], ...] = (
    (1, 0),
    (2, 300),
    (3, 700),
    (4, 1300),
    (5, 2200),
    (6, 3400),
    (7, 4900),
    (8, 6700),
    (9, 8800),
    (10, 11200),
)


@dataclass(frozen=True)
class AchievementDefinition:
    id: Any
    code: str
    title: str
    description: str
    category: str
    icon_key: str
    xp: int
    rule_type: str
    rule_value: float
    sort_order: int


@dataclass(frozen=True)
class AchievementUnlocked:
    code: str
    title: str
    description: str
    category: str
    icon_key: str
    xp: int
    unlocked_at: datetime


@dataclass(frozen=True)
class AchievementCatalogItem:
    code: str
    title: str
    description: str
    category: str
    icon_key: str
    xp: int
    sort_order: int
    is_unlocked: bool
    unlocked_at: datetime | None


@dataclass(frozen=True)
class AchievementEvaluationResult:
    new_achievements: list[AchievementUnlocked]
    profile_xp: int
    profile_level: int
    old_level: int


def get_level_for_xp(xp: int) -> int:
    level = 1
    for candidate_level, threshold in LEVEL_THRESHOLDS:
        if xp >= threshold:
            level = candidate_level
        else:
            break
    return level


def evaluate_user_achievements(
    conn,
    *,
    user_id: str,
    run_id: str | None = None,
) -> AchievementEvaluationResult:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              COALESCE(run_count, 0),
              COALESCE(total_distance_m, 0),
              COALESCE(successful_captures_count, 0),
              COALESCE(total_captured_area_m2, 0),
              COALESCE(total_victims_count, 0),
              COALESCE(owned_area_m2, 0),
              COALESCE(profile_level, 1)
            FROM user_stats
            WHERE user_id = %s
            """,
            (user_id,),
        )
        stats_row = cur.fetchone()
        if stats_row is None:
            metrics = {
                "run_count": 0.0,
                "distance_total": 0.0,
                "captures_count": 0.0,
                "capture_total": 0.0,
                "victims_total": 0.0,
                "owned_area": 0.0,
            }
            old_level = 1
        else:
            metrics = {
                "run_count": float(stats_row[0]),
                "distance_total": float(stats_row[1]),
                "captures_count": float(stats_row[2]),
                "capture_total": float(stats_row[3]),
                "victims_total": float(stats_row[4]),
                "owned_area": float(stats_row[5]),
            }
            old_level = int(stats_row[6])

        single_distance = 0.0
        single_capture = 0.0
        single_victims = 0.0
        if run_id:
            cur.execute(
                """
                SELECT
                  COALESCE(distance_m, 0),
                  COALESCE(capture_area_m2, 0),
                  COALESCE(victims_count, 0)
                FROM runs
                WHERE id = %s AND user_id = %s
                """,
                (run_id, user_id),
            )
            run_row = cur.fetchone()
            if run_row is not None:
                single_distance = float(run_row[0])
                single_capture = float(run_row[1])
                single_victims = float(run_row[2])

        metrics["distance_single"] = single_distance
        metrics["capture_single"] = single_capture
        metrics["victims_single"] = single_victims

        cur.execute(
            """
            SELECT
              id,
              code,
              title,
              description,
              category,
              icon_key,
              xp,
              rule_type,
              rule_value,
              sort_order
            FROM achievement_definitions
            ORDER BY sort_order ASC, code ASC
            """
        )
        definitions = [
            AchievementDefinition(
                id=row[0],
                code=str(row[1]),
                title=str(row[2]),
                description=str(row[3]),
                category=str(row[4]),
                icon_key=str(row[5]),
                xp=int(row[6]),
                rule_type=str(row[7]),
                rule_value=float(row[8]),
                sort_order=int(row[9]),
            )
            for row in cur.fetchall()
        ]

        cur.execute(
            """
            SELECT achievement_id
            FROM user_achievements
            WHERE user_id = %s
            """,
            (user_id,),
        )
        earned_ids = {row[0] for row in cur.fetchall()}

        unlocked_now: list[AchievementUnlocked] = []
        for definition in definitions:
            if definition.id in earned_ids:
                continue
            metric_value = _metric_value_for_rule(metrics, definition.rule_type)
            if metric_value < definition.rule_value:
                continue
            cur.execute(
                """
                INSERT INTO user_achievements(user_id, achievement_id, source_run_id)
                VALUES (%s, %s, %s)
                RETURNING unlocked_at
                """,
                (user_id, definition.id, run_id),
            )
            unlocked_at = cur.fetchone()[0]
            unlocked_now.append(
                AchievementUnlocked(
                    code=definition.code,
                    title=definition.title,
                    description=definition.description,
                    category=definition.category,
                    icon_key=definition.icon_key,
                    xp=definition.xp,
                    unlocked_at=unlocked_at,
                )
            )

        cur.execute(
            """
            SELECT COALESCE(SUM(ad.xp), 0)
            FROM user_achievements ua
            JOIN achievement_definitions ad ON ad.id = ua.achievement_id
            WHERE ua.user_id = %s
            """,
            (user_id,),
        )
        profile_xp = int(cur.fetchone()[0] or 0)
        profile_level = get_level_for_xp(profile_xp)

        cur.execute(
            """
            INSERT INTO user_stats(user_id, profile_xp, profile_level, updated_at)
            VALUES (%s, %s, %s, now())
            ON CONFLICT (user_id)
            DO UPDATE SET
              profile_xp = EXCLUDED.profile_xp,
              profile_level = EXCLUDED.profile_level,
              updated_at = now()
            """,
            (user_id, profile_xp, profile_level),
        )

    return AchievementEvaluationResult(
        new_achievements=unlocked_now,
        profile_xp=profile_xp,
        profile_level=profile_level,
        old_level=old_level,
    )


def list_user_achievements(conn, *, user_id: str) -> tuple[int, int, list[AchievementCatalogItem]]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              COALESCE(us.profile_xp, 0),
              COALESCE(us.profile_level, 1)
            FROM users u
            LEFT JOIN user_stats us ON us.user_id = u.id
            WHERE u.id = %s
            """,
            (user_id,),
        )
        stats_row = cur.fetchone()
        if stats_row is None:
            raise ValueError("user not found")
        profile_xp = int(stats_row[0])
        profile_level = int(stats_row[1])

        cur.execute(
            """
            SELECT
              ad.code,
              ad.title,
              ad.description,
              ad.category,
              ad.icon_key,
              ad.xp,
              ad.sort_order,
              ua.unlocked_at
            FROM achievement_definitions ad
            LEFT JOIN user_achievements ua
              ON ua.achievement_id = ad.id
             AND ua.user_id = %s
            ORDER BY
              CASE WHEN ua.unlocked_at IS NULL THEN 1 ELSE 0 END,
              ad.sort_order ASC,
              ad.code ASC
            """,
            (user_id,),
        )
        items = [
            AchievementCatalogItem(
                code=str(row[0]),
                title=str(row[1]),
                description=str(row[2]),
                category=str(row[3]),
                icon_key=str(row[4]),
                xp=int(row[5]),
                sort_order=int(row[6]),
                is_unlocked=row[7] is not None,
                unlocked_at=row[7],
            )
            for row in cur.fetchall()
        ]
    return profile_xp, profile_level, items


def _metric_value_for_rule(metrics: dict[str, float], rule_type: str) -> float:
    return {
        "run_count_gte": metrics["run_count"],
        "distance_single_gte": metrics["distance_single"],
        "distance_total_gte": metrics["distance_total"],
        "capture_single_gte": metrics["capture_single"],
        "capture_total_gte": metrics["capture_total"],
        "captures_count_gte": metrics["captures_count"],
        "victims_single_gte": metrics["victims_single"],
        "victims_total_gte": metrics["victims_total"],
        "owned_area_gte": metrics["owned_area"],
    }.get(rule_type, -1)
