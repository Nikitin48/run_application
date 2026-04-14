# VPS деплой: рейтинг + локации РФ

Отдельный пошаговый runbook для выката изменений с рейтингом и справочниками локаций на VPS.

## Что входит в релиз

- Backend API:
  - `GET /leaderboard`
  - `GET /locations/countries`
  - `GET /locations/regions`
  - `GET /locations/cities`
- Миграции БД:
  - `db/migrations/20260409_leaderboard_locations.sql`
  - `db/migrations/20260409_drop_unused_location_timestamps.sql` (если применимо)
- Импорт справочника:
  - `python_backend/scripts/import_ru_locations.py`
  - датасет `region;city` (например `final_cities.csv`)

## 0) Подготовка (локально)

1. Убедиться, что изменения закоммичены и запушены в нужную ветку.
2. Убедиться, что в коммит **не попали**:
   - `.env`, `secrets/*`
   - `__pycache__/*`, `.pyc`
3. Проверить локально:
   - backend health,
   - интеграционные тесты,
   - базовый smoke фронта.

## 1) Подключение к VPS

```bash
ssh -i ~/.ssh/vps_run_app claus@<VPS_IP>
cd /opt/run_application
```

## 2) Backup БД (обязательно)

```bash
cd /opt/run_application
TS=$(date +%F-%H%M%S)
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "/tmp/run_application.$TS.sql"
ls -lh "/tmp/run_application.$TS.sql"
```

## 3) Обновление кода на VPS

Если есть локальные правки на сервере:

```bash
cd /opt/run_application
git stash push -m "vps-local-config" -- deploy/nginx/default.conf docker-compose.prod.yml
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
git stash pop
```

Если правок нет:

```bash
cd /opt/run_application
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
```

## 4) Применение миграций

### 4.1 Основная миграция

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260409_leaderboard_locations.sql
```

### 4.2 Удаление timestamp-полей в ref_* (если на VPS старая версия схемы)

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260409_drop_unused_location_timestamps.sql
```

## 5) Импорт справочника регионов/городов

Важно: текущий Docker-образ backend содержит только каталог `app/`.
Скрипты из `python_backend/scripts` в контейнере отсутствуют, поэтому импорт выполняем через временное копирование скрипта и CSV в running backend-контейнер.

### Импорт `final_cities.csv` (рекомендуемый путь)

```bash
cd /opt/run_application

# 1) Узнать id контейнера backend
BACKEND_CID=$(docker compose -f docker-compose.prod.yml ps -q backend)
echo "$BACKEND_CID"

# 2) Скопировать скрипт и датасет в контейнер
docker cp python_backend/scripts/import_ru_locations.py "$BACKEND_CID:/tmp/import_ru_locations.py"
docker cp data_cities/final_cities.csv "$BACKEND_CID:/tmp/final_cities.csv"

# 3) Выполнить импорт внутри контейнера (там корректный DATABASE_URL -> db:5432)
docker compose -f docker-compose.prod.yml exec -T backend sh -lc \
  'python /tmp/import_ru_locations.py \
    --dataset-csv /tmp/final_cities.csv \
    --replace-all'
```

### Альтернатива: импорт `ru_regions.csv` + `ru_cities.csv`

```bash
cd /opt/run_application
BACKEND_CID=$(docker compose -f docker-compose.prod.yml ps -q backend)

docker cp python_backend/scripts/import_ru_locations.py "$BACKEND_CID:/tmp/import_ru_locations.py"
docker cp python_backend/data/ru_regions.csv "$BACKEND_CID:/tmp/ru_regions.csv"
docker cp python_backend/data/ru_cities.csv "$BACKEND_CID:/tmp/ru_cities.csv"

docker compose -f docker-compose.prod.yml exec -T backend sh -lc \
  'python /tmp/import_ru_locations.py \
    --regions-csv /tmp/ru_regions.csv \
    --cities-csv /tmp/ru_cities.csv \
    --replace-all'
```

## 6) Перезапуск backend

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
docker compose -f docker-compose.prod.yml ps
```

## 7) Smoke-check после выката

```bash
curl -sS https://api.georunapp.ru/health
```

С токеном:

```bash
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/locations/countries"
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/locations/regions?query=мос"
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/leaderboard?scope=country&metric=area"
```

Проверки БД:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as regions from ref_regions;"'
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as cities from ref_cities;"'
```

## 8) Rollback

1. Откатить код на предыдущий стабильный commit/образ backend.
2. Перезапустить backend.
3. Если критическая несовместимость данных:
   - восстановить дамп из `/tmp/run_application.<timestamp>.sql`.
4. Предпочтительно делать `forward-fix`, чтобы не терять новые записи.

## 9) Контрольный список “готово”

- `/health` отвечает `ok=true`.
- `locations/*` и `leaderboard` отвечают `200` для авторизованного пользователя.
- Справочник загружен (ожидаемые количества).
- Логин/профиль/история/карта не сломаны.
