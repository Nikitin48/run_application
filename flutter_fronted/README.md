# run_application

Flutter app for a running tracker with gamification (capture territories on map).

## Backend base URL (runs everywhere)

The app uses `API_BASE_URL` (dart define) with platform defaults:

- Android Emulator (default): `http://10.0.2.2:8000`
- iOS Simulator (default): `http://127.0.0.1:8000`
- Physical device: set your Mac IP:
  - `--dart-define=API_BASE_URL=http://<MAC_IP>:8000`

## Production release (Play Store / prod API)

Продакшен API задаётся в `config/dart_define.prod.json`. Сборка одной командой из каталога `flutter_fronted`:

```bash
./build_release.sh
```

По умолчанию: **`flutter build appbundle --release`** с `API_BASE_URL=https://api.georunapp.ru`.

Другие цели: `./build_release.sh apk`, `./build_release.sh ipa`, `./build_release.sh ios`.

## Location permissions

This project uses `geolocator` for GPS tracking.

- **iOS**: usage strings are in `ios/Runner/Info.plist`
- **Android**: permissions are in `android/app/src/main/AndroidManifest.xml`

## Документация по фронтенду (RU)

- `docs/FRONTEND_WORK_RU.md`
