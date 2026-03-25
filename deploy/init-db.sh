#!/usr/bin/env bash
# Первичное применение schema.sql и functions.sql к Postgres в compose.
# Запускать на сервере из корня репозитория (рядом с docker-compose.prod.yml):
#   chmod +x deploy/init-db.sh
#   ./deploy/init-db.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Создай файл .env (см. env.production.example)." >&2
  exit 1
fi

docker compose -f docker-compose.prod.yml exec -T db \
  sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < "$ROOT/db/schema.sql"

docker compose -f docker-compose.prod.yml exec -T db \
  sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < "$ROOT/db/functions.sql"

echo "OK: схема и функции применены."
