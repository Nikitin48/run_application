# VPS деплой: история пробежек с `capture_geom` и превью карты

Пошаговая инструкция для выката изменений, где:
- в `runs` добавляется `capture_geom`,
- `GET /runs/history` отдает `capture_geojson` и `track_geojson`,
- фронт рисует превью области/трека в карточке истории.

## Что входит в релиз

- Миграция БД:
  - `db/migrations/20260410_runs_capture_geom.sql`
- Backend:
  - `python_backend/app/routers/runs.py`
  - `python_backend/app/models.py`
- Frontend:
  - `flutter_fronted/lib/src/features/histories/presentation/histories_page.dart`
  - `flutter_fronted/lib/src/features/runs/domain/run_models.dart`

## 0) Подготовка (локально)

1. Убедиться, что изменения закоммичены и запушены в нужную ветку (`dev`).
2. Проверить, что в коммит не попали:
   - `.env`, `secrets/*`
   - `__pycache__/*`, `.pyc`
3. Локально проверить:
   - backend стартует без ошибок,
   - история пробежек открывается,
   - в карточке истории отображается превью.

## 1) Подключение к VPS

```bash
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208
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

Если есть локальные правки на сервере (например `deploy/nginx/default.conf`, `docker-compose.prod.yml`):

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

## 4) Применение миграции `capture_geom`

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260410_runs_capture_geom.sql
```

Ожидаемый результат: успешный `COMMIT`.

## 5) Пересборка и перезапуск backend

Важно: не полагаться на старый локальный образ. Явно пересобрать backend.

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml build backend
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
docker compose -f docker-compose.prod.yml ps
```

## 6) Smoke-check API после выката

```bash
curl -sS https://api.georunapp.ru/health
```

Проверка истории (нужен access token):

```bash
curl -sS -H "Authorization: Bearer <TOKEN>" \
  "https://api.georunapp.ru/runs/history?limit=5&offset=0"
```

Проверить, что в элементах ответа присутствуют:
- `capture_geojson`
- `track_geojson`

## 7) Проверки БД

Проверка заполненности `capture_geom` у существующих пробежек:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT
      COUNT(*) AS total_runs,
      COUNT(*) FILTER (WHERE capture_geom IS NOT NULL) AS runs_with_capture_geom
    FROM runs;
  "'
```

Опционально посмотреть последние записи:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT id, status, capture_area_m2, capture_geom IS NOT NULL AS has_geom, created_at
    FROM runs
    ORDER BY created_at DESC
    LIMIT 10;
  "'
```

## 8) Проверка в приложении

1. Открыть экран истории.
2. Убедиться, что в каждом элементе с захватом есть превью карты.
3. Проверить, что:
   - полигон области отображается,
   - трек отображается,
   - цвет трека/области соответствует текущему цвету территории пользователя.

## 9) Rollback

1. Откатить backend на предыдущий стабильный commit/образ.
2. Перезапустить backend:
   - `docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend`
3. Если критическая проблема в данных:
   - восстановить дамп из `/tmp/run_application.<timestamp>.sql`.
4. Предпочтительно делать `forward-fix`, если это безопаснее для новых данных.

## 10) Короткий чеклист "готово"

- `health` отвечает корректно.
- Миграция `20260410_runs_capture_geom.sql` применена.
- `/runs/history` возвращает `capture_geojson` и `track_geojson`.
- В UI истории видны превью карт с полигоном и треком.
- Ошибок в логах backend после деплоя нет.
