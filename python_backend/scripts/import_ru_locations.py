from __future__ import annotations

import argparse
import csv
import hashlib
import os
from pathlib import Path


def normalize_name(value: str) -> str:
    return " ".join(value.strip().lower().split())


def make_region_code(region_name: str) -> str:
    digest = hashlib.sha1(normalize_name(region_name).encode("utf-8")).hexdigest()[:12].upper()
    return f"RU-REG-{digest}"


def make_city_code(region_name: str, city_name: str) -> str:
    key = f"{normalize_name(region_name)}|{normalize_name(city_name)}"
    digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:12].upper()
    return f"RU-CITY-{digest}"


def load_regions(path: Path) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    with path.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            code = (row.get("code") or "").strip()
            name = (row.get("name") or "").strip()
            if not code or not name:
                continue
            rows.append((code, name))
    return rows


def load_cities(path: Path) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    with path.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            code = (row.get("code") or "").strip()
            region_code = (row.get("region_code") or "").strip()
            name = (row.get("name") or "").strip()
            if not code or not region_code or not name:
                continue
            rows.append((code, region_code, name))
    return rows


def load_region_city_dataset(path: Path) -> tuple[list[tuple[str, str]], list[tuple[str, str, str]]]:
    regions_map: dict[str, str] = {}
    cities_map: dict[tuple[str, str], str] = {}

    with path.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f, delimiter=";")
        required = {"region", "city"}
        if not required.issubset(set(reader.fieldnames or [])):
            raise SystemExit("dataset CSV must contain headers: region;city")
        for row in reader:
            region_name = (row.get("region") or "").strip()
            city_name = (row.get("city") or "").strip()
            if not region_name or not city_name:
                continue
            region_norm = normalize_name(region_name)
            city_norm = normalize_name(city_name)
            if region_norm not in regions_map:
                regions_map[region_norm] = region_name
            city_key = (region_norm, city_norm)
            if city_key not in cities_map:
                cities_map[city_key] = city_name

    if not regions_map or not cities_map:
        raise SystemExit("dataset CSV has no valid rows")

    regions = [
        (make_region_code(region_name), region_name)
        for _, region_name in sorted(regions_map.items(), key=lambda item: item[1].lower())
    ]

    region_code_by_norm = {
        norm: make_region_code(region_name)
        for norm, region_name in regions_map.items()
    }
    cities = [
        (make_city_code(regions_map[region_norm], city_name), region_code_by_norm[region_norm], city_name)
        for (region_norm, _), city_name in sorted(cities_map.items(), key=lambda item: item[1].lower())
    ]
    return regions, cities


def main() -> None:
    import psycopg

    parser = argparse.ArgumentParser(description="Import RU locations into reference tables.")
    parser.add_argument("--regions-csv", help="CSV with headers: code,name")
    parser.add_argument("--cities-csv", help="CSV with headers: code,region_code,name")
    parser.add_argument(
        "--dataset-csv",
        help="CSV with headers: region;city (semicolon-delimited).",
    )
    parser.add_argument(
        "--replace-all",
        action="store_true",
        help="Delete non-imported regions/cities after import and reset invalid user references.",
    )
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL"),
        help="Postgres connection string (defaults to DATABASE_URL env var).",
    )
    args = parser.parse_args()

    if not args.database_url:
        raise SystemExit("DATABASE_URL is required")

    use_dataset = bool(args.dataset_csv)
    if use_dataset:
        if args.regions_csv or args.cities_csv:
            raise SystemExit("use either --dataset-csv or (--regions-csv and --cities-csv)")
        regions, cities = load_region_city_dataset(Path(args.dataset_csv))
    else:
        if not args.regions_csv or not args.cities_csv:
            raise SystemExit("provide --dataset-csv or both --regions-csv and --cities-csv")
        regions = load_regions(Path(args.regions_csv))
        cities = load_cities(Path(args.cities_csv))

    if not regions:
        raise SystemExit("No regions loaded from CSV")
    if not cities:
        raise SystemExit("No cities loaded from CSV")

    imported_region_codes = [code for code, _ in regions]
    imported_city_codes = [code for code, _, _ in cities]

    with psycopg.connect(args.database_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO ref_countries (code, name)
                VALUES ('RU', 'Россия')
                ON CONFLICT (code) DO UPDATE
                SET name = EXCLUDED.name
                """
            )

            for code, name in regions:
                cur.execute(
                    """
                    INSERT INTO ref_regions (code, country_code, name, normalized_name, is_active)
                    VALUES (%s, 'RU', %s, %s, true)
                    ON CONFLICT (code) DO UPDATE
                    SET name = EXCLUDED.name,
                        normalized_name = EXCLUDED.normalized_name,
                        is_active = EXCLUDED.is_active
                    """,
                    (code, name, normalize_name(name)),
                )

            for code, region_code, name in cities:
                cur.execute(
                    """
                    INSERT INTO ref_cities (code, country_code, region_code, name, normalized_name, is_active)
                    VALUES (%s, 'RU', %s, %s, %s, true)
                    ON CONFLICT (code) DO UPDATE
                    SET region_code = EXCLUDED.region_code,
                        name = EXCLUDED.name,
                        normalized_name = EXCLUDED.normalized_name,
                        is_active = EXCLUDED.is_active
                    """,
                    (code, region_code, name, normalize_name(name)),
                )

            if args.replace_all:
                cur.execute(
                    """
                    UPDATE users
                    SET city_code = NULL
                    WHERE city_code IS NOT NULL
                      AND NOT (city_code = ANY(%s))
                    """,
                    (imported_city_codes,),
                )
                cur.execute(
                    """
                    UPDATE users
                    SET region_code = NULL
                    WHERE region_code IS NOT NULL
                      AND NOT (region_code = ANY(%s))
                    """,
                    (imported_region_codes,),
                )
                cur.execute(
                    """
                    DELETE FROM ref_cities
                    WHERE country_code = 'RU'
                      AND NOT (code = ANY(%s))
                    """,
                    (imported_city_codes,),
                )
                cur.execute(
                    """
                    DELETE FROM ref_regions
                    WHERE country_code = 'RU'
                      AND NOT (code = ANY(%s))
                    """,
                    (imported_region_codes,),
                )
        conn.commit()

    mode = "dataset" if use_dataset else "explicit_csv"
    print(
        f"Imported {len(regions)} regions and {len(cities)} cities "
        f"(mode={mode}, replace_all={args.replace_all})."
    )


if __name__ == "__main__":
    main()
