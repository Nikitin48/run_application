BEGIN;

ALTER TABLE runs
  ADD COLUMN IF NOT EXISTS capture_geom geometry(MultiPolygon, 4326);

UPDATE runs
SET capture_geom = compute_capture_polygons(track_line)
WHERE capture_geom IS NULL;

COMMIT;
