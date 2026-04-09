-- Drop unused timestamp columns from location reference dictionaries.
-- Safe for local pre-release DB where feature is not yet in production.

BEGIN;

ALTER TABLE IF EXISTS ref_countries
  DROP COLUMN IF EXISTS created_at,
  DROP COLUMN IF EXISTS updated_at;

ALTER TABLE IF EXISTS ref_regions
  DROP COLUMN IF EXISTS created_at,
  DROP COLUMN IF EXISTS updated_at;

ALTER TABLE IF EXISTS ref_cities
  DROP COLUMN IF EXISTS created_at,
  DROP COLUMN IF EXISTS updated_at;

COMMIT;
