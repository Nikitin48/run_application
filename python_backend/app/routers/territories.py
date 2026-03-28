from __future__ import annotations

import json

from fastapi import APIRouter, Query

from ..db import db_conn


router = APIRouter(prefix="/territories", tags=["territories"])


@router.get("")
def get_territories(
    min_lng: float = Query(..., alias="minLng"),
    min_lat: float = Query(..., alias="minLat"),
    max_lng: float = Query(..., alias="maxLng"),
    max_lat: float = Query(..., alias="maxLat"),
) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  t.user_id::text,
                  u.display_name,
                  u.territory_color,
                  ST_AsGeoJSON(t.geom)::text AS geojson,
                  ST_Area(ST_Transform(t.geom, 3857))::double precision AS area_m2
                FROM territories t
                JOIN users u ON u.id = t.user_id
                WHERE ST_Intersects(
                  t.geom,
                  ST_MakeEnvelope(%s, %s, %s, %s, 4326)
                )
                """,
                (min_lng, min_lat, max_lng, max_lat),
            )
            features = []
            for (
                user_id,
                display_name,
                territory_color,
                geojson_text,
                area_m2,
            ) in cur.fetchall():
                features.append(
                    {
                        "type": "Feature",
                        "geometry": json.loads(geojson_text),
                        "properties": {
                            "user_id": user_id,
                            "display_name": display_name or "",
                            "territory_color": territory_color or "#3B82F6",
                            "area_m2": area_m2,
                        },
                    }
                )
    return {"type": "FeatureCollection", "features": features}


