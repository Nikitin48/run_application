# Acceptance checklist: рейтинг и локации

Цель: быстро проверить, что после миграций и импорта справочника фича работает end-to-end.

## 0) Предусловия

- Backend запущен локально (`python_backend/run.sh`).
- В БД применены миграции:
  - `db/migrations/20260409_leaderboard_locations.sql`
  - `db/migrations/20260409_drop_unused_location_timestamps.sql` (если обновляли локальную схему)
- Справочник загружен:
  - `python_backend/scripts/import_ru_locations.py --dataset-csv data_cities/final_cities.csv --replace-all ...`

## 1) Проверка справочников в БД

Проверки:

```sql
select count(*) as regions_count from ref_regions;
select count(*) as cities_count from ref_cities;
select count(*) as countries_count from ref_countries;
```

Ожидание:
- `regions_count = 85`
- `cities_count = 1146`
- `countries_count >= 1` и есть `RU`.

## 2) Проверка API locations (авторизованный запрос)

Получить токен и выполнить:

- `GET /locations/countries`
- `GET /locations/regions?query=моск&limit=20`
- `GET /locations/cities?region_code=<код_региона>&query=...&limit=20`

Ожидание:
- ответы `200`,
- в `countries` есть `RU`,
- `regions/cities` возвращают данные по фильтру,
- без токена `locations/*` возвращают `401`.

## 3) Проверка обновления профиля локации

Сценарий:
1. Открыть профиль в приложении.
2. Выбрать область через поиск.
3. Выбрать город через поиск.
4. Нажать «Сохранить профиль».
5. Проверить `GET /me/profile`.

Ожидание:
- в `me/profile` заполнены `country_code='RU'`, `region_code`, `city_code`,
- `region_name` и `city_name` соответствуют выбранным значениям.

## 4) Проверка сброса локации в профиле

Сценарий A (сброс города):
1. Нажать «Сбросить город».
2. Сохранить профиль.
3. Проверить `GET /me/profile`.

Ожидание:
- `city_code = null`,
- `region_code` сохранен.

Сценарий B (сброс области):
1. Нажать «Сбросить область».
2. Сохранить профиль.
3. Проверить `GET /me/profile`.

Ожидание:
- `region_code = null`,
- `city_code = null`.

## 5) Проверка API leaderboard

Проверки:

- `GET /leaderboard?scope=country&metric=area`
- `GET /leaderboard?scope=country&metric=distance`
- `GET /leaderboard?scope=region&metric=area`
- `GET /leaderboard?scope=city&metric=distance`

Ожидание:
- `200`,
- структура ответа валидная: `scope`, `metric`, `entries`, `my_rank`, `my_score`,
- сортировка меняется при переключении `metric`,
- для `region/city` без заполненной локации у пользователя возвращается `422`.

## 6) Проверка UI рейтинга

Сценарий:
1. Открыть экран «Рейтинг» из профиля.
2. Переключать фильтры:
   - `Город / Область / Страна`
   - `Площадь / Дистанция`
3. Проверить обновление списка и блока «Ваш ранг».

Ожидание:
- список перезапрашивается и обновляется,
- нет падений экрана/исключений,
- форматы значений корректны (`м`, `км`, `м²`, `км²` по текущим форматтерам).

## 7) Проверка регрессий базовых сценариев

- Логин/логаут.
- Просмотр карты.
- История пробежек.
- Профиль (изменение имени/пароля/цвета).

Ожидание:
- существующие фичи работают как до изменений.

## 8) Автотесты

Backend integration tests:

```bash
cd python_backend
./.venv/bin/python -m unittest discover -s tests -p "test_*.py" -v
```

Ожидание:
- `test_locations_leaderboard.py` проходит полностью.
