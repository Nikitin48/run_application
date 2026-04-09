from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from fastapi import HTTPException

from ..db import db_conn
from ..repositories.leaderboard_repo import LeaderboardRepository

Scope = Literal["city", "region", "country"]
Metric = Literal["area", "distance"]


@dataclass(frozen=True)
class LeaderboardContext:
    country_code: str
    region_code: str | None
    city_code: str | None


class LeaderboardService:
    def __init__(self, repo: LeaderboardRepository | None = None) -> None:
        self._repo = repo or LeaderboardRepository()

    def get_user_context(self, *, user_id: str) -> LeaderboardContext:
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
                row = cur.fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="user not found")
        return LeaderboardContext(country_code=row[0], region_code=row[1], city_code=row[2])

    def get_leaderboard(
        self,
        *,
        user_id: str,
        scope: Scope,
        metric: Metric,
        limit: int,
        offset: int,
    ) -> tuple[list, int | None, float | None]:
        context = self.get_user_context(user_id=user_id)
        if scope == "country":
            country_code = "RU"
            region_code = None
            city_code = None
        elif scope == "region":
            if not context.region_code:
                raise HTTPException(status_code=422, detail="set region in profile first")
            country_code = context.country_code
            region_code = context.region_code
            city_code = None
        else:
            if not context.region_code or not context.city_code:
                raise HTTPException(status_code=422, detail="set city in profile first")
            country_code = context.country_code
            region_code = context.region_code
            city_code = context.city_code

        entries = self._repo.fetch_entries(
            scope=scope,
            metric=metric,
            country_code=country_code,
            region_code=region_code,
            city_code=city_code,
            limit=limit,
            offset=offset,
        )
        my_rank = self._repo.fetch_my_rank(
            user_id=user_id,
            scope=scope,
            metric=metric,
            country_code=country_code,
            region_code=region_code,
            city_code=city_code,
        )
        if my_rank is None:
            return entries, None, None
        return entries, my_rank[0], my_rank[1]
