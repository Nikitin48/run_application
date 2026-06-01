from __future__ import annotations

import json

from fastapi import APIRouter, Query

from ..db import db_conn
from ..services.territory_maintenance import resolve_due_territory_contests


router = APIRouter(prefix="/territories", tags=["territories"])


@router.get("")
def get_territories(
    min_lng: float = Query(..., alias="minLng"),
    min_lat: float = Query(..., alias="minLat"),
    max_lng: float = Query(..., alias="maxLng"),
    max_lat: float = Query(..., alias="maxLat"),
) -> dict:
    with db_conn() as conn:
        resolve_due_territory_contests(conn)
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  t.id::text,
                  t.user_id::text,
                  u.display_name,
                  u.avatar_url,
                  u.territory_color,
                  ST_AsGeoJSON(t.geom)::text AS geojson,
                  ST_Area(ST_Transform(t.geom, 3857))::double precision AS area_m2,
                  t.status,
                  t.captured_at,
                  t.protected_until,
                  t.protection_duration_hours,
                  COALESCE(us.run_count, 0) AS run_count,
                  COALESCE(us.total_distance_m, 0)::double precision AS total_distance_m,
                  COALESCE(us.total_elapsed_s, 0) AS total_elapsed_s,
                  COALESCE(us.total_paused_s, 0) AS total_paused_s,
                  COALESCE(us.total_moving_s, 0) AS total_moving_s,
                  COALESCE(
                    us.owned_area_m2,
                    territory_owned_area_m2(t.user_id)
                  )::double precision AS owned_area_m2,
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
                territory_id,
                user_id,
                display_name,
                avatar_url,
                territory_color,
                geojson_text,
                area_m2,
                territory_status,
                captured_at,
                protected_until,
                protection_duration_hours,
                run_count,
                total_distance_m,
                total_elapsed_s,
                total_paused_s,
                total_moving_s,
                owned_area_m2,
                polygon_areas_m2_json,
            ) in cur.fetchall():
                features.append(
                    {
                        "type": "Feature",
                        "geometry": json.loads(geojson_text),
                        "properties": {
                            "feature_kind": "territory",
                            "territory_id": territory_id,
                            "user_id": user_id,
                            "display_name": display_name or "",
                            "avatar_url": avatar_url,
                            "territory_color": territory_color or "#3B82F6",
                            "area_m2": area_m2,
                            "status": territory_status,
                            "captured_at": captured_at.isoformat() if captured_at else None,
                            "protected_until": protected_until.isoformat()
                            if protected_until
                            else None,
                            "protection_duration_hours": protection_duration_hours,
                            "stats": {
                                "run_count": run_count,
                                "total_distance_m": float(total_distance_m),
                                "total_elapsed_s": total_elapsed_s,
                                "total_paused_s": total_paused_s,
                                "total_moving_s": total_moving_s,
                                "owned_area_m2": float(owned_area_m2),
                            },
                            "polygon_areas_m2": [
                                float(v) for v in json.loads(polygon_areas_m2_json)
                            ],
                        },
                    }
                )
            cur.execute(
                """
                SELECT
                  ca.id::text,
                  t.id::text AS territory_id,
                  t.user_id::text AS owner_user_id,
                  owner.display_name AS owner_display_name,
                  owner.avatar_url AS owner_avatar_url,
                  owner.territory_color AS owner_territory_color,
                  ST_AsGeoJSON(ca.geom)::text AS geojson,
                  ST_Area(ST_Transform(ca.geom, 3857))::double precision AS area_m2,
                  ca.current_winner_user_id::text,
                  winner.display_name AS current_winner_display_name,
                  winner.territory_color AS current_winner_territory_color,
                  ca.resolve_at,
                  COALESCE(
                    (
                      SELECT json_agg(
                        json_build_object(
                          'user_id', p.user_id::text,
                          'display_name', pu.display_name,
                          'territory_color', pu.territory_color
                        )
                        ORDER BY p.first_joined_at, p.user_id
                      )
                      FROM territory_contested_area_participants p
                      JOIN users pu ON pu.id = p.user_id
                      WHERE p.contested_area_id = ca.id
                    ),
                    '[]'::json
                  ) AS participants_json,
                  COALESCE(
                    (
                      SELECT json_agg(ST_Area(ST_Transform(d.geom, 3857)) ORDER BY d.path)::text
                      FROM ST_Dump(ca.geom) AS d
                    ),
                    '[]'
                  ) AS polygon_areas_m2_json
                FROM territory_contested_areas ca
                JOIN territories t ON t.id = ca.territory_id
                JOIN users owner ON owner.id = t.user_id
                LEFT JOIN users winner ON winner.id = ca.current_winner_user_id
                WHERE ST_Intersects(
                  ca.geom,
                  ST_MakeEnvelope(%s, %s, %s, %s, 4326)
                )
                """,
                (min_lng, min_lat, max_lng, max_lat),
            )
            for (
                contested_area_id,
                territory_id,
                owner_user_id,
                owner_display_name,
                owner_avatar_url,
                owner_territory_color,
                geojson_text,
                area_m2,
                current_winner_user_id,
                current_winner_display_name,
                current_winner_territory_color,
                resolve_at,
                participants_json,
                polygon_areas_m2_json,
            ) in cur.fetchall():
                participants = [
                    {
                        "user_id": str(item.get("user_id") or ""),
                        "display_name": item.get("display_name") or "",
                        "territory_color": item.get("territory_color") or "#3B82F6",
                    }
                    for item in (participants_json or [])
                    if isinstance(item, dict)
                ]
                features.append(
                    {
                        "type": "Feature",
                        "geometry": json.loads(geojson_text),
                        "properties": {
                            "feature_kind": "contested_area",
                            "contested_area_id": contested_area_id,
                            "territory_id": territory_id,
                            "user_id": owner_user_id,
                            "display_name": owner_display_name or "",
                            "avatar_url": owner_avatar_url,
                            "territory_color": owner_territory_color or "#3B82F6",
                            "area_m2": area_m2,
                            "status": "contested",
                            "resolve_at": resolve_at.isoformat() if resolve_at else None,
                            "current_winner_user_id": current_winner_user_id,
                            "current_winner_display_name": current_winner_display_name or "",
                            "current_winner_territory_color": current_winner_territory_color
                            or "#3B82F6",
                            "participants": participants,
                            "polygon_areas_m2": [
                                float(v) for v in json.loads(polygon_areas_m2_json)
                            ],
                        },
                    }
                )
    return {"type": "FeatureCollection", "features": features}


