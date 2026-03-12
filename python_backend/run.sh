#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Выбор БД при запуске: local (по умолчанию) или release (Yandex Cloud)
# Примеры: ./run.sh | ./run.sh local | ./run.sh release
APP_ENV="${1:-local}"
export APP_ENV

case "$APP_ENV" in
  local)
    echo "→ Запуск с локальной БД (APP_ENV=local, .env.local)"
    ;;
  release)
    echo "→ Запуск с облачной БД (APP_ENV=release, .env.release)"
    ;;
  *)
    echo "Неизвестный режим: $APP_ENV. Используй: local или release." >&2
    exit 1
    ;;
esac

# Prefer project venv if it exists (avoids "uvicorn: command not found").
PY="./.venv/bin/python"
if [[ -x "$PY" ]]; then
  exec "$PY" -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
fi

exec python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000