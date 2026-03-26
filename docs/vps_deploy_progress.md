# VPS Deploy Progress (`georunapp.ru`)

Этот файл фиксирует текущий прогресс развёртывания backend + DB на VPS и оставшиеся шаги.

## Что уже сделано

- Куплен VPS с Ubuntu 24.04.
- Создан пользователь `claus`, работа идёт не под `root`.
- Проверен и запущен SSH (`sshd active`), порт `22` слушает на `0.0.0.0`.
- Добавлен SSH-ключ для доступа.
- Установлены базовые пакеты:
  - `ca-certificates`, `curl`, `git`, `ufw`, `fail2ban`.
- Установлен Docker + Compose plugin.
- Пользователь добавлен в группу `docker` (`sudo usermod -aG docker claus`).
- Репозиторий склонирован на VPS в `/opt/run_application`.
- Поднят стек через `docker-compose.prod.yml`.
- Инициализирована БД (schema + functions) через `deploy/init-db.sh`.
- Проверен health endpoint:
  - `curl http://185.225.34.208/health` -> `{"ok":true,"env":"release"}`.
- Домен `georunapp.ru` активен, DNS зона в Beget настроена.
- В зоне есть `A` для `api` на IP VPS по данным панели.
- Публичный DNS для **`api.georunapp.ru`** подтверждён: `dig @8.8.8.8` и `dig @1.1.1.1` → **185.225.34.208** (2026-03-25).
- **HTTPS включён:** `curl https://api.georunapp.ru/health` → `{"ok":true,"env":"release"}` (Let's Encrypt + Nginx SSL-конфиг).

## Что осталось сделать

1. Зафиксировать в Flutter релизе: `API_BASE_URL=https://api.georunapp.ru` (`--dart-define` или flavor).
2. Настроить GitHub Secrets (`VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `DEPLOY_PATH`) и при необходимости **`docker login ghcr.io`** на VPS для приватного образа.
3. Деплой через **Actions → Deploy to VPS** после появления образа в GHCR.
4. Настроить **автообновление** сертификата (`certbot renew` + `nginx -s reload` в контейнере) — см. `deploy/HTTPS_LETSENCRYPT.md`.
5. (Опционально) убрать лишнюю DNS-запись `www.api`, если мешает.

## Ключевые команды, которые использовали

### SSH и доступ

```bash
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208
ssh-copy-id -i ~/.ssh/vps_run_app.pub claus@185.225.34.208
sudo systemctl status ssh --no-pager
sudo ss -tlnp | grep ':22'
```

### Docker и проверка прав

```bash
sudo usermod -aG docker claus
# перелогиниться по SSH
docker run --rm hello-world
docker compose version
```

### Запуск проекта на VPS

```bash
cd /opt/run_application
cp env.production.example .env
touch .env.release
docker compose -f docker-compose.prod.yml up -d
chmod +x deploy/init-db.sh
./deploy/init-db.sh
docker compose -f docker-compose.prod.yml restart backend
curl -sS http://127.0.0.1/health
curl -sS http://185.225.34.208/health
```

### Диагностика контейнеров

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs --tail=200 backend
docker compose -f docker-compose.prod.yml logs --tail=200 nginx
docker compose -f docker-compose.prod.yml logs --tail=200 db
```

### DNS проверки

```bash
dig +short georunapp.ru
dig +short api.georunapp.ru @8.8.8.8
dig api.georunapp.ru A @ns1.beget.com +noall +answer
dig api.georunapp.ru +trace
curl -sS http://api.georunapp.ru/health
```

### HTTPS (после того как `api.georunapp.ru` начнет резолвиться)

```bash
sudo apt install -y certbot
cd /opt/run_application
WEBROOT="$(docker volume inspect run-application_certbot-www --format '{{ .Mountpoint }}')"
sudo certbot certonly --webroot -w "$WEBROOT" \
  -d api.georunapp.ru \
  --email YOUR_EMAIL@example.com \
  --agree-tos --no-eff-email
```

Дальше:
- в `docker-compose.prod.yml` у `nginx` заменить
  - `certbot-conf:/etc/letsencrypt:ro`
  - на `/etc/letsencrypt:/etc/letsencrypt:ro`
- применить:

```bash
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
```

- взять HTTPS-конфиг из `deploy/nginx/default-ssl.example.conf`, заменить домен на `api.georunapp.ru`, затем:

```bash
docker compose -f docker-compose.prod.yml exec nginx nginx -t
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
curl -sS https://api.georunapp.ru/health
```

## GitHub CD (что подготовлено в репозитории)

- Workflow сборки образа: `.github/workflows/backend-docker.yml`
- Workflow деплоя на VPS: `.github/workflows/deploy-vps.yml`

Нужные Secrets в GitHub:

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `DEPLOY_PATH` (например `/opt/run_application`)

