#!/usr/bin/env bash
set -euo pipefail

# Allow overriding backend and device from environment.
DEVICE_ID="${DEVICE_ID:-192.168.1.138:5555}"
BACKEND_HOST="${BACKEND_HOST:-$(ipconfig getifaddr en0 || true)}"
BACKEND_PORT="${BACKEND_PORT:-8000}"

if [[ -z "${BACKEND_HOST}" ]]; then
  echo "Cannot detect local Wi-Fi IP. Set BACKEND_HOST manually."
  echo "Example: BACKEND_HOST=192.168.1.100 ./run.sh"
  exit 1
fi

flutter run -d "${DEVICE_ID}" --dart-define="API_BASE_URL=http://${BACKEND_HOST}:${BACKEND_PORT}"