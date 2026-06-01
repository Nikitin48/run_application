from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from ..dependencies.auth import current_user_id
from ..models import (
    LeaderboardEntryOut,
    LeaderboardMetric,
    LeaderboardResponseOut,
    LeaderboardScope,
)
from ..services.leaderboard_service import LeaderboardService

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])
service = LeaderboardService()


@router.get("", response_model=LeaderboardResponseOut)
def get_leaderboard(
    scope: LeaderboardScope = Query(default="country"),
    metric: LeaderboardMetric = Query(default="area"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user_id: str = Depends(current_user_id),
) -> LeaderboardResponseOut:
    rows, my_rank, my_score = service.get_leaderboard(
        user_id=user_id,
        scope=scope,
        metric=metric,
        limit=limit,
        offset=offset,
    )
    return LeaderboardResponseOut(
        scope=scope,
        metric=metric,
        entries=[
            LeaderboardEntryOut(
                rank=row.rank,
                user_id=row.user_id,
                display_name=row.display_name,
                avatar_url=row.avatar_url,
                country_code=row.country_code,
                region_code=row.region_code,
                city_code=row.city_code,
                total_distance_m=row.total_distance_m,
                owned_area_m2=row.owned_area_m2,
                score=row.score,
            )
            for row in rows
        ],
        my_rank=my_rank,
        my_score=my_score,
    )
