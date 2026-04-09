-- Resets RU region/city reference dictionaries.
-- Use before full re-import from dataset when test data was inserted manually.

BEGIN;

UPDATE users
SET city_code = NULL
WHERE city_code IS NOT NULL;

UPDATE users
SET region_code = NULL
WHERE region_code IS NOT NULL;

DELETE FROM ref_cities
WHERE country_code = 'RU';

DELETE FROM ref_regions
WHERE country_code = 'RU';

INSERT INTO ref_countries (code, name)
VALUES ('RU', 'Россия')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name;

COMMIT;
