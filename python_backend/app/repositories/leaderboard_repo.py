from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from ..db import db_conn

Scope = Literal["city", "region", "country"]
Metric = Literal["area", "distance"]


@dataclass(frozen=True)
class LeaderboardRow:
    rank: int
    user_id: str
    display_name: str
    avatar_url: str | None
    country_code: str
    region_code: str | None
    city_code: str | None
    total_distance_m: float
    owned_area_m2: float
    score: float


class LeaderboardRepository:
    def fetch_entries(
        self,
        *,
        scope: Scope,
        metric: Metric,
        country_code: str,
        region_code: str | None,
        city_code: str | None,
        limit: int,
        offset: int,
    ) -> list[LeaderboardRow]:
        where_sql = "u.country_code = %s"
        where_params: list[object] = [country_code]
        if scope == "region":
            where_sql += " AND u.region_code = %s"
            where_params.append(region_code)
        elif scope == "city":
            where_sql += " AND u.city_code = %s"
            where_params.append(city_code)

        score_sql = "COALESCE(us.owned_area_m2, 0)" if metric == "area" else "COALESCE(us.total_distance_m, 0)"

        sql = f"""
            WITH ranked AS (
              SELECT
                ROW_NUMBER() OVER (
                  ORDER BY {score_sql} DESC, u.updated_at DESC, u.id ASC
                ) AS rank,
                u.id::text AS user_id,
                u.display_name,
                u.avatar_url,
                u.country_code,
                u.region_code,
                u.city_code,
                COALESCE(us.total_distance_m, 0) AS total_distance_m,
                COALESCE(us.owned_area_m2, 0) AS owned_area_m2,
                {score_sql} AS score
              FROM users u
              LEFT JOIN user_stats us ON us.user_id = u.id
              WHERE {where_sql}
            )
            SELECT
              rank,
              user_id,
              display_name,
              avatar_url,
              country_code,
              region_code,
              city_code,
              total_distance_m,
              owned_area_m2,
              score
            FROM ranked
            ORDER BY rank
            LIMIT %s OFFSET %s
        """

        params = [*where_params, limit, offset]
        with db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()
        return [
            LeaderboardRow(
                rank=int(row[0]),
                user_id=row[1],
                display_name=row[2],
                avatar_url=row[3],
                country_code=row[4],
                region_code=row[5],
                city_code=row[6],
                total_distance_m=float(row[7]),
                owned_area_m2=float(row[8]),
                score=float(row[9]),
            )
            for row in rows
        ]

    def fetch_my_rank(
        self,
        *,
        user_id: str,
        scope: Scope,
        metric: Metric,
        country_code: str,
        region_code: str | None,
        city_code: str | None,
    ) -> tuple[int, float] | None:
        where_sql = "u.country_code = %s"
        where_params: list[object] = [country_code]
        if scope == "region":
            where_sql += " AND u.region_code = %s"
            where_params.append(region_code)
        elif scope == "city":
            where_sql += " AND u.city_code = %s"
            where_params.append(city_code)

        score_sql = "COALESCE(us.owned_area_m2, 0)" if metric == "area" else "COALESCE(us.total_distance_m, 0)"
        sql = f"""
            WITH ranked AS (
              SELECT
                ROW_NUMBER() OVER (
                  ORDER BY {score_sql} DESC, u.updated_at DESC, u.id ASC
                ) AS rank,
                u.id::text AS user_id,
                {score_sql} AS score
              FROM users u
              LEFT JOIN user_stats us ON us.user_id = u.id
              WHERE {where_sql}
            )
            SELECT rank, score
            FROM ranked
            WHERE user_id = %s
            LIMIT 1
        """
        with db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, [*where_params, user_id])
                row = cur.fetchone()
        if row is None:
            return None
        return int(row[0]), float(row[1])
