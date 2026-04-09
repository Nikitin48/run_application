from __future__ import annotations

import argparse
import csv
import fnmatch
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from xml.etree import ElementTree as ET


@dataclass(frozen=True)
class AddrObject:
    object_id: int
    object_guid: str
    name: str
    type_name: str
    level: int


def _iter_xml_files(base_dir: Path, pattern: str) -> Iterable[Path]:
    pattern_lower = pattern.lower()
    for path in base_dir.rglob("*"):
        if path.is_file() and fnmatch.fnmatch(path.name.lower(), pattern_lower):
            yield path


def _normalize_name(value: str) -> str:
    return " ".join(value.strip().lower().split())


def _display_name(name: str, type_name: str) -> str:
    clean_name = " ".join(name.strip().split())
    clean_type = " ".join(type_name.strip().split())
    if not clean_type:
        return clean_name
    suffixes = {clean_type.lower(), f"{clean_type.lower()}."}
    if clean_name.lower().endswith(tuple(suffixes)):
        return clean_name
    return f"{clean_name} {clean_type}".strip()


def _attr(element: ET.Element, key: str) -> str:
    return (element.attrib.get(key) or "").strip()


def _local_tag(element: ET.Element) -> str:
    # Handles XML namespaces: "{ns}OBJECT" -> "OBJECT"
    return element.tag.rsplit("}", 1)[-1]


def _parse_int(value: str) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _is_active_addr_obj(row: ET.Element) -> bool:
    is_active = _attr(row, "ISACTIVE")
    is_actual = _attr(row, "ISACTUAL")
    return is_active == "1" and is_actual == "1"


def _is_active_hierarchy(row: ET.Element) -> bool:
    return _attr(row, "ISACTIVE") == "1"


def load_addr_objects(
    files: list[Path],
    city_levels: set[int],
) -> tuple[dict[int, AddrObject], dict[int, AddrObject]]:
    regions: dict[int, AddrObject] = {}
    cities: dict[int, AddrObject] = {}

    for xml_file in files:
        for event, elem in ET.iterparse(xml_file, events=("end",)):
            if _local_tag(elem) != "OBJECT":
                elem.clear()
                continue
            if not _is_active_addr_obj(elem):
                elem.clear()
                continue

            level = _parse_int(_attr(elem, "LEVEL"))
            object_id = _parse_int(_attr(elem, "OBJECTID"))
            guid = _attr(elem, "OBJECTGUID")
            name = _attr(elem, "NAME")
            type_name = _attr(elem, "TYPENAME")
            if level is None or object_id is None or not guid or not name:
                elem.clear()
                continue

            obj = AddrObject(
                object_id=object_id,
                object_guid=guid.upper(),
                name=name,
                type_name=type_name,
                level=level,
            )
            if level == 1:
                regions[object_id] = obj
            elif level in city_levels:
                cities[object_id] = obj
            elem.clear()

    return regions, cities


def load_parent_map(files: list[Path]) -> dict[int, int]:
    parent_by_obj_id: dict[int, int] = {}
    for xml_file in files:
        for event, elem in ET.iterparse(xml_file, events=("end",)):
            if _local_tag(elem) != "ITEM":
                elem.clear()
                continue
            if not _is_active_hierarchy(elem):
                elem.clear()
                continue
            obj_id = _parse_int(_attr(elem, "OBJECTID"))
            parent_id = _parse_int(_attr(elem, "PARENTOBJID"))
            if obj_id is None or parent_id is None:
                elem.clear()
                continue
            parent_by_obj_id[obj_id] = parent_id
            elem.clear()
    return parent_by_obj_id


def resolve_region_id(
    start_obj_id: int,
    parent_by_obj_id: dict[int, int],
    region_ids: set[int],
) -> int | None:
    current = start_obj_id
    visited: set[int] = set()
    while current not in visited:
        visited.add(current)
        if current in region_ids:
            return current
        parent = parent_by_obj_id.get(current)
        if parent is None:
            return None
        current = parent
    return None


def write_regions_csv(path: Path, country_code: str, regions: dict[int, AddrObject]) -> None:
    ordered = sorted(regions.values(), key=lambda item: item.name.lower())
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["code", "name"])
        writer.writeheader()
        for region in ordered:
            code = f"{country_code}-REG-{region.object_guid}"
            writer.writerow({"code": code, "name": _display_name(region.name, region.type_name)})


def write_cities_csv(
    path: Path,
    country_code: str,
    regions: dict[int, AddrObject],
    cities: dict[int, AddrObject],
    parent_by_obj_id: dict[int, int],
) -> tuple[int, int]:
    region_ids = set(regions.keys())
    rows: list[dict[str, str]] = []
    skipped_without_region = 0

    for city in cities.values():
        region_id = resolve_region_id(city.object_id, parent_by_obj_id, region_ids)
        if region_id is None:
            skipped_without_region += 1
            continue
        region = regions.get(region_id)
        if region is None:
            skipped_without_region += 1
            continue
        city_code = f"{country_code}-CITY-{city.object_guid}"
        region_code = f"{country_code}-REG-{region.object_guid}"
        rows.append(
            {
                "code": city_code,
                "region_code": region_code,
                "name": _display_name(city.name, city.type_name),
            }
        )

    rows.sort(key=lambda item: item["name"].lower())
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["code", "region_code", "name"])
        writer.writeheader()
        writer.writerows(rows)
    return len(rows), skipped_without_region


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert GAR/FIAS XML dumps to CSV files for location import.",
    )
    parser.add_argument("--gar-dir", required=True, help="Directory with GAR XML files.")
    parser.add_argument(
        "--addr-obj-pattern",
        default="AS_ADDR_OBJ*.XML",
        help="Filename glob for address object files.",
    )
    parser.add_argument(
        "--adm-hierarchy-pattern",
        default="AS_ADM_HIERARCHY*.XML",
        help="Filename glob for hierarchy files.",
    )
    parser.add_argument(
        "--country-code",
        default="RU",
        help="Country code prefix for generated location codes.",
    )
    parser.add_argument(
        "--city-levels",
        default="4,6",
        help="Comma-separated GAR levels treated as city-like objects.",
    )
    parser.add_argument(
        "--out-regions-csv",
        required=True,
        help="Output CSV for regions (code,name).",
    )
    parser.add_argument(
        "--out-cities-csv",
        required=True,
        help="Output CSV for cities (code,region_code,name).",
    )
    args = parser.parse_args()

    gar_dir = Path(args.gar_dir).resolve()
    if not gar_dir.exists():
        raise SystemExit(f"GAR directory not found: {gar_dir}")

    city_levels = {
        level
        for level in (
            _parse_int(item.strip())
            for item in args.city_levels.split(",")
        )
        if level is not None
    }
    if not city_levels:
        raise SystemExit("city-levels must contain at least one numeric level")

    addr_files = list(_iter_xml_files(gar_dir, args.addr_obj_pattern))
    hier_files = list(_iter_xml_files(gar_dir, args.adm_hierarchy_pattern))
    if not addr_files:
        raise SystemExit("No AS_ADDR_OBJ XML files found")
    if not hier_files:
        raise SystemExit("No AS_ADM_HIERARCHY XML files found")

    print(f"Found {len(addr_files)} addr files and {len(hier_files)} hierarchy files.")
    regions, cities = load_addr_objects(addr_files, city_levels)
    print(f"Loaded active regions: {len(regions)}, city-like objects: {len(cities)}.")
    parent_by_obj_id = load_parent_map(hier_files)
    print(f"Loaded active hierarchy links: {len(parent_by_obj_id)}.")

    out_regions = Path(args.out_regions_csv).resolve()
    out_cities = Path(args.out_cities_csv).resolve()
    write_regions_csv(out_regions, args.country_code.upper(), regions)
    written_cities, skipped_cities = write_cities_csv(
        out_cities,
        args.country_code.upper(),
        regions,
        cities,
        parent_by_obj_id,
    )

    print(f"Regions CSV: {out_regions}")
    print(f"Cities CSV: {out_cities}")
    print(f"Written cities: {written_cities}; skipped (no region ancestor): {skipped_cities}")
    print("Done.")


if __name__ == "__main__":
    main()
