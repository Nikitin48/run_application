# Восстановление БД в DBeaver (пошагово)

БД проекта: **PostgreSQL + PostGIS**. Все скрипты лежат в папке `db/`.

---

## Шаг 1. Подключение к серверу PostgreSQL

1. Откройте **DBeaver**.
2. **База данных → Новое подключение → PostgreSQL** (или кнопка «Новое подключение»).
3. Укажите параметры (как в вашем `.env`):
   - **Host:** `127.0.0.1`
   - **Port:** `5432`
   - **Database:** `postgres` (или оставьте пустым для подключения к серверу)
   - **Username:** `clausss`
   - **Password:** ваш пароль пользователя PostgreSQL
4. Нажмите **Test Connection**. Если попросит — скачайте драйвер.
5. **Finish** — подключение появится в дереве слева.

---

## Шаг 2. Создать базу данных (если нужна отдельная БД)

Если хотите отдельную БД для приложения (например `run_app`):

1. Правый клик по подключению → **Создать → База данных**.
2. Имя: `run_app` (или любое).
3. **OK**.

Затем создайте **второе подключение** в DBeaver к этой БД `run_app` (те же host/port/user, но Database = `run_app`). Дальше все шаги делайте в контексте этой БД.

Если используете базу `postgres` — просто откройте её в дереве и переходите к шагу 3.

---

## Шаг 3. Включить расширения PostGIS и pgcrypto

1. В дереве выберите вашу базу (`postgres` или `run_app`).
2. Откройте **SQL Editor** (иконка SQL или правый клик по БД → **SQL Editor → New SQL Script**).
3. Вставьте и выполните (Ctrl+Enter или кнопка Execute):

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

Убедитесь, что выполнилось без ошибок. Без PostGIS схема и функции не заработают.

---

## Шаг 4. Выполнить schema.sql (таблицы)

1. В том же или новом SQL-скрипте откройте файл **`db/schema.sql`** из вашего проекта  
   (Файл → Открыть файл → `.../run_application/db/schema.sql`).
2. Убедитесь, что внизу выбран правильный **подключение и база** (та, куда восстанавливаете).
3. Выполните весь скрипт (Ctrl+Enter или Execute).

Будут созданы таблицы: `users`, `auth_identities`, `refresh_tokens`, `runs`, `run_points`, `run_pauses`, `territories`, `user_stats`, `user_last_notification`.

---

## Шаг 5. Выполнить functions.sql (функции PostGIS)

1. Откройте файл **`db/functions.sql`** (Файл → Открыть файл).
2. Выберите то же подключение и базу.
3. Выполните весь скрипт (Ctrl+Enter).

Будут созданы функции:
- `compute_capture_polygons` — полигоны захвата из трека.
- `finalize_run_capture` — перекраска территорий, уведомления, обновление статистики.

---

## Шаг 6. Проверка

В DBeaver в дереве слева:

- **База → Schemas → public → Tables** — должны быть все таблицы.
- **База → Schemas → public → Functions** — должны быть `compute_capture_polygons` и `finalize_run_capture`.

Проверка из SQL:

```sql
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
-- Должно быть 9 таблиц

SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
-- Должны быть compute_capture_polygons и finalize_run_capture
```

---

## Если бэкенд подключается к другой базе

В `python_backend/.env` указано:

```env
DATABASE_URL=postgresql://clausss@127.0.0.1:5432/postgres
```

То есть приложение подключается к базе **`postgres`** на порту 5432. Если вы создали базу `run_app`, измените строку на:

```env
DATABASE_URL=postgresql://clausss@127.0.0.1:5432/run_app
```

(и при необходимости добавьте пароль: `postgresql://clausss:ВАШ_ПАРОЛЬ@127.0.0.1:5432/run_app`).

---

## Краткий чеклист

| Шаг | Действие |
|-----|----------|
| 1 | Подключиться к PostgreSQL в DBeaver |
| 2 | (Опционально) Создать БД `run_app` |
| 3 | Выполнить `CREATE EXTENSION postgis;` и `pgcrypto` |
| 4 | Выполнить `db/schema.sql` |
| 5 | Выполнить `db/functions.sql` |
| 6 | Проверить таблицы и функции, при необходимости поправить `DATABASE_URL` в `.env` |

После этого БД восстановлена и готова к работе с приложением.
