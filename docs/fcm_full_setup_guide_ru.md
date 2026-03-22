# Push сейчас и бесплатно: что делать в первую очередь

Этот документ перестроен так, чтобы сверху были только шаги, которые можно сделать **сейчас и бесплатно**.

## Что реально доступно бесплатно уже сейчас

- История уведомлений в приложении (до 10 последних) уже работает.
- Локальные системные уведомления в активном приложении уже работают.
- Полноценный push через FCM на Android можно поднять бесплатно.
- Для iOS полноценный push требует платный Apple Developer (вынесено в конец документа).

---

## 1) Бесплатный минимум для запуска сейчас

### 1.1 Применить SQL в БД

Нужно один раз применить актуальные файлы:

1. `db/schema.sql`
2. `db/functions.sql`

Это добавит:
- историю уведомлений,
- таблицу токенов устройств `user_push_tokens`,
- обновленную логику захвата + уведомлений.

### 1.2 Обновить backend env

В `python_backend/.env` добавьте:

```env
FCM_ENABLED=true
FCM_SERVICE_ACCOUNT_JSON_PATH=/absolute/path/to/firebase-service-account.json
```

Если захотите временно выключить отправку push:

```env
FCM_ENABLED=false
```

### 1.3 Подготовить Firebase service account JSON (бесплатно)

1. Откройте [Firebase Console](https://console.firebase.google.com/).
2. Выберите проект (или создайте новый).
3. `Project settings` → `Service accounts`.
4. Нажмите `Generate new private key`.
5. Сохраните JSON в безопасное место на диске.
6. Пропишите абсолютный путь в `FCM_SERVICE_ACCOUNT_JSON_PATH`.

---

## 2) Бесплатный FCM для Android (рекомендуемый следующий шаг)

### 2.1 Создать Firebase проект (если еще нет)

1. [Firebase Console](https://console.firebase.google.com/) → `Create project`.
2. Название, например: `run-application`.
3. Google Analytics можно не включать.

### 2.2 Добавить Android app в Firebase

1. В Firebase: `Add app` → Android.
2. `Android package name` = `com.example.run_application`.
3. Скачайте `google-services.json`.
4. Положите файл в:
   - `flutter_fronted/android/app/google-services.json`

### 2.3 Что уже внесено в коде (проверка)

Уже сделано:
- подключен Google Services plugin в Gradle;
- добавлено разрешение `android.permission.POST_NOTIFICATIONS`;
- добавлены пакеты `firebase_core`, `firebase_messaging`;
- токен автоматически регистрируется на backend после логина.

### 2.4 Запуск

Backend:

```bash
cd python_backend
./run.sh
```

Flutter:

```bash
cd flutter_fronted
flutter pub get
flutter run
```

---

## 3) Бесплатный сценарий проверки (Android + локально)

Нужно 2 пользователя:
- `A` (атакует),
- `B` (теряет территорию).

Сценарий:

1. На устройстве `B` залогиниться и разрешить уведомления.
2. Убедиться, что backend запущен с `FCM_ENABLED=true`.
3. На устройстве `A` сделать пробежку с захватом территории `B`.
4. Проверить на `B`:
   - приходит push: `Ваша территория была атакована`;
   - в экране `Уведомления` появилась запись.

---

## 4) Частые проблемы (бесплатная часть)

### Android push не приходит

- нет `google-services.json` в `flutter_fronted/android/app/`;
- `google-services.json` от другого package id;
- Android 13+: не выдано permission на уведомления;
- устройство/эмулятор без Google Play services.

### Backend не отправляет push

- `FCM_ENABLED=false` в env;
- неверный путь в `FCM_SERVICE_ACCOUNT_JSON_PATH`;
- ключ сервисного аккаунта от другого Firebase проекта.

---

## 5) Безопасность (обязательно)

Никогда не коммитьте:
- `firebase-service-account.json`;
- реальные секреты из `.env`.

---

## 6) Платные/ограничивающие моменты (перенесено вниз)

### iOS полноценный push (background/terminated)

Для этого нужен **Apple Developer аккаунт (платный)**, потому что требуется APNs.

Нужно будет сделать:

1. Добавить iOS app в Firebase.
2. Положить `GoogleService-Info.plist` в:
   - `flutter_fronted/ios/Runner/GoogleService-Info.plist`
3. В Apple Developer создать APNs key (`.p8`), получить `Key ID` и `Team ID`.
4. В Firebase (`Project settings` → `Cloud Messaging`) загрузить APNs key.
5. В Xcode у target `Runner` включить:
   - `Push Notifications`,
   - `Background Modes` → `Remote notifications`.

Без этого iOS реальный push работать не будет (только локальные уведомления в активном приложении).

