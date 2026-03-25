# Инструкция: развертывание backend + PostgreSQL с нуля (VPS, Ubuntu 24.04)

Этот гайд собран под текущий проект (`python_backend` + PostGIS/PostgreSQL + Nginx + Docker Compose).

## 0) Что нужно заранее

- VPS с Ubuntu 24.04 и публичным IPv4.
- Доступ по SSH (root или пользователь с `sudo`).
- Репозиторий проекта на GitHub.
- (Для HTTPS) домен и доступ к DNS-зоне.

## 1) Первый вход и базовая подготовка сервера

```bash
ssh root@<VPS_IP>
apt update && apt upgrade -y
apt install -y ca-certificates curl git ufw fail2ban
```

Создаём рабочего пользователя:

```bash
adduser claus
usermod -aG sudo claus
su - claus
```

## 2) SSH ключи и безопасный вход

На локальной машине:

```bash
ssh-keygen -t ed25519 -C "vps-deploy" -f ~/.ssh/vps_run_app -N ""
ssh-copy-id -i ~/.ssh/vps_run_app.pub claus@<VPS_IP>
```

Проверка:

```bash
ssh -i ~/.ssh/vps_run_app claus@<VPS_IP>
```

Отключить парольный вход (после проверки входа по ключу):

```bash
sudo nano /etc/ssh/sshd_config.d/99-hardening.conf
```

Содержимое:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Применить:

```bash
sudo sshd -t && sudo systemctl restart ssh
sudo systemctl enable ssh
```

## 3) Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Важно: порт `5432` наружу не открывать.

## 4) Docker + Compose

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker claus
```

Перелогиниться по SSH и проверить:

```bash
docker run --rm hello-world
docker compose version
```

## 5) Клонирование проекта на VPS

```bash
sudo mkdir -p /opt/run_application
sudo chown claus:claus /opt/run_application
cd /opt/run_application
```

Вариант через deploy key (рекомендуется для VPS):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github_run_app -N ""
cat ~/.ssh/github_run_app.pub
```

Публичный ключ добавить в GitHub репозиторий как **Deploy key (read)**, затем:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' \
  git clone git@github.com:Nikitin48/run_application.git .
```

## 6) Переменные окружения

```bash
cd /opt/run_application
cp env.production.example .env
touch .env.release
nano .env
```

Проверьте ключевые значения:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `JWT_SECRET`
- `DATABASE_URL=postgresql://<user>:<pass>@db:5432/<db>`
- `APP_ENV=release`

## 7) Первый запуск и инициализация БД

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml up -d
chmod +x deploy/init-db.sh
./deploy/init-db.sh
docker compose -f docker-compose.prod.yml restart backend
```

Проверки:

```bash
docker compose -f docker-compose.prod.yml ps
curl -sS http://127.0.0.1/health
curl -sS http://<VPS_IP>/health
```

## 8) DNS (домен и поддомен API)

Для прод-API используйте `api.<домен>`, например `api.georunapp.ru`.

В DNS-зоне добавить:

- `A` запись: `api` -> `<VPS_IP>`

Проверки:

```bash
dig api.<домен> A @ns1.beget.com +noall +answer
dig +short api.<домен> @8.8.8.8
curl -sS http://api.<домен>/health
```

Если авторитативные NS отвечают, а `8.8.8.8` даёт `NXDOMAIN` — проблема делегирования у регистратора/реестра, не в сервере.

## 9) HTTPS (Let's Encrypt)

Подробный файл: `deploy/HTTPS_LETSENCRYPT.md`.

Кратко:

1. Установить certbot:
   ```bash
   sudo apt install -y certbot
   ```
2. Найти mountpoint тома `certbot-www`.
3. Выпустить сертификат для `api.<домен>`.
4. В `docker-compose.prod.yml` у nginx заменить том сертификатов на bind:
   - было: `certbot-conf:/etc/letsencrypt:ro`
   - стало: `/etc/letsencrypt:/etc/letsencrypt:ro`
5. Переключить nginx-конфиг на SSL (пример: `deploy/nginx/default-ssl.example.conf`).
6. Проверить:
   ```bash
   curl -sS https://api.<домен>/health
   ```

## 10) CI/CD через GitHub Actions

В репозитории уже подготовлены:

- `.github/workflows/backend-docker.yml` — build/push образа в GHCR.
- `.github/workflows/deploy-vps.yml` — ручной deploy по SSH.

Секреты GitHub:

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `DEPLOY_PATH` (например `/opt/run_application`)

Если GHCR пакет приватный — на VPS выполнить `docker login ghcr.io`.

## 11) Обновление проекта после первого запуска

```bash
cd /opt/run_application
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
docker compose -f docker-compose.prod.yml up -d --build
curl -sS http://127.0.0.1/health
```

## 12) Быстрая диагностика

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs --tail=200 backend
docker compose -f docker-compose.prod.yml logs --tail=200 nginx
docker compose -f docker-compose.prod.yml logs --tail=200 db
sudo systemctl status ssh --no-pager
sudo ufw status verbose
```

## Мини-чеклист готовности

- [ ] `curl http://<VPS_IP>/health` возвращает `ok=true`
- [ ] `api.<домен>` резолвится в IP VPS
- [ ] `curl https://api.<домен>/health` работает
- [ ] SSH только по ключам
- [ ] Порт 5432 не открыт в интернет
- [ ] GitHub Actions может деплоить на VPS

