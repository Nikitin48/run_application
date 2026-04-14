# Changelog (2026-04-09): рейтинг + справочники локаций РФ

## Добавлено

### Backend API

- Новый endpoint рейтинга:
  - `GET /leaderboard`
  - параметры: `scope=city|region|country`, `metric=area|distance`, `limit`, `offset`
- Новые endpoint'ы справочника локаций:
  - `GET /locations/countries`
  - `GET /locations/regions`
  - `GET /locations/cities`
- Для `regions/cities` добавлена серверная пагинация:
  - `limit`, `offset`
- Роутеры подключены в `python_backend/app/main.py`.

### Backend архитектура

- Добавлен repository layer:
  - `python_backend/app/repositories/leaderboard_repo.py`
- Добавлен service layer:
  - `python_backend/app/services/leaderboard_service.py`
- Добавлены пакеты:
  - `python_backend/app/repositories/__init__.py`
  - `python_backend/app/services/__init__.py`

### Backend модели и профиль

- Расширены модели в `python_backend/app/models.py`:
  - `LeaderboardEntryOut`, `LeaderboardResponseOut`
  - `LocationItemOut`, `CountryItemOut`, `RegionItemOut`, `CityItemOut`
  - поля локации в `MeProfileOut` (`country/region/city code+name`)
- Расширен `UpdateMeProfileRequest` для локации и корректной обработки `null`-сброса.
- В `python_backend/app/routers/me.py`:
  - `GET /me/profile` возвращает локацию пользователя,
  - `PATCH /me/profile` валидирует иерархию `country -> region -> city`,
  - поддержан явный сброс города/области.

### Справочник локаций и импорт

- Добавлен скрипт импорта:
  - `python_backend/scripts/import_ru_locations.py`
- Поддержан режим:
  - `--dataset-csv data_cities/final_cities.csv` (формат `region;city`)
  - `--replace-all` для очистки лишних данных и синхронизации справочника
- Добавлен конвертер ГАР/ФИАС:
  - `python_backend/scripts/gar_to_locations_csv.py`
- Добавлены sample CSV:
  - `python_backend/data/ru_regions.sample.csv`
  - `python_backend/data/ru_cities.sample.csv`

### БД и миграции

- Обновлена схема:
  - `db/schema.sql`
  - новые таблицы `ref_countries`, `ref_regions`, `ref_cities`
  - новые поля в `users`: `country_code`, `region_code`, `city_code`
- Добавлены миграции:
  - `db/migrations/20260409_leaderboard_locations.sql`
  - `db/migrations/20260409_locations_reset_ru.sql`
  - `db/migrations/20260409_drop_unused_location_timestamps.sql`
- Из схемы и миграций удалены демо seed-данные регионов/городов.
- Удалены неиспользуемые timestamp-поля из `ref_*` (до релиза, локально безопасно).

### Flutter

- Добавлена фича рейтинга:
  - `flutter_fronted/lib/src/features/leaderboard/*`
  - экран рейтинга с фильтрами:
    - scope: город/область/страна
    - metric: площадь/дистанция
  - убраны selected-иконки в сегмент-контролах фильтров
  - переключатели выровнены по центру
  - добавлен infinite scroll рейтинга с пагинацией по 20 записей
- Добавлена фича локаций:
  - `flutter_fronted/lib/src/features/locations/*`
  - поиск регионов/городов через backend API
- Обновлен профиль:
  - `flutter_fronted/lib/src/features/profile/*`
  - выбор региона/города из списка через `showModalBottomSheet`,
  - дебаунс поиска (300ms),
  - подгрузка списков регионов/городов с пагинацией при скролле,
  - блок `Локация для рейтинга` перенесен в `Персональные данные`,
  - сохранение локации по общей кнопке `Сохранить профиль`,
  - убраны кнопки-крестики, оставлена только кнопка `Выбрать`.
- Добавлен роут рейтинга:
  - `flutter_fronted/lib/src/app/router.dart`

### Тесты и качество

- Добавлены backend интеграционные тесты:
  - `python_backend/tests/test_locations_leaderboard.py`
- Добавлена зависимость:
  - `httpx==0.28.1` в `python_backend/requirements.txt` (для `fastapi.testclient`)
- Фикс в auth:
  - безопасная обработка IP клиента для `inet` поля в `refresh_tokens`.

### Документация

- Добавлен runbook деплоя:
  - `docs/guide/leaderboard_locations_vps_rollout.md`
- Добавлен acceptance checklist:
  - `docs/guide/leaderboard_locations_acceptance_checklist.md`

## Проверено

- `GET /health` отвечает `200`.
- Новые пути видны в `/openapi.json`.
- `dart analyze` по измененным flutter-файлам без новых ошибок.
- `python_backend/tests/test_locations_leaderboard.py` проходит (8 тестов, включая пагинацию `regions`).

## Важно перед продом

- Выполнить полный импорт `final_cities.csv` на прод-БД.
- Прогнать acceptance checklist.
- Убедиться, что `.env` и `DATABASE_URL` консистентны с compose-настройками.
