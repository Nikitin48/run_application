#!/usr/bin/env bash
# Релизная сборка с продакшен API (см. config/dart_define.prod.json).
#
#   ./build_release.sh                    → Android App Bundle
#   ./build_release.sh apk                → APK
#   ./build_release.sh ipa                → iOS IPA
#   ./build_release.sh ios                → iOS без IPA
# Любые дальнейшие аргументы уходят в flutter build …
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

DEFINES="$(pwd)/config/dart_define.prod.json"
if [[ ! -f "$DEFINES" ]]; then
  echo "Не найден $DEFINES" >&2
  exit 1
fi

TARGET="appbundle"
case "${1:-}" in
  appbundle|apk|ipa|ios)
    TARGET="$1"
    shift
    ;;
esac

case "$TARGET" in
  appbundle)
    flutter build appbundle --release --dart-define-from-file="$DEFINES" "$@"
    ;;
  apk)
    flutter build apk --release --dart-define-from-file="$DEFINES" "$@"
    ;;
  ipa)
    flutter build ipa --release --dart-define-from-file="$DEFINES" "$@"
    ;;
  ios)
    flutter build ios --release --dart-define-from-file="$DEFINES" "$@"
    ;;
esac
