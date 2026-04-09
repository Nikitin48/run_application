from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query

from ..db import db_conn
from ..models import CityItemOut, CountryItemOut, RegionItemOut
from .me import current_user_id

router = APIRouter(prefix="/locations", tags=["locations"])


@router.get("/countries", response_model=list[CountryItemOut])
def list_countries(user_id: str = Depends(current_user_id)) -> list[CountryItemOut]:
    _ = user_id
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT code, name
                FROM ref_countries
                WHERE is_active = true
                ORDER BY name
                """
            )
            return [CountryItemOut(code=row[0], name=row[1]) for row in cur.fetchall()]


@router.get("/regions", response_model=list[RegionItemOut])
def list_regions(
    query: str = Query(default="", max_length=80),
    country_code: str = Query(default="RU", min_length=2, max_length=8),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    user_id: str = Depends(current_user_id),
) -> list[RegionItemOut]:
    _ = user_id
    if country_code != "RU":
        raise HTTPException(status_code=422, detail="only RU country is supported")
    search = f"%{query.strip().lower()}%"
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT code, name, country_code
                FROM ref_regions
                WHERE is_active = true
                  AND country_code = %s
                  AND (%s = '%%' OR normalized_name LIKE %s)
                ORDER BY name
                LIMIT %s
                OFFSET %s
                """,
                (country_code, search, search, limit, offset),
            )
            return [RegionItemOut(code=row[0], name=row[1], country_code=row[2]) for row in cur.fetchall()]


@router.get("/cities", response_model=list[CityItemOut])
def list_cities(
    region_code: str = Query(min_length=2, max_length=32),
    query: str = Query(default="", max_length=80),
    country_code: str = Query(default="RU", min_length=2, max_length=8),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    user_id: str = Depends(current_user_id),
) -> list[CityItemOut]:
    _ = user_id
    if country_code != "RU":
        raise HTTPException(status_code=422, detail="only RU country is supported")
    search = f"%{query.strip().lower()}%"
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT code, name, country_code, region_code
                FROM ref_cities
                WHERE is_active = true
                  AND country_code = %s
                  AND region_code = %s
                  AND (%s = '%%' OR normalized_name LIKE %s)
                ORDER BY name
                LIMIT %s
                OFFSET %s
                """,
                (country_code, region_code, search, search, limit, offset),
            )
            return [
                CityItemOut(
                    code=row[0],
                    name=row[1],
                    country_code=row[2],
                    region_code=row[3],
                )
                for row in cur.fetchall()
            ]
