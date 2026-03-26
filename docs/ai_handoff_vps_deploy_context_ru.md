# Handoff для ИИ: прод-контур VPS + backend + мобильный клиент

Краткий контекст по уже проделанной работе. Цель: быстро понять архитектуру, пути к файлам и типовые грабли.

## Проект

- **Backend:** `python_backend/` — FastAPI, Uvicorn, JWT, Postgres через psycopg3.
- **БД:** PostgreSQL + **PostGIS** (схема и функции в `db/schema.sql`, `db/functions.sql`).
- **Мобильный клиент:** `flutter_fronted/` — `API_BASE_URL` через `--dart-define` / `String.fromEnvironment`.
- **Прод API:** `https://api.georunapp.ru` (домен `georunapp.ru`, VPS у Beget).

## Инфраструктура на VPS

- **ОС:** Ubuntu 24.04, пользователь для деплоя: `claus` (пример), проект: **`/opt/run_application`**.
- **Стек:** `docker-compose.prod.yml` — сервисы **`db`** (postgis/postgis), **`backend`**, **`nginx`** (`80`/`443`).
- **Переменные:** файл **`.env`** рядом с compose (в git не коммитится). Нужны согласованные **`POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB`** и **`DATABASE_URL=postgresql://USER:PASS@db:5432/DB`** (хост **`db`** — имя сервиса в compose).
- **Инициализация БД (один раз или после сброса volume):** `deploy/init-db.sh` (прогоняет `db/schema.sql` и `db/functions.sql`).
- **Health:** `GET /health` → `{"ok":true,"env":"release"}`.

## HTTPS

- Nginx по HTTP отдаёт ACME challenge из тома **`certbot-www`**; сертификаты Let’s Encrypt на **хосте** в `/etc/letsencrypt`.
- В **`docker-compose.prod.yml`** у **`nginx`** монтирование **`/etc/letsencrypt:/etc/letsencrypt:ro`** (не пустой том `certbot-conf`), иначе контейнер не видит выданные certbot’ом файлы.
- Готовый vhost с TLS: **`deploy/nginx/default-ssl.example.conf`** (в проекте уже под **`api.georunapp.ru`**). На сервере копируется в **`deploy/nginx/default.conf`**.
- Подробности: **`deploy/HTTPS_LETSENCRYPT.md`**.

## DNS

- Зона у **Beget**; для API — **`A`** `api` → IP VPS.
- Если авторитативные NS Beget отвечают, а публичные резолверы долго давали **`NXDOMAIN`** — проблема делегирования/реестра `.ru`, не сервера.

## CI/CD (GitHub)

- **Сборка образа:** `.github/workflows/backend-docker.yml` → **GHCR**, теги `latest` и `sha-<commit>`.
- **Деплой по SSH:** `.github/workflows/deploy-vps.yml` (ручной *workflow_dispatch*). Секреты: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `DEPLOY_PATH` (часто `/opt/run_application`).
- Если на сервере есть **`docker-compose.fcm.yml`**, workflow подключает **два** compose-файла при `pull`/`up`.

## Flutter — продакшен API без ручного `--dart-define`

- **`flutter_fronted/config/dart_define.prod.json`** — `API_BASE_URL: https://api.georunapp.ru`.
- **`flutter_fronted/build_release.sh`** — обёртка: по умолчанию `appbundle`, опции `apk` / `ipa` / `ios`. Использует **`--dart-define-from-file=config/dart_define.prod.json`**.
- Команды вида **`flutter build release`** в Flutter **нет**; релиз — **`flutter build appbundle --release`** (или скрипт выше).

## FCM (push)

- По умолчанию на проде **`FCM_ENABLED`** не задан → **`false`**, сервер **не шлёт** FCM.
- Включение: **`deploy/FCM_PRODUCTION.md`**, **`docker-compose.fcm.yml`**, ключ в **`secrets/firebase-adminsdk.json`** (каталог **`secrets/`** в **`.gitignore`**).

## Типовые поломки (уже встречались)

1. **`password authentication failed for user "…"`** — расхождение пароля **внутри уже инициализированного** Postgres volume и строки **`DATABASE_URL`** / **`POSTGRES_PASSWORD`**. Первый `up` задаёт пароль в данных БД; смена только `.env` не обновляет Postgres → **`ALTER USER`** или снос **`pgdata`** и заново `init-db`.
2. **Нет `DATABASE_URL` в `.env`** — backend берёт дефолты из `settings.py` (`127.0.0.1`, другой пользователь), подключение к **`db`** ломается.
3. **Расхождение `POSTGRES_USER` и логина в `DATABASE_URL`** — путаница при первом создании тома vs текущий `.env`.
4. Логи: **`docker compose -f docker-compose.prod.yml logs backend`** (на VPS).

## Куда смотреть дальше

| Тема | Файл / раздел |
|------|----------------|
| Прогресс/чеклист вручную | `docs/vps_deploy_progress.md` |
| Деплой с нуля | `docs/backend_db_deploy_from_scratch.md` |
| Beget / compose / CD | `deploy/README.md` |
| HTTPS | `deploy/HTTPS_LETSENCRYPT.md` |
| FCM | `deploy/FCM_PRODUCTION.md` |
| Пример `.env` | `env.production.example` |

## Безопасность

- Реальные пароли, JWT-секреты и Firebase JSON **не** должны попадать в git / чаты.
- Порт **5432** наружу не открывать.
