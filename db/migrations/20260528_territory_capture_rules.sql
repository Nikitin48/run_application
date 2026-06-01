BEGIN;

-- Move the old "one row per user" territory table into the new fragment model.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'territories'
      AND column_name = 'user_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'territories'
      AND column_name = 'id'
  ) THEN
    ALTER TABLE territories RENAME TO territories_legacy_one_row_per_user;
  END IF;
END;
$$;

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

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'territories_legacy_one_row_per_user'
  ) THEN
    EXECUTE $sql$
      INSERT INTO territories(user_id, geom, captured_at, protected_until, protection_duration_hours, status, updated_at)
      SELECT
        user_id,
        geom,
        COALESCE(updated_at, now()),
        COALESCE(updated_at, now()) + interval '6 hours',
        6,
        CASE
          WHEN COALESCE(updated_at, now()) + interval '6 hours' > now() THEN 'protected'
          ELSE 'vulnerable'
        END,
        COALESCE(updated_at, now())
      FROM territories_legacy_one_row_per_user
      ON CONFLICT DO NOTHING
    $sql$;
  END IF;
END;
$$;

DROP TABLE IF EXISTS territories_legacy_one_row_per_user;

UPDATE territories
SET status = CASE
      WHEN protected_until > now() THEN 'protected'
      ELSE 'vulnerable'
    END
WHERE status NOT IN ('protected', 'vulnerable');

ALTER TABLE territories
  DROP CONSTRAINT IF EXISTS territories_status_check;

ALTER TABLE territories
  ADD CONSTRAINT territories_status_check
  CHECK (status IN ('protected', 'vulnerable'));

CREATE INDEX IF NOT EXISTS territories_user_ix ON territories(user_id);
CREATE INDEX IF NOT EXISTS territories_geom_gix ON territories USING GIST (geom);
CREATE INDEX IF NOT EXISTS territories_status_protected_until_ix
  ON territories(status, protected_until);

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

COMMIT;
