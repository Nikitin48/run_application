# Краткая инструкция: pull на VPS и решение конфликтов

Подключиться в консоли по ключу
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208


## 1) Базовый pull на VPS

```bash
cd /opt/run_application
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
```

Если ошибка `Permission denied (publickey)`:

```bash
ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes -T git@github.com
```

Проверьте, что ключ `~/.ssh/github_run_app.pub` добавлен в GitHub repo как Deploy key.

## 2) Если `git pull` блокируется локальными изменениями

Типичная ошибка:
- `Your local changes would be overwritten by merge`

Безопасный сценарий:

```bash
cd /opt/run_application
git stash push -m "vps-local-config" -- deploy/nginx/default.conf docker-compose.prod.yml
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
git stash pop
```

## 3) Если после `stash pop` конфликт

### 3.1 Проверить состояние

```bash
git status
```

Если есть `Unmerged paths` -> конфликт еще не решен.  
Если только `Changes not staged for commit` -> конфликта уже нет, это просто локальные правки.

### 3.2 Быстро восстановить рабочий compose

Если `docker compose ...` ругается на YAML (`could not find expected ':'`), проще взять чистый файл из удаленной ветки:

```bash
cd /opt/run_application
cp docker-compose.prod.yml docker-compose.prod.yml.bad.$(date +%F-%H%M)
git show origin/dev:docker-compose.prod.yml > docker-compose.prod.yml
sed -i 's#certbot-conf:/etc/letsencrypt:ro#/etc/letsencrypt:/etc/letsencrypt:ro#' docker-compose.prod.yml
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
```

## 4) Применить проверенный nginx-конфиг (если поймали редирект-петлю)

Симптом:
- `curl -sSL https://api.georunapp.ru/health` -> `Maximum redirects followed`

Фикс:

```bash
cd /opt/run_application
cp deploy/nginx/default-ssl.example.conf deploy/nginx/default.conf
docker compose -f docker-compose.prod.yml exec nginx nginx -t
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
```

## 5) Перезапуск и проверка

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans
docker compose -f docker-compose.prod.yml ps
curl -sS https://api.georunapp.ru/health
curl -sS http://127.0.0.1/health
```

Важно: `curl -I` (HEAD) может вернуть `405`, это не обязательно ошибка.  
Проверяйте `/health` обычным GET (`curl -sS ...`).

## 6) Что учитывать на проде

- Не коммитьте серверные файлы и секреты: `.env`, `.env.release`, `secrets/*`.
- Если серверные `deploy/nginx/default.conf` и `docker-compose.prod.yml` должны оставаться локальными, можно скрыть их от обычного pull:

```bash
git update-index --skip-worktree deploy/nginx/default.conf docker-compose.prod.yml
```

Отмена:

```bash
git update-index --no-skip-worktree deploy/nginx/default.conf docker-compose.prod.yml
```

- После `stash pop` удалите временные `.bak` файлы, чтобы не путаться.
- Любые изменения в `docker-compose.prod.yml` сначала проверяйте через:

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
```

## 7) Если после деплоя пропали push-уведомления (FCM)

Частый кейс: после pull/deploy backend запущен, но внутри контейнера нет ключа
`/secrets/firebase-adminsdk.json`.

### 7.1 Быстрая диагностика

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec backend \
  ls -la /secrets/firebase-adminsdk.json

grep -E '^FCM_ENABLED=|^FCM_SERVICE_ACCOUNT_JSON_PATH=' .env

docker compose -f docker-compose.prod.yml exec db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select count(*) as push_tokens from user_push_tokens;"'
```

Ожидается:
- файл `/secrets/firebase-adminsdk.json` существует,
- `FCM_ENABLED=true`,
- `FCM_SERVICE_ACCOUNT_JSON_PATH=/secrets/firebase-adminsdk.json`,
- в `user_push_tokens` есть записи.

### 7.2 Фикс, если ключа нет

```bash
cd /opt/run_application
mkdir -p secrets
chmod 700 secrets
# скопировать JSON с локальной машины в /opt/run_application/secrets/firebase-adminsdk.json
chmod 600 /opt/run_application/secrets/firebase-adminsdk.json
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans
```

### 7.3 Проверка фактической отправки

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml logs -f backend | \
  grep -E "Push targets loaded|Sending territory attacked push|Deleted invalid push tokens|Failed to initialize Firebase|FCM credentials file not found"
```

При успешной отправке должны появляться:
- `Push targets loaded for run ...`
- `Sending territory attacked push ...`

## 8) Полный ресинк с `origin/dev` и пересборка backend

Используйте, когда нужно "начать с чистого состояния" на VPS и заново собрать backend.

```bash
cd /opt/run_application

# 0) Бэкап серверных файлов (для быстрого отката)
TS=$(date +%F-%H%M%S)
cp -a deploy/nginx/default.conf "/tmp/default.conf.$TS.bak" || true
cp -a docker-compose.prod.yml "/tmp/docker-compose.prod.yml.$TS.bak" || true

# 1) Полная синхронизация с dev
git fetch origin
git checkout dev
git reset --hard origin/dev

# 2) Вернуть прод-настройку SSL тома, если нужно
sed -i 's#certbot-conf:/etc/letsencrypt:ro#/etc/letsencrypt:/etc/letsencrypt:ro#' docker-compose.prod.yml

# 3) Поставить проверенный nginx SSL-конфиг
cp deploy/nginx/default-ssl.example.conf deploy/nginx/default.conf

# 4) Проверить FCM-переменные и наличие ключа
grep -E '^FCM_ENABLED=|^FCM_SERVICE_ACCOUNT_JSON_PATH=' .env
ls -la /opt/run_application/secrets/firebase-adminsdk.json

# 5) Проверить compose, пересобрать backend и поднять стек
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml build --no-cache backend
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans

# 6) Проверки
docker compose -f docker-compose.prod.yml ps
curl -sS http://127.0.0.1/health
curl -sS https://api.georunapp.ru/health
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml logs --tail=120 backend
```
