# VPS деплой: политика конфиденциальности и условия пользования (PDF ссылки)

Пошаговый runbook для настройки публичных ссылок на юридические документы, чтобы:

- из мобильного приложения ссылки открывались во внешнем браузере,
- по переходу происходило скачивание PDF,
- документы были доступны напрямую по URL.

Целевой домен API:

- `https://api.georunapp.ru`

Целевые URL документов:

- `https://api.georunapp.ru/legal/privacy-policy.pdf`
- `https://api.georunapp.ru/legal/terms-of-use.pdf`

## Что входит в задачу

### Nginx

- добавить location `^~ /legal/` в конфиг nginx:
  - `deploy/nginx/default.conf`
  - (опционально, как шаблон TLS) `deploy/nginx/default-ssl.example.conf`
- включить заголовок `Content-Disposition: attachment` для принудительного скачивания.

### Docker Compose

- смонтировать каталог с PDF в nginx-контейнер:
  - `./deploy/legal:/srv/legal:ro`

### Контент (PDF)

- загрузить на VPS 2 файла:
  - `deploy/legal/privacy-policy.pdf`
  - `deploy/legal/terms-of-use.pdf`

## 0) Подготовка (локально)

1. Убедиться, что в репозитории есть:
   - `deploy/nginx/default.conf` с блоком `location ^~ /legal/`
   - `docker-compose.prod.yml` с томом `./deploy/legal:/srv/legal:ro`
2. Убедиться, что подготовлены финальные PDF:
   - `privacy-policy.pdf`
   - `terms-of-use.pdf`
3. В тексте документов заменить `https://thismywebsite.com` на актуальные адреса:
   - сайт: `https://georunapp.ru`
   - прямая ссылка на политику: `https://api.georunapp.ru/legal/privacy-policy.pdf`

## 1) Подключение к VPS

```bash
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208
cd /opt/run_application
```

## 2) Backup текущего nginx-конфига (рекомендуется)

```bash
cd /opt/run_application
TS=$(date +%F-%H%M%S)
cp deploy/nginx/default.conf "/tmp/default.conf.$TS.bak"
ls -lh "/tmp/default.conf.$TS.bak"
```

## 3) Обновление кода на VPS

Если есть локальные правки на сервере:

```bash
cd /opt/run_application
git stash push -m "vps-local-config" -- deploy/nginx/default.conf docker-compose.prod.yml
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
git stash pop
```

Если правок нет:

```bash
cd /opt/run_application
GIT_SSH_COMMAND='ssh -i ~/.ssh/github_run_app -o IdentitiesOnly=yes' git pull
```

Если `git pull` конфликтует, использовать:

- `docs/vps/vps_pull_conflict_quick_guide.md`

## 4) Загрузка PDF на VPS

На VPS:

```bash
cd /opt/run_application
mkdir -p deploy/legal
```

Вариант A (предпочтительно): файлы уже в git, просто проверить:

```bash
cd /opt/run_application
ls -lh deploy/legal/privacy-policy.pdf deploy/legal/terms-of-use.pdf
```

Вариант B: скопировать файлы вручную с локальной машины:

```bash
scp -i ~/.ssh/vps_run_app ./deploy/legal/privacy-policy.pdf claus@185.225.34.208:/opt/run_application/deploy/legal/privacy-policy.pdf
scp -i ~/.ssh/vps_run_app ./deploy/legal/terms-of-use.pdf claus@185.225.34.208:/opt/run_application/deploy/legal/terms-of-use.pdf
```

После загрузки:

```bash
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208
cd /opt/run_application
ls -lh deploy/legal
```

## 5) Перезапуск nginx с новым монтированием

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec nginx nginx -t
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
docker compose -f docker-compose.prod.yml ps
```

Проверить, что сервис `nginx` в статусе `Up`.

## 6) Smoke-check публичных ссылок

### 6.1 Проверка заголовков и статуса

```bash
curl -I https://api.georunapp.ru/legal/privacy-policy.pdf
curl -I https://api.georunapp.ru/legal/terms-of-use.pdf
```

Ожидается:

- `HTTP/2 200`
- `content-type: application/pdf`
- `content-disposition: attachment`

### 6.2 Проверка скачивания файла

```bash
curl -L -o /tmp/privacy-policy.pdf https://api.georunapp.ru/legal/privacy-policy.pdf
curl -L -o /tmp/terms-of-use.pdf https://api.georunapp.ru/legal/terms-of-use.pdf
ls -lh /tmp/privacy-policy.pdf /tmp/terms-of-use.pdf
```

Ожидается:

- файлы скачались,
- размер больше `0`,
- PDF открывается локально без ошибок.

### 6.3 Проверка 404 на несуществующий файл

```bash
curl -I https://api.georunapp.ru/legal/not-found.pdf
```

Ожидается:

- `HTTP/2 404`

## 7) Проверка в мобильном приложении

1. В приложении открыть экран авторизации.
2. Нажать ссылку "Политика конфиденциальности":
   - должен открыться внешний браузер,
   - должна начаться загрузка `privacy-policy.pdf`.
3. Нажать ссылку "Условия пользования":
   - должен открыться внешний браузер,
   - должна начаться загрузка `terms-of-use.pdf`.

Если браузер открывается, но скачивания нет:

- проверить заголовок `content-disposition` через `curl -I`,
- проверить расширение `.pdf` и корректный `content-type`.

## 8) Rollback

Если после изменений nginx не стартует или ссылки не работают:

1. Вернуть резервную копию конфига:

```bash
cd /opt/run_application
cp /tmp/default.conf.<TIMESTAMP>.bak deploy/nginx/default.conf
```

2. Убрать проблемный том из `docker-compose.prod.yml` (если нужно).
3. Перезапустить nginx:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml up -d --force-recreate nginx
```

## 9) Короткий чеклист "готово"

- Папка `deploy/legal` существует на VPS.
- Загружены `privacy-policy.pdf` и `terms-of-use.pdf`.
- В `docker-compose.prod.yml` есть `./deploy/legal:/srv/legal:ro`.
- В `deploy/nginx/default.conf` есть `location ^~ /legal/`.
- `nginx -t` проходит без ошибок.
- `https://api.georunapp.ru/legal/privacy-policy.pdf` отвечает `200`.
- `https://api.georunapp.ru/legal/terms-of-use.pdf` отвечает `200`.
- В ответах есть `Content-Disposition: attachment`.
- Из приложения ссылки открываются во внешнем браузере и документы скачиваются.
