#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Prefer project venv if it exists (avoids "uvicorn: command not found").
PY="./.venv/bin/python"
if [[ -x "$PY" ]]; then
  exec "$PY" -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
fi

exec python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000