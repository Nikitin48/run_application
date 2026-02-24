-- Final DB schema for:
-- - users + basic auth identities
-- - runs (track line + optional points)
-- - territories (ONE MultiPolygon per user)
-- - user_stats (aggregates)
-- - user_last_notification (ONLY last notification per user)
--
-- This script enables required extensions automatically (recommended for local dev).

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

-- Users
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL UNIQUE,
  display_name text NOT NULL,
  avatar_url text,
  territory_color text NOT NULL DEFAULT '#3B82F6' CHECK (territory_color ~ '^#[0-9A-Fa-f]{6}$'),
  is_banned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

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

-- Territories: ONE row per user with their current owned area.
CREATE TABLE IF NOT EXISTS territories (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  geom geometry(MultiPolygon, 4326) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS territories_geom_gix ON territories USING GIST (geom);

-- Aggregated stats
CREATE TABLE IF NOT EXISTS user_stats (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  run_count integer NOT NULL DEFAULT 0,
  total_distance_m double precision NOT NULL DEFAULT 0,
  total_elapsed_s bigint NOT NULL DEFAULT 0,
  total_paused_s bigint NOT NULL DEFAULT 0,
  total_moving_s bigint NOT NULL DEFAULT 0,
  owned_area_m2 double precision NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Only last notification per user (victim).
-- Payload stored as typed columns for easy UI + optional JSON payload.
CREATE TABLE IF NOT EXISTS user_last_notification (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  kind text NOT NULL DEFAULT 'territory_stolen',
  attacker_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  run_id uuid REFERENCES runs(id) ON DELETE SET NULL,
  stolen_area_m2 double precision NOT NULL DEFAULT 0,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMIT;


