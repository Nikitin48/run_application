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
                  u.avatar_url,
                  u.territory_color,
                  ST_AsGeoJSON(t.geom)::text AS geojson,
                  ST_Area(ST_Transform(t.geom, 3857))::double precision AS area_m2,
                  COALESCE(us.run_count, 0) AS run_count,
                  COALESCE(us.total_distance_m, 0)::double precision AS total_distance_m,
                  COALESCE(us.total_elapsed_s, 0) AS total_elapsed_s,
                  COALESCE(us.total_paused_s, 0) AS total_paused_s,
                  COALESCE(us.total_moving_s, 0) AS total_moving_s,
                  COALESCE(
                    (
                      SELECT json_agg(ST_Area(ST_Transform(d.geom, 3857)) ORDER BY d.path)::text
                      FROM ST_Dump(t.geom) AS d
                    ),
                    '[]'
                  ) AS polygon_areas_m2_json
                FROM territories t
                JOIN users u ON u.id = t.user_id
                LEFT JOIN user_stats us ON us.user_id = t.user_id
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
                avatar_url,
                territory_color,
                geojson_text,
                area_m2,
                run_count,
                total_distance_m,
                total_elapsed_s,
                total_paused_s,
                total_moving_s,
                polygon_areas_m2_json,
            ) in cur.fetchall():
                features.append(
                    {
                        "type": "Feature",
                        "geometry": json.loads(geojson_text),
                        "properties": {
                            "user_id": user_id,
                            "display_name": display_name or "",
                            "avatar_url": avatar_url,
                            "territory_color": territory_color or "#3B82F6",
                            "area_m2": area_m2,
                            "stats": {
                                "run_count": run_count,
                                "total_distance_m": float(total_distance_m),
                                "total_elapsed_s": total_elapsed_s,
                                "total_paused_s": total_paused_s,
                                "total_moving_s": total_moving_s,
                                "owned_area_m2": area_m2,
                            },
                            "polygon_areas_m2": [
                                float(v) for v in json.loads(polygon_areas_m2_json)
                            ],
                        },
                    }
                )
    return {"type": "FeatureCollection", "features": features}


