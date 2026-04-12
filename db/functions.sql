-- PostGIS functions:
-- 1) compute_capture_polygons(track_line, tol_m, min_area_m2)
--    - builds all enclosed areas (MultiPolygon) from a run track
--    - handles "figure-eight" (returns multiple polygons)
--    - uses self-snapping with tol_m so "almost" closures become real nodes
-- 2) finalize_run_capture(run_id, tol_m, min_area_m2)
--    - computes capture polygons for the run
--    - repaints ownership: victims lose intersection, runner gains the capture
--    - writes notification history for victims
--    - updates user_stats for runner and victims touched
--
-- Requires:
--   CREATE EXTENSION IF NOT EXISTS postgis;
--   CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

CREATE OR REPLACE FUNCTION compute_capture_polygons(
  p_track_line geometry,
  p_tol_m double precision DEFAULT 10,
  p_min_area_m2 double precision DEFAULT 150
)
RETURNS geometry
LANGUAGE plpgsql
AS $$
DECLARE
  line_m geometry;
  snapped geometry;
  noded geometry;
  poly_coll geometry;
  poly_m geometry;
  filtered_m geometry;
  filtered_4326 geometry;
BEGIN
  IF p_track_line IS NULL OR ST_IsEmpty(p_track_line) THEN
    RETURN ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326);
  END IF;

  -- Work in meters (WebMercator). For MVP this is acceptable; can be refined later.
  line_m := ST_Transform(p_track_line, 3857);

  -- Snap the line to itself so near-intersections become nodes.
  snapped := ST_Snap(line_m, line_m, p_tol_m);

  -- Node the linework (split at intersections).
  noded := ST_Node(snapped);

  -- Polygonize: produce faces (supports figure-eight -> multiple polygons).
  poly_coll := ST_Polygonize(noded);

  -- Extract polygons, make valid, unify.
  poly_m := ST_CollectionExtract(ST_MakeValid(ST_UnaryUnion(poly_coll)), 3);

  IF poly_m IS NULL OR ST_IsEmpty(poly_m) THEN
    RETURN ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326);
  END IF;

  -- Filter tiny polygons by area (still in meters).
  filtered_m := (
    SELECT COALESCE(
      ST_Multi(ST_Union(geom)),
      ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 3857)
    )
    FROM (
      SELECT (ST_Dump(poly_m)).geom AS geom
    ) d
    WHERE ST_Area(d.geom) >= p_min_area_m2
  );

  IF filtered_m IS NULL OR ST_IsEmpty(filtered_m) THEN
    RETURN ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326);
  END IF;

  filtered_4326 := ST_Transform(filtered_m, 4326);
  RETURN ST_Multi(ST_CollectionExtract(ST_MakeValid(filtered_4326), 3));
END;
$$;


CREATE OR REPLACE FUNCTION finalize_run_capture(
  p_run_id uuid,
  p_tol_m double precision DEFAULT 10,
  p_min_area_m2 double precision DEFAULT 150
)
RETURNS TABLE(
  capture_area_m2 double precision,
  victims_count integer
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_runner_id uuid;
  v_line geometry;
  v_capture geometry;
  v_capture_m geometry;
  v_area_m2 double precision;
  v_distance_m double precision;
  v_elapsed_s integer;
  v_paused_s integer;
  v_moving_s integer;
  v_now timestamptz := now();
  v_victims int := 0;
  v_row record;
  v_stolen geometry;
  v_stolen_area double precision;
  v_victim_new geometry;
BEGIN
  SELECT r.user_id, r.track_line
  INTO v_runner_id, v_line
  FROM runs r
  WHERE r.id = p_run_id;

  IF v_runner_id IS NULL THEN
    RAISE EXCEPTION 'run % not found', p_run_id;
  END IF;

  -- Load run metrics (fallbacks are allowed).
  SELECT
    COALESCE(r.distance_m, 0),
    COALESCE(
      r.elapsed_s,
      CASE
        WHEN r.started_at IS NOT NULL AND r.ended_at IS NOT NULL
          THEN GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (r.ended_at - r.started_at)))::int)
        ELSE 0
      END
    ),
    COALESCE(r.paused_s, 0),
    COALESCE(r.moving_s, NULL)
  INTO v_distance_m, v_elapsed_s, v_paused_s, v_moving_s
  FROM runs r
  WHERE r.id = p_run_id;

  IF v_moving_s IS NULL THEN
    v_moving_s := GREATEST(0, v_elapsed_s - v_paused_s);
  END IF;

  v_capture := compute_capture_polygons(v_line, p_tol_m, p_min_area_m2);
  IF v_capture IS NULL OR ST_IsEmpty(v_capture) THEN
    -- Even runs without territory capture must be fully processed and counted in stats.
    UPDATE runs
    SET status = 'processed',
        elapsed_s = v_elapsed_s,
        paused_s = v_paused_s,
        moving_s = v_moving_s,
        updated_at = v_now
    WHERE id = p_run_id;

    INSERT INTO user_stats(
      user_id,
      run_count,
      total_distance_m,
      total_elapsed_s,
      total_paused_s,
      total_moving_s,
      successful_captures_count,
      total_captured_area_m2,
      total_victims_count,
      owned_area_m2,
      updated_at
    )
    VALUES (
      v_runner_id,
      1,
      v_distance_m,
      v_elapsed_s,
      v_paused_s,
      v_moving_s,
      0,
      0,
      0,
      COALESCE((SELECT ST_Area(ST_Transform(geom, 3857)) FROM territories WHERE user_id = v_runner_id), 0),
      v_now
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      run_count = user_stats.run_count + 1,
      total_distance_m = user_stats.total_distance_m + v_distance_m,
      total_elapsed_s = user_stats.total_elapsed_s + v_elapsed_s,
      total_paused_s = user_stats.total_paused_s + v_paused_s,
      total_moving_s = user_stats.total_moving_s + v_moving_s,
      owned_area_m2 = COALESCE((SELECT ST_Area(ST_Transform(geom, 3857)) FROM territories WHERE user_id = v_runner_id), 0),
      updated_at = v_now;

    capture_area_m2 := 0;
    victims_count := 0;
    RETURN NEXT;
    RETURN;
  END IF;

  v_capture_m := ST_Transform(v_capture, 3857);
  v_area_m2 := ST_Area(v_capture_m);

  -- Temp accumulator per victim (sum stolen area).
  CREATE TEMP TABLE IF NOT EXISTS tmp_victim_stolen (
    victim_user_id uuid PRIMARY KEY,
    stolen_area_m2 double precision NOT NULL DEFAULT 0
  ) ON COMMIT DROP;

  TRUNCATE tmp_victim_stolen;

  -- Lock runner territory row (if exists) to prevent races.
  PERFORM 1
  FROM territories t
  WHERE t.user_id = v_runner_id
  FOR UPDATE;

  -- Lock and process all victims whose territory intersects with capture (excluding runner).
  FOR v_row IN
    SELECT t.user_id, t.geom
    FROM territories t
    WHERE t.user_id <> v_runner_id
      AND ST_Intersects(t.geom, v_capture)
    FOR UPDATE
  LOOP
    v_stolen := ST_Intersection(v_row.geom, v_capture);
    v_stolen := ST_Multi(ST_CollectionExtract(ST_MakeValid(v_stolen), 3));

    IF v_stolen IS NULL OR ST_IsEmpty(v_stolen) THEN
      CONTINUE;
    END IF;

    v_stolen_area := ST_Area(ST_Transform(v_stolen, 3857));
    IF v_stolen_area < p_min_area_m2 THEN
      CONTINUE;
    END IF;

    -- Accumulate victim stolen area
    INSERT INTO tmp_victim_stolen(victim_user_id, stolen_area_m2)
    VALUES (v_row.user_id, v_stolen_area)
    ON CONFLICT (victim_user_id)
    DO UPDATE SET stolen_area_m2 = tmp_victim_stolen.stolen_area_m2 + EXCLUDED.stolen_area_m2;

    -- Remove captured area from victim territory
    v_victim_new := ST_Difference(v_row.geom, v_capture);
    v_victim_new := ST_Multi(ST_CollectionExtract(ST_MakeValid(v_victim_new), 3));

    IF v_victim_new IS NULL OR ST_IsEmpty(v_victim_new) THEN
      DELETE FROM territories WHERE user_id = v_row.user_id;
    ELSE
      -- Remove dust after difference
      v_victim_new := (
        SELECT COALESCE(
          ST_Multi(ST_Union(geom)),
          ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326)
        )
        FROM (
          SELECT (ST_Dump(v_victim_new)).geom AS geom
        ) d
        WHERE ST_Area(ST_Transform(d.geom, 3857)) >= p_min_area_m2
      );

      IF v_victim_new IS NULL OR ST_IsEmpty(v_victim_new) THEN
        DELETE FROM territories WHERE user_id = v_row.user_id;
      ELSE
        UPDATE territories
        SET geom = v_victim_new,
            updated_at = v_now
        WHERE user_id = v_row.user_id;
      END IF;
    END IF;
  END LOOP;

  -- Ensure runner has a territory row (upsert).
  INSERT INTO territories(user_id, geom, updated_at)
  VALUES (v_runner_id, ST_Multi(v_capture), v_now)
  ON CONFLICT (user_id)
  DO UPDATE SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(territories.geom, EXCLUDED.geom)), 3)),
                updated_at = v_now;

  -- Update runs table status
  UPDATE runs
  SET status = 'processed',
      elapsed_s = v_elapsed_s,
      paused_s = v_paused_s,
      moving_s = v_moving_s,
      updated_at = v_now
  WHERE id = p_run_id;

  -- Append notification history for victims.
  INSERT INTO user_notifications(
    user_id, kind, attacker_user_id, run_id, stolen_area_m2, payload, created_at
  )
  SELECT
    tvs.victim_user_id,
    'territory_stolen',
    v_runner_id,
    p_run_id,
    tvs.stolen_area_m2,
    jsonb_build_object('stolen_area_m2', tvs.stolen_area_m2),
    v_now
  FROM tmp_victim_stolen tvs;

  -- Keep only the latest 10 notifications per affected user.
  DELETE FROM user_notifications un
  USING (
    SELECT id
    FROM (
      SELECT
        n.id,
        ROW_NUMBER() OVER (
          PARTITION BY n.user_id
          ORDER BY n.created_at DESC, n.id DESC
        ) AS rn
      FROM user_notifications n
      WHERE n.user_id IN (SELECT victim_user_id FROM tmp_victim_stolen)
    ) ranked
    WHERE ranked.rn > 10
  ) old
  WHERE un.id = old.id;

  SELECT COUNT(*) INTO v_victims FROM tmp_victim_stolen;

  -- Update stats (runner + victims touched)
  -- Runner: increment run_count + distance, recompute owned area from territories.
  INSERT INTO user_stats(
    user_id,
    run_count,
    total_distance_m,
    total_elapsed_s,
    total_paused_s,
    total_moving_s,
    successful_captures_count,
    total_captured_area_m2,
    total_victims_count,
    owned_area_m2,
    updated_at
  )
  VALUES (
    v_runner_id,
    1,
    v_distance_m,
    v_elapsed_s,
    v_paused_s,
    v_moving_s,
    1,
    v_area_m2,
    v_victims,
    COALESCE((SELECT ST_Area(ST_Transform(geom, 3857)) FROM territories WHERE user_id = v_runner_id), 0),
    v_now
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    run_count = user_stats.run_count + 1,
    total_distance_m = user_stats.total_distance_m + v_distance_m,
    total_elapsed_s = user_stats.total_elapsed_s + v_elapsed_s,
    total_paused_s = user_stats.total_paused_s + v_paused_s,
    total_moving_s = user_stats.total_moving_s + v_moving_s,
    successful_captures_count = user_stats.successful_captures_count + 1,
    total_captured_area_m2 = user_stats.total_captured_area_m2 + v_area_m2,
    total_victims_count = user_stats.total_victims_count + v_victims,
    owned_area_m2 = COALESCE((SELECT ST_Area(ST_Transform(geom, 3857)) FROM territories WHERE user_id = v_runner_id), 0),
    updated_at = v_now;

  -- Victims: recompute owned_area_m2 only (distance/run_count unchanged here).
  UPDATE user_stats us
  SET owned_area_m2 = COALESCE((SELECT ST_Area(ST_Transform(t.geom, 3857)) FROM territories t WHERE t.user_id = us.user_id), 0),
      updated_at = v_now
  WHERE us.user_id IN (SELECT victim_user_id FROM tmp_victim_stolen);

  -- Victims that don't have a stats row yet:
  INSERT INTO user_stats(
    user_id,
    run_count,
    total_distance_m,
    total_elapsed_s,
    total_paused_s,
    total_moving_s,
    owned_area_m2,
    updated_at
  )
  SELECT
    tvs.victim_user_id,
    0,
    0,
    0,
    0,
    0,
    COALESCE((SELECT ST_Area(ST_Transform(t.geom, 3857)) FROM territories t WHERE t.user_id = tvs.victim_user_id), 0),
    v_now
  FROM tmp_victim_stolen tvs
  ON CONFLICT (user_id) DO NOTHING;

  capture_area_m2 := v_area_m2;
  victims_count := v_victims;
  RETURN NEXT;
END;
$$;

COMMIT;


