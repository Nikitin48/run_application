BEGIN;

ALTER TABLE user_stats
  ADD COLUMN IF NOT EXISTS successful_captures_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_captured_area_m2 double precision NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_victims_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_xp integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_level integer NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS achievement_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  title text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  icon_key text NOT NULL,
  xp integer NOT NULL CHECK (xp >= 0),
  rule_type text NOT NULL,
  rule_value double precision NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS achievement_definitions_category_sort_ix
  ON achievement_definitions(category, sort_order, code);

CREATE TABLE IF NOT EXISTS user_achievements (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id uuid NOT NULL REFERENCES achievement_definitions(id) ON DELETE CASCADE,
  source_run_id uuid REFERENCES runs(id) ON DELETE SET NULL,
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS user_achievements_user_unlocked_ix
  ON user_achievements(user_id, unlocked_at DESC);
CREATE INDEX IF NOT EXISTS user_achievements_source_run_ix
  ON user_achievements(source_run_id);

INSERT INTO achievement_definitions(code, title, description, category, icon_key, xp, rule_type, rule_value, sort_order)
VALUES
  ('runs_001', 'Первые шаги', 'Завершить 1 пробежку', 'run_count', 'run_count', 100, 'run_count_gte', 1, 10),
  ('runs_005', 'Разогрев', 'Завершить 5 пробежек', 'run_count', 'run_count', 100, 'run_count_gte', 5, 20),
  ('runs_010', 'В ритме', 'Завершить 10 пробежек', 'run_count', 'run_count', 250, 'run_count_gte', 10, 30),
  ('runs_025', 'Не остановить', 'Завершить 25 пробежек', 'run_count', 'run_count', 500, 'run_count_gte', 25, 40),
  ('runs_050', 'Машина бега', 'Завершить 50 пробежек', 'run_count', 'run_count', 1000, 'run_count_gte', 50, 50),

  ('single_distance_1k', 'Первый километр', 'Пробежать 1 км за один забег', 'distance_single', 'distance_single', 100, 'distance_single_gte', 1000, 110),
  ('single_distance_5k', 'Пятёрка', 'Пробежать 5 км за один забег', 'distance_single', 'distance_single', 100, 'distance_single_gte', 5000, 120),
  ('single_distance_10k', 'Десятка', 'Пробежать 10 км за один забег', 'distance_single', 'distance_single', 250, 'distance_single_gte', 10000, 130),
  ('single_distance_21k', 'Полумарафонец', 'Пробежать 21.1 км за один забег', 'distance_single', 'distance_single', 500, 'distance_single_gte', 21100, 140),
  ('single_distance_42k', 'Марафонец', 'Пробежать 42.2 км за один забег', 'distance_single', 'distance_single', 1000, 'distance_single_gte', 42200, 150),

  ('total_distance_10k', 'На дистанции', 'Пробежать 10 км суммарно', 'distance_total', 'distance_total', 100, 'distance_total_gte', 10000, 210),
  ('total_distance_50k', 'Дальше больше', 'Пробежать 50 км суммарно', 'distance_total', 'distance_total', 250, 'distance_total_gte', 50000, 220),
  ('total_distance_100k', 'Сотня', 'Пробежать 100 км суммарно', 'distance_total', 'distance_total', 500, 'distance_total_gte', 100000, 230),
  ('total_distance_250k', 'Длинный путь', 'Пробежать 250 км суммарно', 'distance_total', 'distance_total', 1000, 'distance_total_gte', 250000, 240),
  ('total_distance_500k', 'Железная выносливость', 'Пробежать 500 км суммарно', 'distance_total', 'distance_total', 1000, 'distance_total_gte', 500000, 250),

  ('single_capture_first', 'Первый захват', 'Первая пробежка с захватом территории', 'capture_single', 'capture_single', 100, 'capture_single_gte', 1, 310),
  ('single_capture_100k', 'Землемер', 'Захватить 0.1 км² за один забег', 'capture_single', 'capture_single', 100, 'capture_single_gte', 100000, 320),
  ('single_capture_4m', 'Картограф', 'Захватить 4 км² за один забег', 'capture_single', 'capture_single', 500, 'capture_single_gte', 4000000, 330),
  ('single_capture_10m', 'Завоеватель', 'Захватить 10 км² за один забег', 'capture_single', 'capture_single', 1000, 'capture_single_gte', 10000000, 340),
  ('single_capture_25m', 'Титан карты', 'Захватить 25 км² за один забег', 'capture_single', 'capture_single', 1000, 'capture_single_gte', 25000000, 350),

  ('captures_005', 'Захватчик', 'Выполнить 5 успешных захватов', 'captures_count', 'captures_count', 100, 'captures_count_gte', 5, 410),
  ('captures_010', 'Охотник за землями', 'Выполнить 10 успешных захватов', 'captures_count', 'captures_count', 250, 'captures_count_gte', 10, 420),
  ('captures_025', 'Коллекционер территорий', 'Выполнить 25 успешных захватов', 'captures_count', 'captures_count', 500, 'captures_count_gte', 25, 430),
  ('captures_050', 'Повелитель карты', 'Выполнить 50 успешных захватов', 'captures_count', 'captures_count', 1000, 'captures_count_gte', 50, 440),

  ('total_capture_10m', 'Империя растёт', 'Захватить 10 км² суммарно', 'capture_total', 'capture_total', 250, 'capture_total_gte', 10000000, 510),
  ('total_capture_50m', 'Расширение границ', 'Захватить 50 км² суммарно', 'capture_total', 'capture_total', 500, 'capture_total_gte', 50000000, 520),
  ('total_capture_100m', 'Континентальный размах', 'Захватить 100 км² суммарно', 'capture_total', 'capture_total', 1000, 'capture_total_gte', 100000000, 530),

  ('victims_single_1', 'Первый соперник', 'Захватить территорию хотя бы у 1 соперника за забег', 'victims_single', 'victims', 100, 'victims_single_gte', 1, 610),
  ('victims_single_2', 'Двойной удар', 'Захватить территорию у 2 соперников за один забег', 'victims_single', 'victims', 250, 'victims_single_gte', 2, 620),
  ('victims_single_3', 'Тройная угроза', 'Захватить территорию у 3 соперников за один забег', 'victims_single', 'victims', 500, 'victims_single_gte', 3, 630),
  ('victims_total_10', 'Гроза района', 'Суммарно затронуть 10 соперников', 'victims_total', 'victims', 250, 'victims_total_gte', 10, 640),
  ('victims_total_25', 'Легенда захватов', 'Суммарно затронуть 25 соперников', 'victims_total', 'victims', 1000, 'victims_total_gte', 25, 650),

  ('owned_area_500k', 'Есть своя земля', 'Иметь текущую площадь 0.5 км²', 'owned_area', 'owned_area', 100, 'owned_area_gte', 500000, 710),
  ('owned_area_5m', 'Маленькое королевство', 'Иметь текущую площадь 5 км²', 'owned_area', 'owned_area', 500, 'owned_area_gte', 5000000, 720),
  ('owned_area_20m', 'Большая держава', 'Иметь текущую площадь 20 км²', 'owned_area', 'owned_area', 1000, 'owned_area_gte', 20000000, 730)
ON CONFLICT (code) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    icon_key = EXCLUDED.icon_key,
    xp = EXCLUDED.xp,
    rule_type = EXCLUDED.rule_type,
    rule_value = EXCLUDED.rule_value,
    sort_order = EXCLUDED.sort_order;

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

  CREATE TEMP TABLE IF NOT EXISTS tmp_victim_stolen (
    victim_user_id uuid PRIMARY KEY,
    stolen_area_m2 double precision NOT NULL DEFAULT 0
  ) ON COMMIT DROP;

  TRUNCATE tmp_victim_stolen;

  PERFORM 1
  FROM territories t
  WHERE t.user_id = v_runner_id
  FOR UPDATE;

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

    INSERT INTO tmp_victim_stolen(victim_user_id, stolen_area_m2)
    VALUES (v_row.user_id, v_stolen_area)
    ON CONFLICT (victim_user_id)
    DO UPDATE SET stolen_area_m2 = tmp_victim_stolen.stolen_area_m2 + EXCLUDED.stolen_area_m2;

    v_victim_new := ST_Difference(v_row.geom, v_capture);
    v_victim_new := ST_Multi(ST_CollectionExtract(ST_MakeValid(v_victim_new), 3));

    IF v_victim_new IS NULL OR ST_IsEmpty(v_victim_new) THEN
      DELETE FROM territories WHERE user_id = v_row.user_id;
    ELSE
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

  INSERT INTO territories(user_id, geom, updated_at)
  VALUES (v_runner_id, ST_Multi(v_capture), v_now)
  ON CONFLICT (user_id)
  DO UPDATE SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(territories.geom, EXCLUDED.geom)), 3)),
                updated_at = v_now;

  UPDATE runs
  SET status = 'processed',
      elapsed_s = v_elapsed_s,
      paused_s = v_paused_s,
      moving_s = v_moving_s,
      updated_at = v_now
  WHERE id = p_run_id;

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

  UPDATE user_stats us
  SET owned_area_m2 = COALESCE((SELECT ST_Area(ST_Transform(t.geom, 3857)) FROM territories t WHERE t.user_id = us.user_id), 0),
      updated_at = v_now
  WHERE us.user_id IN (SELECT victim_user_id FROM tmp_victim_stolen);

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
