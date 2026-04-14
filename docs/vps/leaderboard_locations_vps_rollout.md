# VPS rollout: leaderboard + locations without DB data loss

Этот runbook дополняет:
- `docs/ai_handoff_vps_deploy_context_ru.md`
- `docs/guide/vps_pull_conflict_quick_guide.md`

## 1) Подготовка

```bash
ssh -i ~/.ssh/vps_run_app claus@<VPS_IP>
cd /opt/run_application
```

Если на сервере есть локальные правки конфигов, сначала безопасный `stash`:

```bash
git stash push -m "vps-local-config" -- deploy/nginx/default.conf docker-compose.prod.yml
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
git stash pop
```

## 2) Backup БД (обязательно)

```bash
cd /opt/run_application
TS=$(date +%F-%H%M%S)
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "/tmp/run_application.$TS.sql"
ls -lh "/tmp/run_application.$TS.sql"
```

## 3) Применить миграцию схемы (additive)

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260409_leaderboard_locations.sql
```

## 4) Загрузить полный справочник регионов/городов РФ (после подготовки CSV)

Ожидаемые CSV:
- `python_backend/data/ru_regions.csv` (колонки: `code,name`)
- `python_backend/data/ru_cities.csv` (колонки: `code,region_code,name`)

Если у вас выгрузка ГАР/ФИАС в XML, сначала сгенерируйте CSV локально:

```bash
cd /opt/run_application
python scripts/gar_to_locations_csv.py \
  --gar-dir /path/to/gar_dump \
  --out-regions-csv python_backend/data/ru_regions.csv \
  --out-cities-csv python_backend/data/ru_cities.csv
```

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T backend sh -lc \
  'python scripts/import_ru_locations.py \
    --regions-csv data/ru_regions.csv \
    --cities-csv data/ru_cities.csv'
```

## 5) Перезапустить backend и проверить API

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
docker compose -f docker-compose.prod.yml ps
curl -sS https://api.georunapp.ru/health
```

Проверки новых endpoint:

```bash
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/locations/regions?query=моск"
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/locations/cities?region_code=RU-MOS&query=хим"
curl -sS -H "Authorization: Bearer <TOKEN>" "https://api.georunapp.ru/leaderboard?scope=country&metric=area"
```

## 6) Проверка целостности данных

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as users_cnt from users;"'
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as runs_cnt from runs;"'
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as stats_cnt from user_stats;"'
```

## 7) Rollback strategy

- Код: откатиться на предыдущий commit/образ backend.
- Данные: восстановление дампа из `/tmp/run_application.<timestamp>.sql` делать только при критической несовместимости.
- Предпочтительно: `forward-fix` (исправляющая миграция), чтобы не терять новые изменения данных.
