# VPS деплой: достижения, уровни профиля и экран коллекции

Пошаговый runbook для выката изменений, где:

- в БД добавляется каталог достижений и новые агрегаты в `user_stats`,
- backend начинает выдавать достижения и уровни профиля,
- `POST /runs/finish` возвращает новые достижения и `level_up`,
- `GET /me/profile` и `GET /me/achievements` расширяются новыми данными.

Важно:

- **на VPS выкатываются только backend + БД**,
- Flutter-изменения с новыми вкладками, popup и экраном коллекции **не деплоятся на VPS напрямую**,
- но после выката нужно проверить мобильный клиент против прод-API.

## Что входит в релиз

### БД

- Миграция:
  - `db/migrations/20260411_achievements_mvp.sql`
- Обновления схемы:
  - `db/schema.sql`
  - `db/functions.sql`

### Backend

- `python_backend/app/models.py`
- `python_backend/app/routers/me.py`
- `python_backend/app/routers/runs.py`
- `python_backend/app/services/achievements_service.py`

### Flutter client (не часть VPS-деплоя, но часть релиза)

- `flutter_fronted/lib/src/app/router.dart`
- `flutter_fronted/lib/src/app/home_shell_page.dart`
- `flutter_fronted/lib/src/features/profile/*`
- `flutter_fronted/lib/src/features/runs/*`
- `flutter_fronted/lib/src/core/ui/achievement_badge_card.dart`
- `flutter_fronted/lib/l10n/*`

## 0) Подготовка (локально)

1. Убедиться, что изменения закоммичены и запушены в нужную ветку (`dev`).
2. Проверить, что в коммит **не попали**:
   - `.env`, `secrets/*`
   - `__pycache__/*`, `.pyc`
3. Локально проверить:
   - backend стартует без ошибок,
   - `GET /me/profile` работает,
   - `GET /me/achievements` возвращает каталог достижений,
   - после завершения пробежки `POST /runs/finish` возвращает `new_achievements` и `profile_level`,
   - экран достижений и новые вкладки открываются во Flutter.

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

Если `git pull` конфликтует, использовать:

- `docs/guide/vps_pull_conflict_quick_guide.md`

## 4) Применение миграции достижений

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < db/migrations/20260411_achievements_mvp.sql
```

Ожидаемый результат:

- успешный `COMMIT`
- создаются:
  - `achievement_definitions`
  - `user_achievements`
- в `user_stats` добавляются новые поля
- функция `finalize_run_capture(...)` обновляется

## 5) Быстрая проверка БД после миграции

### 5.1 Проверить, что каталог достижений засеян

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT COUNT(*) AS achievements_count
    FROM achievement_definitions;
  "'
```

Ожидается:

- `35` записей в `achievement_definitions`

### 5.2 Проверить новые колонки в `user_stats`

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT
      column_name
    FROM information_schema.columns
    WHERE table_name = '\''user_stats'\''
      AND column_name IN (
        '\''successful_captures_count'\'',
        '\''total_captured_area_m2'\'',
        '\''total_victims_count'\'',
        '\''profile_xp'\'',
        '\''profile_level'\''
      )
    ORDER BY column_name;
  "'
```

## 6) Пересборка и перезапуск backend

Важно: после изменения SQL-функций и Pydantic-моделей не полагаться на старый образ. Явно пересобрать backend.

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml config -q
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml build backend
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
docker compose -f docker-compose.prod.yml ps
```

## 7) Smoke-check API после выката

### 7.1 Базовый health

```bash
curl -sS https://api.georunapp.ru/health
```

### 7.2 Проверка профиля и достижений (нужен access token)

```bash
curl -sS -H "Authorization: Bearer <TOKEN>" \
  "https://api.georunapp.ru/me/profile"

curl -sS -H "Authorization: Bearer <TOKEN>" \
  "https://api.georunapp.ru/me/achievements"
```

Проверить:

- `me/profile` содержит:
  - `successful_captures_count`
  - `total_captured_area_m2`
  - `total_victims_count`
  - `profile_xp`
  - `profile_level`
- `me/achievements` содержит:
  - `profile_xp`
  - `profile_level`
  - `items`
  - для каждого item есть `is_unlocked`

### 7.3 Проверка завершения пробежки

Лучший smoke-сценарий:

1. Выполнить реальную короткую пробежку/тестовый маршрут из клиента.
2. После `finish` убедиться, что ответ содержит:
   - `new_achievements`
   - `profile_xp`
   - `profile_level`
   - `level_up` (если произошёл)

Если хотите проверить через backend-логи:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml logs --tail=150 backend
```

Проверить, что нет traceback и ошибок SQL после `POST /runs/finish`.

## 8) Проверки БД после реального забега

Проверить последние достижения и статистику пользователя:

```bash
cd /opt/run_application
docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT user_id, profile_xp, profile_level, run_count, successful_captures_count
    FROM user_stats
    ORDER BY updated_at DESC
    LIMIT 10;
  "'

docker compose -f docker-compose.prod.yml exec -T db sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT user_id, achievement_id, unlocked_at
    FROM user_achievements
    ORDER BY unlocked_at DESC
    LIMIT 20;
  "'
```

## 9) Проверка в клиенте после выката backend

Это уже не шаг VPS, а acceptance-check для релиза:

1. Открыть приложение, подключённое к `https://api.georunapp.ru`.
2. Проверить нижний бар:
   - вкладка достижений есть,
   - вкладка рейтинга есть.
3. Проверить экран `Все достижения`:
   - отображаются **все** достижения,
   - неоткрытые карточки тусклые и серые,
   - открытые карточки имеют цвет по редкости,
   - список идёт вертикальной лентой на всю ширину.
4. Проверить профиль:
   - плашки достижений в профиле больше нет.
5. Выполнить тестовый забег:
   - popup достижений появляется,
   - если уровень вырос, показывается `level up`.

## 10) Rollback

1. Откатить backend на предыдущий стабильный commit/образ.
2. Перезапустить backend:

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.fcm.yml up -d --remove-orphans backend
```

3. Если проблема в данных/схеме критическая:
   - восстановить дамп из `/tmp/run_application.<timestamp>.sql`
4. Предпочтительно делать `forward-fix`, если это безопаснее для новых данных.

## 11) Короткий чеклист "готово"

- Код на VPS обновлён без конфликтов.
- Миграция `20260411_achievements_mvp.sql` применена.
- В `achievement_definitions` есть `35` записей.
- Backend пересобран и перезапущен.
- `/health` отвечает корректно.
- `/me/profile` отдаёт новые поля профиля.
- `/me/achievements` отдаёт весь каталог достижений.
- После тестового `finish_run` backend не падает.
- Клиент показывает новые вкладки `Achievements` и `Leaderboard`.
- Экран достижений показывает открытые и неоткрытые ачивки корректно.
