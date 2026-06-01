# Деплой backend + Postgres на VPS (Beget и любой другой хост)

Стек: `docker-compose.prod.yml` — **PostGIS**, **FastAPI backend**, **Nginx** (reverse proxy на порту 80; HTTPS подключается отдельно).

## 1. VPS (Beget)

1. Заказать VPS с **Ubuntu 22.04/24.04**, зафиксировать публичный **IPv4**.
2. В панели Beget (и на самой ВМ — `ufw`) открыть **22, 80, 443**. Порт **5432 наружу не публиковать**.
3. Установить Docker Engine и плагин Compose (официальная инструкция Docker для Ubuntu).

## 2. Код и конфигурация на сервере

Вариант A — **клонировать репозиторий** на сервер, например в `/opt/run-application`:

```bash
sudo mkdir -p /opt/run-application
sudo chown "$USER:$USER" /opt/run-application
cd /opt/run-application
git clone <url> .
```

Вариант B — скопировать минимум: `docker-compose.prod.yml`, каталог `deploy/nginx/`, `python_backend/` (только если собираете образ на сервере; при деплое из GHCR достаточно compose + `deploy/` + `db/` для `init-db.sh`).

Создать `.env`:

```bash
cp env.production.example .env
nano .env
```

Обязательно задать `POSTGRES_*`, `JWT_SECRET`, `DATABASE_URL` с хостом **`db`** (имя сервиса в compose). При необходимости создать пустой `touch .env.release`, если приложение ожидает второй файл рядом (в разработке он используется для Yandex; в Docker достаточно переменных в `.env`).

Первый запуск БД и приложения:

```bash
docker compose -f docker-compose.prod.yml up -d
./deploy/init-db.sh
docker compose -f docker-compose.prod.yml restart backend
```

Проверка: `curl -sS http://127.0.0.1/health` (через Nginx) или с внешнего IP `http://<IP>/health`.

## 3. Домен и HTTPS

Пошагово с командами: **[deploy/HTTPS_LETSENCRYPT.md](HTTPS_LETSENCRYPT.md)** (DNS, `certbot`, правка `docker-compose.prod.yml` для монтирования `/etc/letsencrypt`, пример конфига **`deploy/nginx/default-ssl.example.conf`**).

Для Flutter в проде используйте `API_BASE_URL=https://api.<домен>` (`--dart-define` или flavor).

## 3.1. Push (FCM)

Серверные пуши: **[deploy/FCM_PRODUCTION.md](FCM_PRODUCTION.md)** (файл `docker-compose.fcm.yml`, ключ в `secrets/`).

## 4. CI/CD (GitHub Actions)

- **`.github/workflows/backend-docker.yml`**: при push в `main` (если менялись пути из списка в файле) собирает образ и пушит в **ghcr.io** с тегами `latest` и `sha-<полный_commit_sha>` (имя образа в нижнем регистре).
- **`.github/workflows/deploy-vps.yml`**: **только** ручной запуск *Workflow dispatch*. Параметр **image_tag** по умолчанию `latest`; для зафиксированной версии укажите `sha-<полный_sha>` из собравшего коммита.

Секреты репозитория (Settings → Secrets and variables → Actions):

- `VPS_HOST` — IP или имя VPS.
- `VPS_USER` — SSH-пользователь с правом запускать `docker compose` в каталоге деплоя.
- `VPS_SSH_KEY` — приватный ключ (PEM). Пароль на ключ в `appleboy/ssh-action` не передаётся; удобнее ключ **без passphrase** или отдельный деплой-ключ.
- `DEPLOY_PATH` — абсолютный путь к каталогу с `docker-compose.prod.yml` (например `/opt/run_application`).

На VPS один раз выполните `docker login ghcr.io` пользователем с доступом **read:packages**, если пакет с образом **приватный**.

При деплое `BACKEND_IMAGE` задаётся на runner и передаётся в SSH-сессию; дублировать в `.env` на сервере не обязательно.

## 6. Фоновые задачи в backend

Отдельных serverless/cron-сервисов в проекте нет — всё крутится в контейнере **backend** на VPS.

- **Спорные территории:** каждые ~15 с вызывается `resolve_expired_territory_contests()` (см. `TERRITORY_CONTEST_RESOLVE_*` в `python_backend/env.example`). Пока `backend` жив и `restart: unless-stopped`, споры закрываются по `resolve_at` без действий пользователя.
- Проверка в логах: `docker compose -f docker-compose.prod.yml logs -f backend` → строки `Territory contest background resolver started` и `Territory contest resolve tick (interval=15s): resolved=N`.

## 7. Резервные копии

- Снимки диска в панели Beget (если доступны).
- Регулярный `pg_dump` с выгрузкой на внешнее хранилище — по мере роста ценности данных.
