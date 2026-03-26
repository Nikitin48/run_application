# Документация по фронтенду (Flutter) — что сделано и как работает flow пробежки

## Стек и архитектура

- **UI**: Flutter + Material 3
- **State management**: Riverpod
- **Routing**: GoRouter
- **Networking**: Dio (с перехватчиком токенов + refresh)
- **Storage**: flutter_secure_storage (хранение access/refresh токенов)
- **Map**: flutter_map + OSM тайлы
- **GPS**: geolocator
- **Connectivity**: connectivity_plus
- **Clean-ish**: разделение на `domain / data / application / presentation`, плюс **usecases** и **domain interfaces** для репозиториев.

Структура фич:
- `features/auth`
- `features/territories`
- `features/notifications`
- `features/runs`

## Конфигурация backend URL

Мы используем `API_BASE_URL` (dart-define) + дефолты:
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://127.0.0.1:8000`
- Физическое устройство:
  - Wi‑Fi: `--dart-define=API_BASE_URL=http://<MAC_IP>:8000`
  - или **adb reverse**: `--dart-define=API_BASE_URL=http://127.0.0.1:8000`

Важно: для Android разрешён HTTP (`usesCleartextTraffic=true`), для iOS включён ATS allow (dev).

### Продакшен (store / реальный backend)

- Файл **`config/dart_define.prod.json`**: `API_BASE_URL` → `https://api.georunapp.ru`.
- Команда из корня фронта: **`./build_release.sh`** (по умолчанию **App Bundle** для Google Play).
- Вручную то же самое:  
  `flutter build appbundle --release --dart-define-from-file=config/dart_define.prod.json`

## Авторизация (flow)

1) Пользователь открывает экран **Вход/Регистрация**.
2) `AuthController` вызывает usecase:
   - `LoginUseCase` или `RegisterUseCase`
3) Токены (`access_token`, `refresh_token`) сохраняются в `TokenStorage` (secure storage).
4) `GoRouter` делает redirect:
   - если авторизован → `/map`
   - если нет → `/login`

### Авто-refresh токена

Dio использует `TokenInterceptor`:
- на каждый запрос подставляет `Authorization: Bearer <access>`
- при ответе 401 пытается `POST /auth/refresh` и **повторяет** исходный запрос
- если refresh не удался → очищает токены

## Карта и территории (flow)

Экран `/map`:
- подложка OSM (TileLayer)
- территории подгружаются по bbox: `GET /territories?minLng&minLat&maxLng&maxLat`
- GeoJSON `Polygon/MultiPolygon` парсится в списки точек и рисуется `PolygonLayer`

## Пробежка (flow) — главное

### 1) Старт

Нажимаем **Старт**:
- `RunTrackerController.start()`:
  - проверяет GPS сервис и permissions
  - подписывается на:
    - `Geolocator.getPositionStream` (точки)
    - `Connectivity().onConnectivityChanged` (автопауза по internet_lost)

### 2) Запись точек

Пока `phase == running`:
- новые точки добавляются в `state.points`
- на карте рисуется `Polyline` и маркер текущей точки
- есть простой throttle (не чаще ~800мс)

Автопауза по GPS:
- если `accuracy > 35` → открывается pause `gps_lost`
- как только точность снова нормальная → pause автоматически закрывается и запись продолжается

### 3) Ручная пауза

Кнопка **Пауза** → pause `manual`.
Кнопка **Продолжить** → закрывает pause.

### 4) Финиш и отправка на backend

Нажимаем **Финиш**:
- формируется `FinishRunRequest`:
  - `started_at`, `ended_at`
  - `points[]` (lat/lng/ts/accuracy/speed/altitude)
  - `pauses[]` (manual/gps_lost/internet_lost)
- отправка: `POST /runs/finish`
- пока идёт запрос: overlay “загрузка”
- после успеха:
  - обновляем `territories` (invalidate по bbox)
  - обновляем `notifications/last`
  - переходим на экран `/run-summary`

## Итоги пробежки

Экран `/run-summary` показывает:
- дистанцию, времена (elapsed/paused/moving), темп
- площадь захвата и число “жертв”
Кнопка “Готово” возвращает на карту и очищает `lastFinish`.

## Уведомления “у вас отжали”

На карте показывается баннер, если `GET /notifications/last` вернул `has_notification=true`.
Есть действия: **обновить** и **закрыть**.

## Тестовый режим (эмуляция движения)

На карте есть **Test mode**:
- включается кнопкой рядом с “Ко мне”
- появляется D-pad со стрелками
- стрелки сдвигают текущую позицию на 5 метров и, если пробежка запущена, добавляют “симулированные точки” в трек.


