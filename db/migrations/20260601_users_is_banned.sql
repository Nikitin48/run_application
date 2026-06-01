BEGIN;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_banned boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS users_is_banned_ix
  ON users(is_banned);

COMMIT;
