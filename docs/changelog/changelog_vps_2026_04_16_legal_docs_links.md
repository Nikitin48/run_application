# Changelog VPS (2026-04-16): юридические PDF-ссылки и восстановление HTTPS

Этот changelog фиксирует изменения по публикации документов "Политика конфиденциальности" и "Условия пользования" на VPS, а также устранение проблемы с недоступным `https://api.georunapp.ru`.

## Изменено в репозитории

- Обновлен nginx-конфиг для публичной выдачи PDF:
  - `deploy/nginx/default.conf`
  - `deploy/nginx/default-ssl.example.conf`
- Добавлен блок `location ^~ /legal/`:
  - alias: `/srv/legal/`
  - тип: `application/pdf`
  - заголовок: `Content-Disposition: attachment`
  - fallback: `try_files $uri =404`
- В `docker-compose.prod.yml` добавлено монтирование:
  - `./deploy/legal:/srv/legal:ro`
- Добавлен каталог для юридических документов:
  - `deploy/legal/README.md`
- Добавлена инструкция деплоя:
  - `docs/vps/vps_deploy_legal_docs_links.md`

## Выполнено на VPS

- Загружен файл политики:
  - `/opt/run_application/deploy/legal/privacy-policy.pdf`
- Загружен файл условий:
  - `/opt/run_application/deploy/legal/terms-of-use.pdf`
- Подтверждена выдача файлов из контейнера nginx:
  - `/srv/legal/privacy-policy.pdf`
  - `/srv/legal/terms-of-use.pdf`

## Инцидент и исправление

- После промежуточного шага `https://api.georunapp.ru` перестал отвечать.
- Диагностика показала:
  - активный `default.conf` был без SSL-блока,
  - в `docker-compose.prod.yml` использовался пустой docker-volume `certbot-conf:/etc/letsencrypt:ro`,
  - сертификаты с хоста не попадали в nginx-контейнер.
- Исправлено на VPS:
  - применен SSL-конфиг `deploy/nginx/default-ssl.example.conf` как активный `deploy/nginx/default.conf`,
  - монтирование сертификатов переключено на хостовое:
    - `/etc/letsencrypt:/etc/letsencrypt:ro`
  - выполнен `nginx` recreate и `nginx -t`.

## Проверки

- `curl -I https://api.georunapp.ru/legal/privacy-policy.pdf`:
  - `HTTP/2 200`
  - `content-type: application/pdf`
  - `content-disposition: attachment`
- `curl -I https://api.georunapp.ru/legal/terms-of-use.pdf`:
  - `HTTP/2 200`
  - `content-type: application/pdf`
  - `content-disposition: attachment`
- `curl -I https://api.georunapp.ru/health`:
  - `HTTP/2 405` (ожидаемо для `HEAD`, endpoint допускает `GET`)

## Публичные ссылки для приложения

- `https://api.georunapp.ru/legal/privacy-policy.pdf`
- `https://api.georunapp.ru/legal/terms-of-use.pdf`

## Примечание

- Команда `https://api.georunapp.ru/health` в shell не является валидной командой.
- Для проверки использовать:
  - `curl -sS https://api.georunapp.ru/health`
