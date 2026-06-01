-- PostGIS functions:
-- 1) compute_capture_polygons(track_line, tol_m, min_area_m2)
--    - builds all enclosed areas (MultiPolygon) from a run track
--    - handles "figure-eight" (returns multiple polygons)
--    - uses self-snapping with tol_m so "almost" closures become real nodes
-- 2) finalize_run_capture(run_id, tol_m, min_area_m2)
--    - computes capture polygons for the run
--    - creates contested areas on protected territories
--    - instantly transfers intersections with vulnerable territories
--    - merges adjacent/overlapping vulnerable fragments of the same user
--    - writes notification history for attacked owners
--    - updates user_stats for runner and affected owners
--
-- Requires:
--   CREATE EXTENSION IF NOT EXISTS postgis;
--   CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

CREATE OR REPLACE FUNCTION compute_capture_polygons(
  p_track_line geometry,
  p_tol_m double precision DEFAULT 10,
  p_min_area_m2 double precision DEFAULT 5000
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


CREATE OR REPLACE FUNCTION territory_clean_multipolygon(
  p_geom geometry,
  p_min_area_m2 double precision DEFAULT 5000
)
RETURNS geometry
LANGUAGE plpgsql
AS $$
DECLARE
  v_clean geometry;
BEGIN
  IF p_geom IS NULL OR ST_IsEmpty(p_geom) THEN
    RETURN ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326);
  END IF;

  p_geom := ST_Multi(ST_CollectionExtract(ST_MakeValid(p_geom), 3));
  IF p_geom IS NULL OR ST_IsEmpty(p_geom) THEN
    RETURN ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326);
  END IF;

  v_clean := (
    SELECT COALESCE(
      ST_Multi(ST_Union(geom)),
      ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326)
    )
    FROM (
      SELECT (ST_Dump(p_geom)).geom AS geom
    ) d
    WHERE ST_Area(ST_Transform(d.geom, 3857)) >= p_min_area_m2
  );

  RETURN COALESCE(v_clean, ST_SetSRID('MULTIPOLYGON EMPTY'::geometry, 4326));
END;
$$;


CREATE OR REPLACE FUNCTION territory_owned_area_m2(p_user_id uuid)
RETURNS double precision
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(ST_Area(ST_Transform(t.geom, 3857))), 0)::double precision
  FROM territories t
  WHERE t.user_id = p_user_id
$$;


CREATE OR REPLACE FUNCTION territory_merge_adjacent_fragments(
  p_user_id uuid,
  p_min_area_m2 double precision DEFAULT 5000
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_now timestamptz := now();
  v_merged_pairs integer := 0;
  v_pair record;
  v_union geometry;
BEGIN
  -- Merge only vulnerable fragments (protection expired). Protected pieces stay
  -- separate even if they touch, until all involved timers expire.
  LOOP
    SELECT
      t1.id AS keep_id,
      t2.id AS drop_id,
      t1.geom AS geom1,
      t2.geom AS geom2,
      t1.protected_until AS protected_until1,
      t2.protected_until AS protected_until2,
      t1.protection_duration_hours AS protection_hours1,
      t2.protection_duration_hours AS protection_hours2,
      t1.captured_at AS captured_at1,
      t2.captured_at AS captured_at2
    INTO v_pair
    FROM territories t1
    JOIN territories t2
      ON t1.user_id = t2.user_id
     AND t1.id < t2.id
    WHERE t1.user_id = p_user_id
      AND t1.protected_until <= v_now
      AND t2.protected_until <= v_now
      AND ST_Intersects(t1.geom, t2.geom)
    ORDER BY t1.id, t2.id
    LIMIT 1
    FOR UPDATE OF t1, t2;

    EXIT WHEN NOT FOUND;

    v_union := territory_clean_multipolygon(
      ST_Union(v_pair.geom1, v_pair.geom2),
      p_min_area_m2
    );

    IF v_union IS NULL OR ST_IsEmpty(v_union) THEN
      EXIT;
    END IF;

    UPDATE territory_contested_areas
    SET territory_id = v_pair.keep_id,
        updated_at = v_now
    WHERE territory_id = v_pair.drop_id;

    UPDATE territories
    SET geom = v_union,
        protected_until = GREATEST(v_pair.protected_until1, v_pair.protected_until2),
        protection_duration_hours = GREATEST(
          v_pair.protection_hours1,
          v_pair.protection_hours2
        ),
        captured_at = LEAST(v_pair.captured_at1, v_pair.captured_at2),
        updated_at = v_now
    WHERE id = v_pair.keep_id;

    DELETE FROM territories WHERE id = v_pair.drop_id;
    v_merged_pairs := v_merged_pairs + 1;
  END LOOP;

  RETURN v_merged_pairs;
END;
$$;


CREATE OR REPLACE FUNCTION territory_merge_all_vulnerable_adjacent(
  p_min_area_m2 double precision DEFAULT 5000
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_user record;
  v_total integer := 0;
  v_merged integer;
BEGIN
  FOR v_user IN
    SELECT user_id
    FROM territories
    GROUP BY user_id
    HAVING COUNT(*) > 1
  LOOP
    v_merged := territory_merge_adjacent_fragments(v_user.user_id, p_min_area_m2);
    v_total := v_total + v_merged;
  END LOOP;

  RETURN v_total;
END;
$$;


CREATE OR REPLACE FUNCTION refresh_territory_statuses()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_now timestamptz := now();
BEGIN
  -- Fragment status reflects protection timer only. Contested intersections
  -- are stored separately in territory_contested_areas.
  UPDATE territories t
  SET status = CASE
        WHEN t.protected_until > v_now THEN 'protected'
        ELSE 'vulnerable'
      END,
      updated_at = CASE
        WHEN t.status IS DISTINCT FROM CASE
          WHEN t.protected_until > v_now THEN 'protected'
          ELSE 'vulnerable'
        END THEN v_now
        ELSE t.updated_at
      END;
END;
$$;


CREATE OR REPLACE FUNCTION resolve_expired_territory_contests(
  p_min_area_m2 double precision DEFAULT 5000
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_now timestamptz := now();
  v_row record;
  v_resolved_geom geometry;
  v_owner_geom geometry;
  v_parent_new geometry;
  v_winner_id uuid;
  v_new_duration_hours integer;
  v_resolved_count integer := 0;
BEGIN
  CREATE TEMP TABLE IF NOT EXISTS tmp_contest_affected_users (
    user_id uuid PRIMARY KEY
  ) ON COMMIT DROP;
  TRUNCATE tmp_contest_affected_users;

  FOR v_row IN
    SELECT
      ca.id AS contested_area_id,
      ca.geom AS contested_geom,
      ca.current_winner_user_id,
      t.id AS territory_id,
      t.user_id AS owner_user_id,
      t.geom AS owner_geom,
      t.protection_duration_hours
    FROM territory_contested_areas ca
    JOIN territories t ON t.id = ca.territory_id
    WHERE ca.resolve_at <= v_now
    ORDER BY ca.resolve_at, ca.id
    FOR UPDATE OF ca, t
  LOOP
    v_resolved_geom := territory_clean_multipolygon(v_row.contested_geom, p_min_area_m2);
    IF v_resolved_geom IS NULL OR ST_IsEmpty(v_resolved_geom) THEN
      DELETE FROM territory_contested_areas WHERE id = v_row.contested_area_id;
      CONTINUE;
    END IF;

    v_winner_id := COALESCE(v_row.current_winner_user_id, v_row.owner_user_id);

    INSERT INTO tmp_contest_affected_users(user_id)
    VALUES (v_row.owner_user_id), (v_winner_id)
    ON CONFLICT DO NOTHING;

    IF v_winner_id <> v_row.owner_user_id THEN
      SELECT geom
      INTO v_owner_geom
      FROM territories
      WHERE id = v_row.territory_id
      FOR UPDATE;

      IF v_owner_geom IS NULL OR ST_IsEmpty(v_owner_geom) THEN
        DELETE FROM territory_contested_areas WHERE id = v_row.contested_area_id;
        CONTINUE;
      END IF;

      v_parent_new := territory_clean_multipolygon(
        ST_Difference(v_owner_geom, v_resolved_geom),
        p_min_area_m2
      );

      IF v_parent_new IS NULL OR ST_IsEmpty(v_parent_new) THEN
        DELETE FROM territories WHERE id = v_row.territory_id;
      ELSE
        UPDATE territories
        SET geom = v_parent_new,
            status = 'vulnerable',
            updated_at = v_now
        WHERE id = v_row.territory_id;
      END IF;

      v_new_duration_hours := GREATEST(v_row.protection_duration_hours - 1, 2);

      INSERT INTO territories(
        user_id,
        geom,
        captured_at,
        protected_until,
        protection_duration_hours,
        status,
        updated_at
      )
      VALUES (
        v_winner_id,
        v_resolved_geom,
        v_now,
        v_now + make_interval(hours => v_new_duration_hours),
        v_new_duration_hours,
        'protected',
        v_now
      );
    ELSE
      UPDATE territories
      SET status = 'vulnerable',
          updated_at = v_now
      WHERE id = v_row.territory_id;
    END IF;

    DELETE FROM territory_contested_areas WHERE id = v_row.contested_area_id;
    v_resolved_count := v_resolved_count + 1;
  END LOOP;

  PERFORM refresh_territory_statuses();

  FOR v_row IN
    SELECT user_id FROM tmp_contest_affected_users
  LOOP
    PERFORM territory_merge_adjacent_fragments(v_row.user_id, p_min_area_m2);
  END LOOP;

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
    user_id,
    0,
    0,
    0,
    0,
    0,
    territory_owned_area_m2(user_id),
    v_now
  FROM tmp_contest_affected_users
  ON CONFLICT (user_id)
  DO UPDATE SET
    owned_area_m2 = territory_owned_area_m2(EXCLUDED.user_id),
    updated_at = v_now;

  RETURN v_resolved_count;
END;
$$;


CREATE OR REPLACE FUNCTION finalize_run_capture(
  p_run_id uuid,
  p_tol_m double precision DEFAULT 10,
  p_min_area_m2 double precision DEFAULT 5000
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
  v_intersection geometry;
  v_intersection_area double precision;
  v_victim_new geometry;
  v_runner_gain geometry;
  v_runner_existing geometry;
  v_contest_id uuid;
  v_self_remainder geometry;
  v_existing_contested_geom geometry;
  v_existing_contest record;
  v_overlap geometry;
  v_existing_remainder geometry;
  v_attack_uncontested geometry;
  v_split_contest_id uuid;
BEGIN
  PERFORM resolve_expired_territory_contests(p_min_area_m2);
  PERFORM refresh_territory_statuses();

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
      territory_owned_area_m2(v_runner_id),
      v_now
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      run_count = user_stats.run_count + 1,
      total_distance_m = user_stats.total_distance_m + v_distance_m,
      total_elapsed_s = user_stats.total_elapsed_s + v_elapsed_s,
      total_paused_s = user_stats.total_paused_s + v_paused_s,
      total_moving_s = user_stats.total_moving_s + v_moving_s,
      owned_area_m2 = territory_owned_area_m2(v_runner_id),
      updated_at = v_now;

    capture_area_m2 := 0;
    victims_count := 0;
    RETURN NEXT;
    RETURN;
  END IF;

  v_capture_m := ST_Transform(v_capture, 3857);
  v_area_m2 := ST_Area(v_capture_m);
  v_runner_gain := v_capture;

  CREATE TEMP TABLE IF NOT EXISTS tmp_victim_touched (
    victim_user_id uuid PRIMARY KEY,
    affected_area_m2 double precision NOT NULL DEFAULT 0,
    notification_kind text NOT NULL DEFAULT 'territory_contested'
  ) ON COMMIT DROP;

  TRUNCATE tmp_victim_touched;

  -- Lock runner territory rows (if any) to prevent races.
  PERFORM 1
  FROM territories t
  WHERE t.user_id = v_runner_id
  FOR UPDATE;

  -- Re-capture over own still-protected land: peel overlap into a fresh 6h
  -- fragment; the remainder keeps its existing protection timer. Active
  -- contested areas are handled below by updating current_winner_user_id,
  -- so they must not be cut out into a fresh protected fragment here.
  FOR v_row IN
    SELECT t.id, t.geom, t.protected_until
    FROM territories t
    WHERE t.user_id = v_runner_id
      AND t.protected_until > v_now
      AND ST_Intersects(t.geom, v_capture)
    FOR UPDATE
  LOOP
    v_intersection := territory_clean_multipolygon(
      ST_Intersection(v_row.geom, v_capture),
      p_min_area_m2
    );

    IF v_intersection IS NULL OR ST_IsEmpty(v_intersection) THEN
      CONTINUE;
    END IF;

    SELECT territory_clean_multipolygon(ST_Union(ca.geom), p_min_area_m2)
    INTO v_existing_contested_geom
    FROM territory_contested_areas ca
    WHERE ca.territory_id = v_row.id
      AND ST_Intersects(ca.geom, v_intersection);

    IF v_existing_contested_geom IS NOT NULL
       AND NOT ST_IsEmpty(v_existing_contested_geom) THEN
      v_intersection := territory_clean_multipolygon(
        ST_Difference(v_intersection, v_existing_contested_geom),
        p_min_area_m2
      );
    END IF;

    IF v_intersection IS NULL OR ST_IsEmpty(v_intersection) THEN
      CONTINUE;
    END IF;

    v_intersection_area := ST_Area(ST_Transform(v_intersection, 3857));
    IF v_intersection_area < p_min_area_m2 THEN
      CONTINUE;
    END IF;

    v_self_remainder := territory_clean_multipolygon(
      ST_Difference(v_row.geom, v_intersection),
      p_min_area_m2
    );

    IF v_self_remainder IS NULL OR ST_IsEmpty(v_self_remainder) THEN
      DELETE FROM territories WHERE id = v_row.id;
    ELSE
      UPDATE territories
      SET geom = v_self_remainder,
          updated_at = v_now
      WHERE id = v_row.id;
    END IF;

    INSERT INTO territories(
      user_id,
      geom,
      captured_at,
      protected_until,
      protection_duration_hours,
      status,
      updated_at
    )
    VALUES (
      v_runner_id,
      v_intersection,
      v_now,
      v_now + interval '6 hours',
      6,
      'protected',
      v_now
    );
  END LOOP;

  -- The owner can reclaim current-winner position by crossing an active contest.
  FOR v_row IN
    SELECT ca.id, ca.geom
    FROM territory_contested_areas ca
    JOIN territories t ON t.id = ca.territory_id
    WHERE t.user_id = v_runner_id
      AND ST_Intersects(ca.geom, v_capture)
    FOR UPDATE OF ca
  LOOP
    v_intersection := territory_clean_multipolygon(
      ST_Intersection(v_row.geom, v_capture),
      p_min_area_m2
    );
    IF v_intersection IS NULL OR ST_IsEmpty(v_intersection) THEN
      CONTINUE;
    END IF;

    UPDATE territory_contested_areas
    SET current_winner_user_id = v_runner_id,
        updated_at = v_now
    WHERE id = v_row.id;

    INSERT INTO territory_contested_area_participants(contested_area_id, user_id, first_joined_at, last_joined_at)
    VALUES (v_row.id, v_runner_id, v_now, v_now)
    ON CONFLICT (contested_area_id, user_id)
    DO UPDATE SET last_joined_at = EXCLUDED.last_joined_at;
  END LOOP;

  -- Process all other users whose territories intersect with the capture.
  FOR v_row IN
    SELECT t.id, t.user_id, t.geom, t.protected_until
    FROM territories t
    WHERE t.user_id <> v_runner_id
      AND ST_Intersects(t.geom, v_capture)
    FOR UPDATE
  LOOP
    v_intersection := territory_clean_multipolygon(
      ST_Intersection(v_row.geom, v_capture),
      p_min_area_m2
    );

    IF v_intersection IS NULL OR ST_IsEmpty(v_intersection) THEN
      CONTINUE;
    END IF;

    v_intersection_area := ST_Area(ST_Transform(v_intersection, 3857));
    IF v_intersection_area < p_min_area_m2 THEN
      CONTINUE;
    END IF;

    IF v_row.protected_until > v_now THEN
      -- Protected territory is not stolen immediately: only the intersection
      -- becomes contested and the runner does not own that overlap yet.
      v_runner_gain := territory_clean_multipolygon(
        ST_Difference(v_runner_gain, v_intersection),
        p_min_area_m2
      );

      v_attack_uncontested := v_intersection;

      FOR v_existing_contest IN
        SELECT ca.id, ca.geom, ca.created_at
        FROM territory_contested_areas ca
        WHERE ca.territory_id = v_row.id
          AND ST_Intersects(ca.geom, v_attack_uncontested)
        ORDER BY ca.created_at
        FOR UPDATE
      LOOP
        v_overlap := territory_clean_multipolygon(
          ST_Intersection(v_existing_contest.geom, v_attack_uncontested),
          p_min_area_m2
        );

        IF v_overlap IS NULL OR ST_IsEmpty(v_overlap) THEN
          CONTINUE;
        END IF;

        IF ST_Area(ST_Transform(v_overlap, 3857)) < p_min_area_m2 THEN
          CONTINUE;
        END IF;

        v_existing_remainder := territory_clean_multipolygon(
          ST_Difference(v_existing_contest.geom, v_overlap),
          p_min_area_m2
        );

        INSERT INTO territory_contested_areas(
          territory_id,
          geom,
          current_winner_user_id,
          resolve_at,
          created_at,
          updated_at
        )
        VALUES (
          v_row.id,
          v_overlap,
          v_runner_id,
          v_row.protected_until,
          v_now,
          v_now
        )
        RETURNING id INTO v_split_contest_id;

        INSERT INTO territory_contested_area_participants(
          contested_area_id,
          user_id,
          first_joined_at,
          last_joined_at
        )
        SELECT
          v_split_contest_id,
          p.user_id,
          p.first_joined_at,
          CASE
            WHEN p.user_id = v_runner_id THEN v_now
            ELSE p.last_joined_at
          END
        FROM territory_contested_area_participants p
        WHERE p.contested_area_id = v_existing_contest.id
        ON CONFLICT (contested_area_id, user_id)
        DO UPDATE SET last_joined_at = EXCLUDED.last_joined_at;

        INSERT INTO territory_contested_area_participants(contested_area_id, user_id, first_joined_at, last_joined_at)
        VALUES
          (v_split_contest_id, v_row.user_id, v_now, v_now),
          (v_split_contest_id, v_runner_id, v_now, v_now)
        ON CONFLICT (contested_area_id, user_id)
        DO UPDATE SET last_joined_at = EXCLUDED.last_joined_at;

        IF v_existing_remainder IS NULL OR ST_IsEmpty(v_existing_remainder) THEN
          DELETE FROM territory_contested_areas
          WHERE id = v_existing_contest.id;
        ELSE
          UPDATE territory_contested_areas
          SET geom = v_existing_remainder,
              updated_at = v_now
          WHERE id = v_existing_contest.id;
        END IF;

        v_attack_uncontested := territory_clean_multipolygon(
          ST_Difference(v_attack_uncontested, v_overlap),
          p_min_area_m2
        );

        IF v_attack_uncontested IS NULL OR ST_IsEmpty(v_attack_uncontested) THEN
          EXIT;
        END IF;
      END LOOP;

      IF v_attack_uncontested IS NOT NULL AND NOT ST_IsEmpty(v_attack_uncontested) THEN
        INSERT INTO territory_contested_areas(
          territory_id,
          geom,
          current_winner_user_id,
          resolve_at,
          created_at,
          updated_at
        )
        VALUES (
          v_row.id,
          v_attack_uncontested,
          v_runner_id,
          v_row.protected_until,
          v_now,
          v_now
        )
        RETURNING id INTO v_contest_id;

        INSERT INTO territory_contested_area_participants(contested_area_id, user_id, first_joined_at, last_joined_at)
        VALUES
          (v_contest_id, v_row.user_id, v_now, v_now),
          (v_contest_id, v_runner_id, v_now, v_now)
        ON CONFLICT (contested_area_id, user_id)
        DO UPDATE SET last_joined_at = EXCLUDED.last_joined_at;
      END IF;

      INSERT INTO tmp_victim_touched(victim_user_id, affected_area_m2, notification_kind)
      VALUES (v_row.user_id, v_intersection_area, 'territory_contested')
      ON CONFLICT (victim_user_id)
      DO UPDATE SET
        affected_area_m2 = tmp_victim_touched.affected_area_m2 + EXCLUDED.affected_area_m2,
        notification_kind = 'territory_contested';

      v_contest_id := NULL;
      CONTINUE;
    END IF;

    -- Vulnerable territories lose the valid intersection immediately.
    INSERT INTO tmp_victim_touched(victim_user_id, affected_area_m2, notification_kind)
    VALUES (v_row.user_id, v_intersection_area, 'territory_stolen')
    ON CONFLICT (victim_user_id)
    DO UPDATE SET
      affected_area_m2 = tmp_victim_touched.affected_area_m2 + EXCLUDED.affected_area_m2,
      notification_kind = CASE
        WHEN tmp_victim_touched.notification_kind = 'territory_contested' THEN 'territory_contested'
        ELSE EXCLUDED.notification_kind
      END;

    v_victim_new := territory_clean_multipolygon(
      ST_Difference(v_row.geom, v_intersection),
      p_min_area_m2
    );

    IF v_victim_new IS NULL OR ST_IsEmpty(v_victim_new) THEN
      DELETE FROM territories WHERE id = v_row.id;
    ELSE
      UPDATE territories
      SET geom = v_victim_new,
          status = 'vulnerable',
          updated_at = v_now
      WHERE id = v_row.id;
    END IF;
  END LOOP;

  SELECT ST_Multi(ST_Union(t.geom))
  INTO v_runner_existing
  FROM territories t
  WHERE t.user_id = v_runner_id;

  IF v_runner_existing IS NOT NULL AND NOT ST_IsEmpty(v_runner_existing) THEN
    v_runner_gain := territory_clean_multipolygon(
      ST_Difference(v_runner_gain, v_runner_existing),
      p_min_area_m2
    );
  END IF;

  IF v_runner_gain IS NOT NULL AND NOT ST_IsEmpty(v_runner_gain) THEN
    INSERT INTO territories(
      user_id,
      geom,
      captured_at,
      protected_until,
      protection_duration_hours,
      status,
      updated_at
    )
    VALUES (
      v_runner_id,
      ST_Multi(v_runner_gain),
      v_now,
      v_now + interval '6 hours',
      6,
      'protected',
      v_now
    );
  END IF;

  PERFORM territory_merge_adjacent_fragments(v_runner_id, p_min_area_m2);

  PERFORM refresh_territory_statuses();

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
    tvt.victim_user_id,
    tvt.notification_kind,
    v_runner_id,
    p_run_id,
    tvt.affected_area_m2,
    jsonb_build_object(
      'affected_area_m2', tvt.affected_area_m2,
      'stolen_area_m2', CASE WHEN tvt.notification_kind = 'territory_stolen' THEN tvt.affected_area_m2 ELSE 0 END
    ),
    v_now
  FROM tmp_victim_touched tvt;

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
      WHERE n.user_id IN (SELECT victim_user_id FROM tmp_victim_touched)
    ) ranked
    WHERE ranked.rn > 10
  ) old
  WHERE un.id = old.id;

  SELECT COUNT(*) INTO v_victims FROM tmp_victim_touched;

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
    territory_owned_area_m2(v_runner_id),
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
    owned_area_m2 = territory_owned_area_m2(v_runner_id),
    updated_at = v_now;

  -- Victims: recompute owned_area_m2 only (distance/run_count unchanged here).
  UPDATE user_stats us
  SET owned_area_m2 = territory_owned_area_m2(us.user_id),
      updated_at = v_now
  WHERE us.user_id IN (SELECT victim_user_id FROM tmp_victim_touched);

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
    tvt.victim_user_id,
    0,
    0,
    0,
    0,
    0,
    territory_owned_area_m2(tvt.victim_user_id),
    v_now
  FROM tmp_victim_touched tvt
  ON CONFLICT (user_id) DO NOTHING;

  capture_area_m2 := v_area_m2;
  victims_count := v_victims;
  RETURN NEXT;
END;
$$;

COMMIT;


