# FCM (push) на продакшен VPS

Сейчас backend шлёт пуши через **Firebase Admin SDK** (`python_backend/app/push.py`). Пока **`FCM_ENABLED=false`** или нет JSON-ключа — **пуши не отправляются** (это нормально).

## 1. Firebase Console

1. Откройте [Firebase Console](https://console.firebase.google.com) → ваш проект (тот же, что в приложении: `google-services.json` / `GoogleService-Info.plist`).
2. **Project settings** → **Service accounts**.
3. **Firebase Admin SDK** → **Generate new private key** → скачайте JSON.

Этот файл **нельзя** коммитить в git.

## 2. Файл на VPS

На сервере в каталоге проекта (например `/opt/run_application`):

```bash
cd /opt/run_application
mkdir -p secrets
chmod 700 secrets
```

Скопируйте JSON с компьютера (с Mac; подставьте путь к скачанному файлу):

```bash
scp -i ~/.ssh/vps_run_app /path/to/your-firebase-adminsdk.json \
  claus@<VPS_IP>:/opt/run_application/secrets/firebase-adminsdk.json
chmod 600 /opt/run_application/secrets/firebase-adminsdk.json
```

Имя файла на сервере должно совпадать с тем, что в compose: **`secrets/firebase-adminsdk.json`**.

## 3. Переменные в `.env`

Добавьте в `/opt/run_application/.env`:

```env
FCM_ENABLED=true
FCM_SERVICE_ACCOUNT_JSON_PATH=/secrets/firebase-adminsdk.json
```

Имя переменной совпадает с `python_backend/env.example`.

## 4. Два compose-файла

В репозитории есть **`docker-compose.fcm.yml`** — он только монтирует ключ в контейнер `backend`.

После `git pull` на VPS поднимайте стек так:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml pull backend
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans
```

Если файла `secrets/firebase-adminsdk.json` ещё нет — **не** добавляйте второй `-f`, иначе Docker выдаст ошибку монтирования.

## 5. Проверка

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec backend \
  python -c "from app.settings import settings; print(settings.fcm_enabled, settings.fcm_service_account_json_path)"

docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec backend \
  ls -la /secrets/firebase-adminsdk.json
```

Ожидается: `True`, путь `/secrets/...`, файл существует.

В логах при первой отправке пуша не должно быть `Failed to initialize Firebase`.

## 6. Мобильное приложение

- Тот же **Firebase project**, что и JSON на сервере.
- Релизная сборка с вашим `API_BASE_URL` (например `./build_release.sh`).
- Разрешения на уведомления; токен должен уходить на **`POST /push-tokens`** (уже в приложении).

## 7. GitHub Actions Deploy

Workflow **Deploy to VPS** при наличии на сервере файла **`docker-compose.fcm.yml`** сам подключает его к `docker compose`. Если файла нет — используется только `docker-compose.prod.yml`.

После первого включения FCM на сервере выполните **`git pull`**, чтобы появился `docker-compose.fcm.yml` и актуальный workflow.
