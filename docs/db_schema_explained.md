# DB schema explained

Источник: `db/schema.sql`. Расширения: `postgis` (геометрия), `pgcrypto` (UUID через `gen_random_uuid()`).

## users
- `id uuid pk` — идентификатор пользователя.
- `username text unique` — логин/хэндл; уникален.
- `display_name text` — отображаемое имя.
- `avatar_url text` — опциональная ссылка на аватар.
- `territory_color text default '#3B82F6'` — цвет территории пользователя в HEX (`#RRGGBB`).
- `is_banned boolean default false` — флаг блокировки.
- `created_at timestamptz default now()` — когда создан.
- `updated_at timestamptz default now()` — когда изменён.

## auth_identities
Привязки провайдеров (email/phone) к пользователю.
- `id uuid pk`
- `user_id uuid fk users on delete cascade` — владелец.
- `provider text check (email|phone)` — тип провайдера.
- `identifier text` — значение (email или телефон).
- `password_hash text` — хэш пароля (алгоритм выбирает бэкенд).
- `verified_at timestamptz` — когда подтверждён (если применимо).
- `created_at/updated_at timestamptz default now()`
- `unique (provider, identifier)` — запрещает дубли по значению.
- `unique (user_id, provider)` — по одному провайдеру на пользователя.

## refresh_tokens
Ротация refresh-токенов, хранится только хэш.
- `id uuid pk`
- `user_id uuid fk users on delete cascade`
- `token_hash text unique` — хэш токена.
- `created_at timestamptz default now()`
- `expires_at timestamptz` — срок действия.
- `revoked_at timestamptz` — если отозван.
- `replaced_by_token_hash text` — хэш нового токена при ротации.
- `user_agent text`, `ip inet` — метаданные сессии.
Индексы: по `user_id`, `expires_at`, `revoked_at`.

## runs
Записи пробежек/активностей.
- `id uuid pk`
- `user_id uuid fk users on delete cascade`
- `status text default 'finished' check ('draft'|'finished'|'processed'|'failed')` — состояние обработки.
- `started_at/ended_at timestamptz` — время начала/конца.
- `distance_m double precision` — пройденная дистанция.
- `elapsed_s integer` — общее время, включая паузы.
- `paused_s integer default 0 not null` — суммарно на паузе.
- `moving_s integer` — время движения (elapsed - paused).
- `avg_pace_s_per_km integer` — темп, если нужен.
- `points jsonb` — сырой трек точек (опционально).
- `track_line geometry(LineString, 4326) not null` — нормализованный маршрут.
- `processing_error text` — описание ошибки обработки.
- `created_at/updated_at timestamptz default now()`
Индексы: `user_id`, `status`.

## run_points
Нормализованные GPS-точки пробежки (по порядку).
- `run_id uuid fk runs on delete cascade`
- `seq integer` — порядковый номер точки в треке.
- `ts timestamptz` — время точки.
- `lat double precision`, `lng double precision` — координаты WGS84.
- `altitude_m double precision` — высота, опц.
- `accuracy_m double precision` — точность, опц.
- `speed_mps double precision` — скорость, опц.
PK `(run_id, seq)`. Индекс `(run_id, ts)`.

## run_pauses
Интервалы пауз во время пробежки.

**Поля:**
- `id uuid pk` — уникальный идентификатор паузы.
- `run_id uuid fk runs on delete cascade` — к какой пробежке относится.
- `started_at timestamptz` — когда пауза началась (обязательно).
- `ended_at timestamptz` — когда пауза закончилась (может быть NULL для открытых пауз).
- `reason text check ('manual'|'gps_lost'|'internet_lost')` — причина паузы:
  - `manual` — пользователь поставил на паузу вручную.
  - `gps_lost` — автоматическая пауза при потере GPS-сигнала (точность > 35 м).
  - `internet_lost` — автоматическая пауза при потере интернет-соединения.
- `created_at timestamptz default now()` — когда запись создана.

**Индекс:** `(run_id, started_at)` — для быстрого поиска пауз по пробежке.

**Как учитываются паузы:**

1. **На клиенте (Flutter):**
   - Паузы создаются автоматически при потере GPS (точность > 35 м) или интернета.
   - Пользователь может поставить паузу вручную.
   - Во время паузы GPS-точки не записываются (клиент не отправляет точки в период паузы).

2. **При загрузке пробежки (`POST /runs/finish`):**
   - Если пауза открыта (нет `ended_at`), она автоматически закрывается на момент `ended_at` пробежки.
   - Для каждой паузы вычисляется пересечение её интервала с интервалом пробежки (`clip_interval`).
   - Суммируется общее время всех пауз → `paused_s`.
   - Вычисляется время движения: `moving_s = elapsed_s - paused_s`.

3. **В базе данных:**
   - Каждая пауза сохраняется отдельной записью в `run_pauses`.
   - Итоговые значения `paused_s` и `moving_s` сохраняются в таблицу `runs`.
   - Эти значения используются для статистики в `user_stats` (суммируются `total_paused_s` и `total_moving_s`).

**Пример:**
Пробежка с 10:00 до 10:30 (1800 сек), пауза с 10:10 до 10:15 (300 сек):
- `elapsed_s = 1800`
- `paused_s = 300`
- `moving_s = 1500`

## territories
Текущая территория пользователя (одна строка на пользователя).
- `user_id uuid pk fk users on delete cascade`
- `geom geometry(MultiPolygon, 4326) not null` — захваченная область.
- `updated_at timestamptz default now()`
GIST-индекс по `geom` для геопоиска/пересечений.

## user_stats
Агрегированные показатели пользователя.
- `user_id uuid pk fk users on delete cascade`
- `run_count integer default 0`
- `total_distance_m double precision default 0`
- `total_elapsed_s bigint default 0`
- `total_paused_s bigint default 0`
- `total_moving_s bigint default 0`
- `owned_area_m2 double precision default 0` — текущая площадь территории.
- `updated_at timestamptz default now()`

## user_last_notification
Хранит только последнее уведомление жертвы о краже территории.
- `user_id uuid pk fk users on delete cascade`
- `kind text default 'territory_stolen'` — тип уведомления.
- `attacker_user_id uuid fk users on delete set null` — кто отжал.
- `run_id uuid fk runs on delete set null` — пробежка-атакер.
- `stolen_area_m2 double precision default 0` — сколько украли.
- `payload jsonb default '{}'` — произвольные данные для UI.
- `created_at timestamptz default now()`

