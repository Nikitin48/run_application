# Changelog (2026-04-10): история пробежек с превью захвата на карте

## Добавлено

### Backend API (`runs/history`)

- Расширен ответ `GET /runs/history`:
  - `capture_geojson` — GeoJSON захваченной области (`MultiPolygon`/`Polygon`)
  - `track_geojson` — GeoJSON трека пробежки (`LineString`)
- Обновлены файлы:
  - `python_backend/app/routers/runs.py`
  - `python_backend/app/models.py`

### Backend обработка завершения пробежки

- При `POST /runs/finish` после `finalize_run_capture(...)` в `runs` теперь сохраняется:
  - `capture_area_m2`
  - `victims_count`
  - `capture_geom = compute_capture_polygons(track_line)`
- Это фиксирует геометрию захвата как исторический snapshot для конкретной пробежки.

### БД и миграции

- В таблицу `runs` добавлено поле:
  - `capture_geom geometry(MultiPolygon, 4326)`
- Обновлен файл схемы:
  - `db/schema.sql`
- Добавлена миграция:
  - `db/migrations/20260410_runs_capture_geom.sql`
- Миграция делает:
  - `ALTER TABLE runs ADD COLUMN IF NOT EXISTS capture_geom ...`
  - backfill для существующих пробежек: `capture_geom = compute_capture_polygons(track_line)`

### Flutter: история с картой внутри item

- В карточку истории добавлено превью карты (`height: 200`, ширина на весь item):
  - превью не интерактивно (`IgnorePointer` + `InteractiveFlag.none`)
  - карта автоцентрируется по bounds захваченной области
  - область рисуется полигоном
  - трек рисуется поверх полилинией
- Добавлен парсинг новых полей истории:
  - `capture_geojson -> capturePolygons`
  - `track_geojson -> trackPoints`
- Обновлены файлы:
  - `flutter_fronted/lib/src/features/histories/presentation/histories_page.dart`
  - `flutter_fronted/lib/src/features/runs/domain/run_models.dart`

### Визуальные доработки превью

- Ограничен диапазон зума/тайлов для уменьшения размытия на маленьких территориях:
  - `minZoom = 9`
  - `maxZoom = 14`
  - `maxNativeZoom = 16`
- Цвет полигона и трека в истории синхронизирован с текущим цветом территории пользователя (`meProfile.territoryColor`).

### Документация

- Добавлен отдельный runbook для выката на VPS:
  - `docs/guide/vps_deploy_run_history_capture_preview.md`

## Изменено

- Модель истории на backend:
  - `RunHistoryItemOut` расширена полями `capture_geojson` и `track_geojson`.
- Модель истории на frontend:
  - `RunHistoryItem` расширена полями `capturePolygons` и `trackPoints`.

## Проверено

- `dart` lint по измененным Flutter-файлам: без новых ошибок.
- Локально проверена компоновка превью истории:
  - карта отображается в карточке,
  - область и трек рисуются,
  - цвет соответствует цвету территории пользователя.

## Важно перед продом

- На VPS обязательно применить миграцию:
  - `db/migrations/20260410_runs_capture_geom.sql`
- Для гарантии нового backend-кода выполнить явную пересборку backend-образа перед `up`.
- Проверить `GET /runs/history` с токеном:
  - наличие `capture_geojson`
  - наличие `track_geojson`
