# Сводка для продолжения разработки (уведомления + push)

Этот файл — handoff для следующей нейронки/разработчика: что уже внедрено, что настроено локально, где смотреть код, какие риски и как чинить типовые проблемы.

## 1) Цель, которая реализовывалась

- In-app уведомления о захвате территории.
- История уведомлений (последние 10).
- Отдельный экран уведомлений.
- Локальные системные уведомления в приложении.
- Интеграция FCM (Android/iOS кодово), регистрация токенов на backend, отправка push при захвате.

## 2) Что уже сделано

### 2.1 База данных

- Добавлена история уведомлений:
  - таблица `user_notifications` (до 10 хранится бизнес-логикой).
- Добавлены push токены:
  - таблица `user_push_tokens`.
- Обновлена функция `finalize_run_capture`:
  - пишет записи в `user_notifications`,
  - чистит историю до 10 на пользователя.

Ключевые файлы:
- `db/schema.sql`
- `db/functions.sql`

### 2.2 Backend (FastAPI)

- Новые/обновленные API:
  - `GET /notifications/last`
  - `GET /notifications?limit=10`
  - `POST /push-tokens`
  - `DELETE /push-tokens`
- Добавлен push-сервис через Firebase Admin SDK.
- В `runs.finish` после захвата отправляются push жертвам.
- Добавлена очистка невалидных токенов (по коду ошибки FCM).

Ключевые файлы:
- `python_backend/app/routers/notifications.py`
- `python_backend/app/routers/push_tokens.py`
- `python_backend/app/routers/runs.py`
- `python_backend/app/push.py`
- `python_backend/app/models.py`
- `python_backend/app/main.py`
- `python_backend/app/settings.py`
- `python_backend/requirements.txt`

### 2.3 Flutter

- Добавлен экран уведомлений:
  - `flutter_fronted/lib/src/features/notifications/presentation/notifications_page.dart`
- Добавлен polling истории уведомлений.
- Добавлена FCM-интеграция:
  - request permission,
  - получение token,
  - отправка token на backend,
  - обработка foreground сообщений.
- Добавлены локальные уведомления.
- На колокольчике реализован индикатор непрочитанных (красная точка).
- При открытии экрана уведомлений последнее уведомление помечается как прочитанное.

Ключевые файлы:
- `flutter_fronted/lib/src/features/notifications/application/last_notification_provider.dart`
- `flutter_fronted/lib/src/features/notifications/application/push_messaging_provider.dart`
- `flutter_fronted/lib/src/features/notifications/application/notification_read_state_provider.dart`
- `flutter_fronted/lib/src/features/notifications/data/notifications_api.dart`
- `flutter_fronted/lib/src/features/notifications/data/notifications_repository.dart`
- `flutter_fronted/lib/src/features/notifications/domain/last_notification.dart`
- `flutter_fronted/lib/src/features/territories/presentation/map_page.dart`
- `flutter_fronted/lib/src/app/router.dart`
- `flutter_fronted/lib/src/app/app.dart`
- `flutter_fronted/lib/main.dart`
- `flutter_fronted/lib/src/core/notifications/local_notifications_service.dart`

### 2.4 Android конфиг

- Подключен Google services plugin.
- Исправлен package id под Firebase config:
  - `com.claus.run_application`
- Добавлено разрешение на уведомления (`POST_NOTIFICATIONS`).
- Включен desugaring для `flutter_local_notifications`.

Ключевые файлы:
- `flutter_fronted/android/settings.gradle.kts`
- `flutter_fronted/android/app/build.gradle.kts`
- `flutter_fronted/android/app/src/main/AndroidManifest.xml`
- `flutter_fronted/android/app/src/main/kotlin/com/example/run_application/MainActivity.kt`

## 3) Локальные секреты и ignore

- Файлы добавлены локально:
  - `flutter_fronted/android/app/google-services.json`
  - `python_backend/secrets/firebase-service-account.json`
- Они должны не коммититься:
  - `flutter_fronted/.gitignore` игнорирует `google-services.json` и iOS plist.
  - `python_backend/.gitignore` игнорирует `secrets/` и `*firebase-adminsdk*.json`.
- FCM env вынесен в `python_backend/.env.local` (игнорируется git):
  - `FCM_ENABLED=true`
  - `FCM_SERVICE_ACCOUNT_JSON_PATH=.../python_backend/secrets/firebase-service-account.json`

## 4) Что проверить перед дальнейшей доработкой

1. В БД применены актуальные `db/schema.sql` и `db/functions.sql`.
2. Backend поднят с `APP_ENV=local` и читает `.env.local`.
3. `POST /push-tokens` реально вызывается после логина (видно в логах backend).
4. В `user_push_tokens` есть токены.
5. У атакующего run действительно имеет `victims_count > 0` (иначе push не отправится никому).

## 5) Известные ограничения

- Полноценный iOS push требует APNs/Apple Developer setup (платный этап).
- Без APNs на iOS можно полагаться только на локальные уведомления/foreground-поведение.
- На Android Emulator локация по умолчанию часто фиктивная (`-122...`), нужно вручную задавать.

## 6) Бэклог для следующей итерации

- Добавить явные backend-логи отправки push:
  - сколько токенов найдено,
  - результат отправки (success/fail),
  - коды ошибок FCM.
- Добавить endpoint/метод “mark as read” на backend (сейчас read-state хранится локально на устройстве).
- Добавить счетчик непрочитанных как серверное состояние (если нужно синхронизировать между устройствами).
- Добавить e2e тест-кейс “A атакует B -> B получает push + запись в feed”.
- Для iOS production: подключить APNs key в Firebase и проверить background/terminated delivery.

## 7) Частые проблемы и исправления

### Проблема: `SQL Error [42P01]: relation "user_notifications" does not exist`

Причина:
- `db/functions.sql` применили раньше создания таблицы.

Исправление:
1. Сначала применить `db/schema.sql`.
2. Затем применить `db/functions.sql`.

### Проблема: `invalid column reference precision`

Причина:
- SQL-диалект/парсер в инструменте конфликтует с `double precision`.

Исправление:
- Использовать `float8` для `stolen_area_m2` в уведомлениях (уже внесено).

### Проблема: Android build падает с `requires core library desugaring`

Причина:
- Для `flutter_local_notifications` не включен desugaring.

Исправление:
- В `android/app/build.gradle.kts`:
  - `isCoreLibraryDesugaringEnabled = true`
  - dependency `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`

### Проблема: Push не приходит, но запись в уведомлениях есть

Причины:
- run без жертв (`victims_count=0`);
- токен зарегистрирован не у того аккаунта/устройства;
- устройство в foreground/notification policy не показывает системный баннер;
- FCM credentials mismatch.

Проверка:
- `user_push_tokens` содержит актуальный токен?
- у run есть `victims_count > 0`?
- в backend логе был `POST /push-tokens` для нужного пользователя?

### Проблема: неверная геолокация на эмуляторе

Причина:
- Эмулятор отдает дефолтные координаты.

Исправление:
- Extended controls -> Location -> Send координаты,
- либо `adb -s emulator-5554 emu geo fix <lng> <lat>`.

### Проблема: устройство не запускается по Wi‑Fi

Причина:
- ADB over TCP не включен или другой сегмент сети.

Исправление:
1. USB: `adb tcpip 5555`
2. `adb connect <PHONE_IP>:5555`
3. `flutter run -d <PHONE_IP>:5555 --dart-define=API_BASE_URL=http://<MAC_IP>:8000`

## 8) Короткая команда запуска (локально)

Backend:

```bash
cd python_backend
source .venv/bin/activate
pip install -r requirements.txt
./run.sh
```

Flutter (Android):

```bash
cd flutter_fronted
flutter pub get
flutter run -d <device_id_or_ip:5555> --dart-define=API_BASE_URL=http://<MAC_IP>:8000
```

