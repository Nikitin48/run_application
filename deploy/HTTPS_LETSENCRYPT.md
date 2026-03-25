# HTTPS (Let’s Encrypt) для API на VPS

Замените **`api.example.com`** на ваш реальный поддомен (например `api.mysite.ru`).

## 0. DNS

В панели регистратора / Beget создайте **A**-запись:

- **Имя:** `api` (или полное `api.example.com`, зависит от панели)
- **Значение:** публичный **IPv4** VPS

Подождите 5–30 минут. Проверка с Mac:

```bash
dig +short api.example.com
curl -sS -o /dev/null -w "%{http_code}\n" http://api.example.com/health
```

Должен ответить **200** (пока по HTTP).

## 1. Установить certbot на хост (не в Docker)

На **VPS**:

```bash
sudo apt update
sudo apt install -y certbot
```

## 2. Узнать путь к webroot-тому `certbot-www`

Проект в compose называется `run-application`, том обычно **`run-application_certbot-www`**.

```bash
cd /opt/run_application
docker volume ls | grep certbot
WEBROOT="$(docker volume inspect run-application_certbot-www --format '{{ .Mountpoint }}')"
echo "$WEBROOT"
sudo ls -la "$WEBROOT"
```

Если имя тома другое, подставьте его в `docker volume inspect ...`.

## 3. Выпустить сертификат (webroot, порт 80 занят nginx — это нормально)

Nginx уже отдаёт `/.well-known/acme-challenge/` из `/var/www/certbot` (= этот том).

```bash
sudo certbot certonly --webroot -w "$WEBROOT" \
  -d api.example.com \
  --email YOUR_EMAIL@example.com \
  --agree-tos --no-eff-email
```

Успех: файлы на **хосте** в `/etc/letsencrypt/live/api.example.com/`.

## 4. Подключить хостовые сертификаты к контейнеру nginx

Сейчас в `docker-compose.prod.yml` у nginx смонтирован **пустой** том `certbot-conf`. Замените **на хосте** монтирование на каталог с хоста.

На хосте отредактируйте `/opt/run_application/docker-compose.prod.yml`, у сервиса `nginx` в `volumes` замените строку:

```yaml
- certbot-conf:/etc/letsencrypt:ro
```

на:

```yaml
- /etc/letsencrypt:/etc/letsencrypt:ro
```

(строку с `certbot-www` не трогайте.)

Применить:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
```

## 5. Конфиг nginx с TLS

Скопируйте пример и **замените домен** во всех `server_name` и путях `ssl_certificate` (если домен тот же — достаточно заменить `api.example.com` на ваш):

```bash
cd /opt/run_application
cp deploy/nginx/default-ssl.example.conf deploy/nginx/default.conf
nano deploy/nginx/default.conf
```

Перезапуск nginx:

```bash
docker compose -f docker-compose.prod.yml exec nginx nginx -t
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
```

Проверка с Mac:

```bash
curl -sS https://api.example.com/health
```

## 6. Автообновление сертификата

```bash
sudo certbot renew --dry-run
```

Планировщик на Ubuntu обычно ставит **twice daily** `certbot.service` / timer. После обновления сертификатов перезагрузите nginx:

```bash
echo 'renew-hook = systemctl reload nginx || true' | sudo tee -a /etc/letsencrypt/cli.ini
```

Для **Docker** лучше хук дергает compose:

```bash
sudo sh -c 'echo "0 3 * * * root certbot renew --quiet --deploy-hook \"cd /opt/run_application && docker compose -f docker-compose.prod.yml exec -T nginx nginx -s reload\"" > /etc/cron.d/certbot-reload-nginx'
```

(при необходимости поправьте путь к проекту.)

## 7. Flutter

```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com
```

Без завершающего `/` в URL.
