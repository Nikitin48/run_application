-- Final DB schema for:
-- - users + basic auth identities
-- - runs (track line + optional points)
-- - territories (protected / contested / vulnerable owned fragments)
-- - user_stats (aggregates)
-- - user_notifications (history up to last N notifications per user)
--
-- This script enables required extensions automatically (recommended for local dev).

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

-- Reference locations (Russia-focused leaderboard scopes).
CREATE TABLE IF NOT EXISTS ref_countries (
  code text PRIMARY KEY,
  name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS ref_regions (
  code text PRIMARY KEY,
  country_code text NOT NULL REFERENCES ref_countries(code) ON DELETE RESTRICT,
  name text NOT NULL,
  normalized_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS ref_cities (
  code text PRIMARY KEY,
  country_code text NOT NULL REFERENCES ref_countries(code) ON DELETE RESTRICT,
  region_code text NOT NULL REFERENCES ref_regions(code) ON DELETE RESTRICT,
  name text NOT NULL,
  normalized_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS ref_regions_lookup_ix
  ON ref_regions(country_code, normalized_name);
CREATE INDEX IF NOT EXISTS ref_cities_lookup_ix
  ON ref_cities(country_code, region_code, normalized_name);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL UNIQUE,
  display_name text NOT NULL,
  country_code text NOT NULL DEFAULT 'RU' REFERENCES ref_countries(code) ON DELETE RESTRICT,
  region_code text REFERENCES ref_regions(code) ON DELETE RESTRICT,
  city_code text REFERENCES ref_cities(code) ON DELETE RESTRICT,
  avatar_url text,
  territory_color text NOT NULL DEFAULT '#3B82F6' CHECK (territory_color ~ '^#[0-9A-Fa-f]{6}$'),
  is_admin boolean NOT NULL DEFAULT false,
  is_banned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS users_location_ix
  ON users(country_code, region_code, city_code);

-- Auth identities (email/phone). Password hash stored as text (algorithm handled by backend).
CREATE TABLE IF NOT EXISTS auth_identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('email', 'phone')),
  identifier text NOT NULL,
  password_hash text NOT NULL,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, identifier),
  UNIQUE (user_id, provider)
);

-- Refresh tokens (rotation). Store only token hash in DB.
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  replaced_by_token_hash text,
  user_agent text,
  ip inet
);

CREATE INDEX IF NOT EXISTS refresh_tokens_user_ix ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_expires_ix ON refresh_tokens(expires_at);
CREATE INDEX IF NOT EXISTS refresh_tokens_revoked_ix ON refresh_tokens(revoked_at);

-- Runs (activities)
CREATE TABLE IF NOT EXISTS runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'finished' CHECK (status IN ('draft', 'finished', 'processed', 'failed')),
  started_at timestamptz,
  ended_at timestamptz,
  distance_m double precision,
  -- Total time (including pauses). If not provided, can be derived from started_at/ended_at.
  elapsed_s integer,
  -- Total paused time (manual + auto pauses).
  paused_s integer NOT NULL DEFAULT 0,
  -- Moving time = elapsed_s - paused_s (store for convenience / UI).
  moving_s integer,
  -- Capture metrics for finished run (used in history UI).
  capture_area_m2 double precision NOT NULL DEFAULT 0,
  victims_count integer NOT NULL DEFAULT 0,
  capture_geom geometry(MultiPolygon, 4326),
  avg_pace_s_per_km integer,
  -- Raw points (optional). In MVP you can store points here and/or compute LineString server-side.
  points jsonb,
  -- Normalized track line (WGS84)
  track_line geometry(LineString, 4326) NOT NULL,
  processing_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS runs_user_ix ON runs(user_id);
CREATE INDEX IF NOT EXISTS runs_status_ix ON runs(status);

-- Raw GPS points (recommended when you have pause/auto-pause and want fair stats/anti-cheat).
CREATE TABLE IF NOT EXISTS run_points (
  run_id uuid NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
  seq integer NOT NULL,
  ts timestamptz NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  altitude_m double precision,
  accuracy_m double precision,
  speed_mps double precision,
  PRIMARY KEY (run_id, seq)
);

CREATE INDEX IF NOT EXISTS run_points_run_ts_ix ON run_points(run_id, ts);

-- Pause intervals (manual or automatic).
CREATE TABLE IF NOT EXISTS run_pauses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL,
  ended_at timestamptz,
  reason text NOT NULL CHECK (reason IN ('manual', 'gps_lost', 'internet_lost')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS run_pauses_run_started_ix ON run_pauses(run_id, started_at);

-- Territories: owned fragments with their own protection timer.
CREATE TABLE IF NOT EXISTS territories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  geom geometry(MultiPolygon, 4326) NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  protected_until timestamptz NOT NULL DEFAULT (now() + interval '6 hours'),
  protection_duration_hours integer NOT NULL DEFAULT 6 CHECK (protection_duration_hours BETWEEN 2 AND 6),
  status text NOT NULL DEFAULT 'protected' CHECK (status IN ('protected', 'vulnerable')),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS territories_user_ix ON territories(user_id);
CREATE INDEX IF NOT EXISTS territories_geom_gix ON territories USING GIST (geom);
CREATE INDEX IF NOT EXISTS territories_status_protected_until_ix
  ON territories(status, protected_until);

-- Contested areas belong to one protected territory fragment. Participants are
-- normalized so the UI can show everyone involved while current_winner_user_id
-- tracks the last valid claimant for that contested geometry.
CREATE TABLE IF NOT EXISTS territory_contested_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id uuid NOT NULL REFERENCES territories(id) ON DELETE CASCADE,
  geom geometry(MultiPolygon, 4326) NOT NULL,
  current_winner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  resolve_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS territory_contested_areas_territory_ix
  ON territory_contested_areas(territory_id);
CREATE INDEX IF NOT EXISTS territory_contested_areas_geom_gix
  ON territory_contested_areas USING GIST (geom);
CREATE INDEX IF NOT EXISTS territory_contested_areas_resolve_ix
  ON territory_contested_areas(resolve_at);

CREATE TABLE IF NOT EXISTS territory_contested_area_participants (
  contested_area_id uuid NOT NULL REFERENCES territory_contested_areas(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  first_joined_at timestamptz NOT NULL DEFAULT now(),
  last_joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (contested_area_id, user_id)
);

CREATE INDEX IF NOT EXISTS territory_contested_area_participants_user_ix
  ON territory_contested_area_participants(user_id);

-- Aggregated stats
CREATE TABLE IF NOT EXISTS user_stats (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  run_count integer NOT NULL DEFAULT 0,
  total_distance_m double precision NOT NULL DEFAULT 0,
  total_elapsed_s bigint NOT NULL DEFAULT 0,
  total_paused_s bigint NOT NULL DEFAULT 0,
  total_moving_s bigint NOT NULL DEFAULT 0,
  successful_captures_count integer NOT NULL DEFAULT 0,
  total_captured_area_m2 double precision NOT NULL DEFAULT 0,
  total_victims_count integer NOT NULL DEFAULT 0,
  owned_area_m2 double precision NOT NULL DEFAULT 0,
  profile_xp integer NOT NULL DEFAULT 0,
  profile_level integer NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Achievement catalog
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

-- Earned achievements per user
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

-- Notifications history (victim-facing feed).
-- We keep full rows and trim to last N entries in business logic.
CREATE TABLE IF NOT EXISTS user_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind text NOT NULL DEFAULT 'territory_stolen',
  attacker_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  run_id uuid REFERENCES runs(id) ON DELETE SET NULL,
  stolen_area_m2 float8 NOT NULL DEFAULT 0,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_notifications_user_created_ix
  ON user_notifications(user_id, created_at DESC);

-- Push tokens per user-device.
CREATE TABLE IF NOT EXISTS user_push_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  token text NOT NULL UNIQUE,
  app_version text,
  device_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS user_push_tokens_user_ix
  ON user_push_tokens(user_id, updated_at DESC);

-- Minimal bootstrap data for Russia-only MVP.
INSERT INTO ref_countries (code, name)
VALUES ('RU', 'Россия')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name;

COMMIT;


