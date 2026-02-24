BEGIN;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS territory_color text;

UPDATE users
SET territory_color = '#3B82F6'
WHERE territory_color IS NULL
   OR territory_color !~ '^#[0-9A-Fa-f]{6}$';

ALTER TABLE users
ALTER COLUMN territory_color SET DEFAULT '#3B82F6';

ALTER TABLE users
ALTER COLUMN territory_color SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'users_territory_color_hex_check'
  ) THEN
    ALTER TABLE users
    ADD CONSTRAINT users_territory_color_hex_check
    CHECK (territory_color ~ '^#[0-9A-Fa-f]{6}$');
  END IF;
END
$$;

COMMIT;
