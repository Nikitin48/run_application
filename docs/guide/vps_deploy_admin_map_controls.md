# VPS деплой: админ-доступ к debug/map controls

Пошаговый runbook для выката изменений, где:

- в БД добавляется флаг `users.is_admin`,
- backend начинает отдавать `is_admin` в `GET /me` и `GET /me/profile`,
- добавляется консольный инструмент назначения админов,
- Flutter скрывает кнопки debug/map style в AppBar карты для не-админов.

Важно:

- **на VPS выкатываются только backend + БД**,
- Flutter-изменения напрямую на VPS не деплоятся,
- но после выката backend нужно проверить клиентом, подключенным к прод-API.

## Что входит в релиз

### БД

- Миграция:
  - `db/migrations/20260413_users_is_admin.sql`
- Обновления схемы:
  - `db/schema.sql`

### Backend

- `python_backend/app/models.py`
- `python_backend/app/routers/me.py`
- `python_backend/scripts/manage_admin.py`

### Flutter client (не часть VPS-деплоя, но часть релиза)

- `flutter_fronted/lib/src/features/profile/domain/me_profile.dart`
- `flutter_fronted/lib/src/features/profile/data/profile_repository.dart`
- `flutter_fronted/lib/src/features/territories/presentation/map_page.dart`

## 0) Подготовка (локально)

1. Убедиться, что изменения закоммичены и запушены в нужную ветку.
2. Проверить, что в коммит не попали:
   - `.env`, `secrets/*`
   - `__pycache__/*`, `.pyc`
3. Локально проверить:
   - backend стартует без ошибок,
   - `GET /me/profile` возвращает `is_admin`,
   - скрипт `manage_admin.py list` выполняется,
   - в клиенте у обычного пользователя нет кнопок `layers` и `gamepad`,
   - у админа кнопки есть.

## 1) Подключение к VPS

```bash
ssh -i ~/.ssh/vps_run_app claus@185.225.34.208
cd /opt/run_application
```

## 2) Backup БД (обязательно)

```bash
cd /opt/run_application
TS=$(date +%F-%H%M%S)
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "/tmp/run_application.$TS.sql"
ls -lh "/tmp/run_application.$TS.sql"
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

## 4) Применение миграции `is_admin`

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260413_users_is_admin.sql
```

Ожидаемый результат:

- успешный `COMMIT`,
- в таблице `users` появляется колонка `is_admin`.

## 5) Быстрая проверка БД после миграции

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_name = '\''users'\''
      AND column_name = '\''is_admin'\'';
  "'
```

Ожидается:

- `data_type = boolean`
- `is_nullable = NO`
- `column_default` содержит `false`

## 6) Пересборка и перезапуск backend

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml build backend
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
docker compose -f docker-compose.prod.yml ps
```

## 7) Назначение админа на VPS

Предпочтительный способ: запустить скрипт внутри backend-контейнера.

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec -T backend \
  python scripts/manage_admin.py grant --email <admin@email>
```

Проверка списка админов:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec -T backend \
  python scripts/manage_admin.py list
```

Снять роль:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec -T backend \
  python scripts/manage_admin.py revoke --email <admin@email>
```

## 8) Smoke-check API после выката

### 8.1 Базовый health

```bash
curl -sS https://api.georunapp.ru/health
```

### 8.2 Проверка `is_admin` в профиле (нужен access token)

```bash
curl -sS -H "Authorization: Bearer <TOKEN>" \
  "https://api.georunapp.ru/me/profile"
```

Проверить:

- в ответе есть поле `is_admin`,
- для назначенного админа значение `true`,
- для обычного пользователя значение `false`.

## 9) Проверка в клиенте после выката backend

Acceptance-check в мобильном приложении (клиент смотрит на прод-API):

1. Войти под обычным пользователем:
   - в AppBar карты **нет** кнопок выбора стиля карты (`layers`) и debug-джойстика (`gamepad`).
2. Войти под админом:
   - в AppBar карты есть `layers` и `gamepad`,
   - включение `gamepad` показывает debug-пад на карте.

## 10) Rollback

1. Откатить backend на предыдущий стабильный commit/образ.
2. Перезапустить backend:

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
```

3. Если нужно срочно убрать админ-права у пользователей:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml exec -T backend \
  python scripts/manage_admin.py revoke --email <admin@email>
```

4. Откат схемы `is_admin` обычно не требуется; безопаснее делать `forward-fix`.

## 11) Короткий чеклист "готово"

- Код на VPS обновлен без конфликтов.
- Миграция `20260413_users_is_admin.sql` применена.
- Колонка `users.is_admin` существует и имеет `DEFAULT false`.
- Backend пересобран и перезапущен.
- `/health` отвечает корректно.
- `/me/profile` возвращает `is_admin`.
- Через `manage_admin.py` можно выдать/снять админку.
- В клиенте обычный пользователь не видит `layers` и `gamepad`.
- В клиенте админ видит и использует эти controls.
