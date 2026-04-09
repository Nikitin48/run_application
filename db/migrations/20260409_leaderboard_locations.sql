-- Additive migration for leaderboard by country/region/city.
-- Safe for existing production DB: no destructive operations.

BEGIN;

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

INSERT INTO ref_countries (code, name)
VALUES ('RU', 'Россия')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS country_code text,
  ADD COLUMN IF NOT EXISTS region_code text,
  ADD COLUMN IF NOT EXISTS city_code text;

UPDATE users
SET country_code = 'RU'
WHERE country_code IS NULL;

ALTER TABLE users
  ALTER COLUMN country_code SET DEFAULT 'RU',
  ALTER COLUMN country_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_country_code_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_country_code_fkey
      FOREIGN KEY (country_code) REFERENCES ref_countries(code) ON DELETE RESTRICT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_region_code_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_region_code_fkey
      FOREIGN KEY (region_code) REFERENCES ref_regions(code) ON DELETE RESTRICT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_city_code_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_city_code_fkey
      FOREIGN KEY (city_code) REFERENCES ref_cities(code) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ref_regions_lookup_ix
  ON ref_regions(country_code, normalized_name);
CREATE INDEX IF NOT EXISTS ref_cities_lookup_ix
  ON ref_cities(country_code, region_code, normalized_name);
CREATE INDEX IF NOT EXISTS users_location_ix
  ON users(country_code, region_code, city_code);

COMMIT;
