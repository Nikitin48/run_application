# Миграция БД в Yandex Cloud (Managed PostgreSQL)

Пошаговый гайд: создать БД в кластере, подключиться из DBeaver, скопировать данные с локальной БД и настроить переключение в проекте.

---

## Шаг 1. Создать базу и пользователя в консоли Yandex Cloud

1. Открой **Yandex Cloud Console** → **Managed Service for PostgreSQL** → выбери свой кластер.

2. **Базы данных** → **Создать базу данных**:
   - Имя: `run_app`
   - Владелец: выбери существующего пользователя или создай нового (см. ниже)

3. **Пользователи** → если нужен отдельный пользователь:
   - **Добавить пользователя**
   - Имя: `run_app_user`
   - Пароль: придумай и сохрани
   - Права: выбери БД `run_app` (если есть опция)

4. Запиши данные для подключения:
   - **Хост:** в карточке кластера (например `c-xxx.rw.mdb.yandexcloud.net`)
   - **Порт:** `6432` (стандартный для Managed PostgreSQL)
   - **Публичный доступ:** должен быть включён (для подключения с твоего ПК)

---

## Шаг 2. Подключиться к кластеру из DBeaver

1. **База данных** → **Новое подключение** → **PostgreSQL**.

2. Параметры:
   | Поле | Значение |
   |------|----------|
   | Host | `c-xxx.rw.mdb.yandexcloud.net` (твой хост) |
   | Port | `6432` |
   | Database | `run_app` |
   | Username | `run_app_user` (или владелец БД) |
   | Password | пароль пользователя |

3. **Driver properties** (вкладка внизу):
   - Найди `sslmode` → значение `require`
   - Или в **Connection settings** → **SSL** → включи SSL, режим `require`

4. **Test Connection** → если всё ок, **Finish**.

---

## Шаг 3. Включить PostGIS и pgcrypto

1. В DBeaver открой подключение к облачной БД `run_app`.
2. **SQL Editor** → New SQL Script.
3. Выполни:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

---

## Шаг 4. Применить схему (таблицы)

1. **Файл** → **Открыть файл** → `db/schema.sql`.
2. Убедись, что выбран правильный контекст: подключение к облачной БД `run_app`.
3. Выполни скрипт (Ctrl+Enter или Execute).

---

## Шаг 5. Применить функции PostGIS

1. **Файл** → **Открыть файл** → `db/functions.sql`.
2. Тот же контекст (облачная БД `run_app`).
3. Выполни скрипт.

---

## Шаг 6. Скопировать данные с локальной БД

### Вариант A: pg_dump + psql (рекомендуется)

В терминале (подставь свои данные):

```bash
# 1. Дамп данных с локальной БД (только данные, схема уже есть)
pg_dump -h 127.0.0.1 -U clausss -d run_app \
  --data-only \
  --no-owner \
  --no-privileges \
  --format=plain \
  -f /tmp/run_app_data.sql
```

Если локальная БД называется иначе (например `postgres`), замени `-d run_app` на нужное имя.

```bash
# 2. Применить данные в облачную БД
psql "postgresql://run_app_user:PASSWORD@c-xxx.rw.mdb.yandexcloud.net:6432/run_app?sslmode=require" \
  -f /tmp/run_app_data.sql
```

Замени `PASSWORD` и хост на свои значения.

### Вариант B: Через DBeaver (Export/Import)

1. Подключись к **локальной** БД в DBeaver.
2. Правый клик по БД → **Tools** → **Backup database** (или **Export Data**).
3. Выбери таблицы, формат SQL.
4. Сохрани дамп.
5. Подключись к **облачной** БД.
6. **Tools** → **Restore** или открой сохранённый SQL и выполни.

### Вариант C: Если данных мало — вручную

Если таблиц мало и данных немного, можно экспортировать через DBeaver (правый клик по таблице → Export Data) и импортировать в облачную БД. Порядок важен: сначала `users`, потом `auth_identities`, `refresh_tokens`, `runs`, `run_points`, `run_pauses`, `territories`, `user_stats`, `user_last_notification`.

---

## Шаг 7. Проверка в облачной БД

В DBeaver (облачная БД):

```sql
SELECT 'users' AS tbl, COUNT(*) FROM users
UNION ALL SELECT 'auth_identities', COUNT(*) FROM auth_identities
UNION ALL SELECT 'refresh_tokens', COUNT(*) FROM refresh_tokens
UNION ALL SELECT 'runs', COUNT(*) FROM runs
UNION ALL SELECT 'run_points', COUNT(*) FROM run_points
UNION ALL SELECT 'run_pauses', COUNT(*) FROM run_pauses
UNION ALL SELECT 'territories', COUNT(*) FROM territories
UNION ALL SELECT 'user_stats', COUNT(*) FROM user_stats
UNION ALL SELECT 'user_last_notification', COUNT(*) FROM user_last_notification;
```

Сравни с локальной БД — количество строк должно совпадать.

---

## Шаг 8. Настроить проект для переключения

1. В `python_backend/` создай `.env.release` (если ещё нет):

```bash
cp env.example.release .env.release
```

2. Отредактируй `.env.release`:

```env
DATABASE_URL=postgresql://run_app_user:ТВОЙ_ПАРОЛЬ@c-xxx.rw.mdb.yandexcloud.net:6432/run_app?sslmode=require
```

Подставь хост, логин, пароль из консоли Yandex Cloud.

3. Убедись, что `.env.local` указывает на локальную БД:

```env
DATABASE_URL=postgresql://clausss@127.0.0.1:5432/run_app
```

(или как у тебя в `.env` сейчас)

---

## Шаг 9. Переключение и проверка

**Локальная БД (разработка):**
```bash
cd python_backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Облачная БД (релиз):**
```bash
APP_ENV=release uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Проверка: `GET /health` → `"env": "local"` или `"env": "release"`.

---

## Чеклист

| # | Действие |
|---|----------|
| 1 | Создать БД `run_app` и пользователя в консоли Yandex Cloud |
| 2 | Подключиться к облачной БД из DBeaver (SSL, порт 6432) |
| 3 | Выполнить `CREATE EXTENSION postgis, pgcrypto` |
| 4 | Выполнить `db/schema.sql` |
| 5 | Выполнить `db/functions.sql` |
| 6 | Скопировать данные (pg_dump → psql или DBeaver) |
| 7 | Проверить количество строк в таблицах |
| 8 | Заполнить `.env.release` |
| 9 | Запустить с `APP_ENV=release` и проверить |

---

## Частые проблемы

**Ошибка SSL:** добавь `?sslmode=require` в URL или включи SSL в DBeaver.

**Connection refused:** проверь, что у кластера включён публичный доступ.

**PostGIS не найден:** в Managed PostgreSQL PostGIS доступен по умолчанию, выполни `CREATE EXTENSION postgis;`.

**Ошибка при импорте данных (foreign key):** убедись, что дамп содержит данные в правильном порядке. `pg_dump --data-only` делает это автоматически.
