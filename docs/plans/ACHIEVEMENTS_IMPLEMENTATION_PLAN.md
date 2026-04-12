# Технический план внедрения: достижения и уровни профиля

Документ описывает конкретный порядок внедрения MVP-системы достижений в текущую кодовую базу `Run Application`.

Связанный продуктовый документ:

- `docs/plans/ACHIEVEMENTS_MVP_PLAN.md`

## 1. Цель документа

Этот документ отвечает на вопросы:

- какие файлы менять
- какие таблицы и поля добавить
- где именно считать достижения
- как расширить API
- как встроить popup и профиль во Flutter

## 2. Текущее состояние проекта

## 2.1 Backend

Текущие точки интеграции:

- `python_backend/app/routers/runs.py`
  - завершение пробежки через `POST /runs/finish`
- `python_backend/app/models.py`
  - Pydantic-модели запросов и ответов
- `python_backend/app/routers/me.py`
  - профиль пользователя
- `python_backend/app/db.py`
  - подключение к БД
- `db/schema.sql`
  - основная схема
- `db/functions.sql`
  - SQL-логика пересчёта территорий и статистики
- `db/migrations/`
  - место для новых миграций

## 2.2 Frontend

Текущие точки интеграции:

- `flutter_fronted/lib/src/features/runs/domain/run_models.dart`
  - модель `FinishRunResponse`
- `flutter_fronted/lib/src/features/runs/data/runs_api.dart`
  - вызов `POST /runs/finish`
- `flutter_fronted/lib/src/features/runs/application/run_tracker_controller.dart`
  - сохраняет `lastFinish` после завершения пробежки
- `flutter_fronted/lib/src/features/runs/presentation/run_summary_page.dart`
  - экран итогов пробежки
- `flutter_fronted/lib/src/features/profile/domain/me_profile.dart`
  - модель профиля
- `flutter_fronted/lib/src/features/profile/data/profile_repository.dart`
  - парсинг `/me/profile`
- `flutter_fronted/lib/src/features/profile/presentation/profile_page.dart`
  - экран профиля

## 3. Предлагаемая стратегия реализации

Внедрять по слоям:

1. БД и миграции.
2. Backend-модели и сервис достижений.
3. Интеграция достижений в `finish_run`.
4. API профиля и отдельный endpoint достижений.
5. Flutter-модели, API и профиль.
6. Popup после забега.

Такой порядок позволит сначала сделать надёжный серверный источник правды, а потом подключить UI.

## 4. Изменения базы данных

## 4.1 Новые миграции

Рекомендуется добавить как минимум две миграции:

- `db/migrations/20260411_achievements_core.sql`
- `db/migrations/20260411_achievements_seed.sql`

При желании можно разделить ещё детальнее:

- `20260411_achievements_tables.sql`
- `20260411_user_stats_achievement_fields.sql`
- `20260411_achievements_seed.sql`

## 4.2 Что добавить в `user_stats`

Новые поля:

- `successful_captures_count integer not null default 0`
- `total_captured_area_m2 double precision not null default 0`
- `total_victims_count integer not null default 0`
- `profile_xp integer not null default 0`
- `profile_level integer not null default 1`

Назначение:

- `successful_captures_count`
  - для достижений по числу успешных захватов
- `total_captured_area_m2`
  - для накопительных достижений по общей захваченной площади
- `total_victims_count`
  - для накопительных достижений по соперникам
- `profile_xp`
  - итоговый опыт профиля
- `profile_level`
  - рассчитанный уровень профиля

## 4.3 Таблица каталога достижений

Создать таблицу `achievement_definitions`.

Поля:

- `id uuid primary key default gen_random_uuid()`
- `code text not null unique`
- `title text not null`
- `description text not null`
- `category text not null`
- `icon_key text not null`
- `xp integer not null`
- `rule_type text not null`
- `rule_value double precision not null`
- `sort_order integer not null default 0`
- `created_at timestamptz not null default now()`

Индексы:

- unique index по `code`
- index по `category, sort_order`

## 4.4 Таблица выданных достижений

Создать таблицу `user_achievements`.

Поля:

- `user_id uuid not null references users(id) on delete cascade`
- `achievement_id uuid not null references achievement_definitions(id) on delete cascade`
- `source_run_id uuid references runs(id) on delete set null`
- `unlocked_at timestamptz not null default now()`

Ключи:

- `primary key (user_id, achievement_id)`

Индексы:

- index по `user_id, unlocked_at desc`
- index по `source_run_id`

## 4.5 Seed каталога достижений

В `20260411_achievements_seed.sql` нужно вставить весь каталог достижений из:

- `docs/plans/ACHIEVEMENTS_MVP_PLAN.md`

Практический совет:

- хранить `code` как стабильный ключ
- не завязывать код backend на `title`

## 4.6 Где обновлять агрегаты

Есть два варианта.

### Вариант A. Обновлять в `db/functions.sql`

Расширить `finalize_run_capture(...)`, чтобы он дополнительно обновлял:

- `successful_captures_count`
- `total_captured_area_m2`
- `total_victims_count`

Плюсы:

- все производные метрики обновляются в одном месте
- меньше риска забыть пересчёт

Минусы:

- SQL-функция станет сложнее

### Вариант B. Обновлять в Python после `finalize_run_capture(...)`

После возврата из SQL-функции в `python_backend/app/routers/runs.py` выполнять отдельный SQL `UPDATE user_stats`.

Плюсы:

- проще читать и дебажить

Минусы:

- логика статистики будет разделена между SQL и Python

### Рекомендация

Для этого проекта лучше:

- базовые агрегаты территории оставить в `db/functions.sql`
- achievement-specific поля тоже обновлять там же

Причина: метрики напрямую зависят от уже рассчитанных `capture_area_m2` и `victims_count`, и их удобно обновлять в рамках одной транзакции обработки пробежки.

## 5. Изменения backend

## 5.1 Новые backend-файлы

Рекомендуется добавить:

- `python_backend/app/services/achievements_service.py`
- `python_backend/app/repositories/achievements_repo.py`

Если хочется проще и компактнее, можно начать без репозитория и сделать только:

- `python_backend/app/services/achievements_service.py`

## 5.2 Что должно быть в `achievements_service.py`

Минимальный набор функций:

- `get_level_for_xp(xp: int) -> int`
- `evaluate_user_achievements(conn, user_id: str, run_id: str | None) -> AchievementEvaluationResult`
- `list_user_achievements(conn, user_id: str) -> ...`

Результат оценки должен содержать:

- список новых достижений
- старый уровень
- новый уровень
- итоговый `profile_xp`
- итоговый `profile_level`

## 5.3 Предлагаемая логика `evaluate_user_achievements(...)`

Шаги:

1. Загрузить метрики пользователя из `user_stats`.
2. При наличии `run_id` загрузить данные конкретного забега из `runs`.
3. Загрузить все `achievement_definitions`.
4. Загрузить уже полученные пользователем достижения.
5. Для каждого определения проверить правило:
   - сравнить нужную метрику с `rule_value`
6. Собрать новые достижения, которых ещё нет в `user_achievements`.
7. Вставить новые строки в `user_achievements`.
8. Посчитать суммарный XP по всем выданным достижениям.
9. Определить новый уровень.
10. Обновить `user_stats.profile_xp` и `user_stats.profile_level`.
11. Вернуть данные для ответа API.

## 5.4 Где вызывать сервис

Основная точка:

- `python_backend/app/routers/runs.py`

Текущее место:

- после `finalize_run_capture(...)`
- после `UPDATE runs SET capture_area_m2 = ..., victims_count = ...`

Предлагаемая последовательность:

1. создать `runs`
2. вставить `run_points`
3. вставить `run_pauses`
4. вызвать `finalize_run_capture(run_id)`
5. обновить `runs.capture_area_m2` и `runs.victims_count`
6. вызвать `evaluate_user_achievements(...)`
7. вернуть расширенный `RunFinishResponse`

## 5.5 Какие backend-файлы менять

### `python_backend/app/models.py`

Добавить новые Pydantic-модели:

- `AchievementUnlockedOut`
- `LevelUpOut`
- `AchievementItemOut`
- `AchievementsResponseOut`

И расширить:

- `UserStatsOut`
- `MeProfileOut`
- `RunFinishResponse`

Новые поля в `UserStatsOut`:

- `successful_captures_count`
- `total_captured_area_m2`
- `total_victims_count`
- `profile_xp`
- `profile_level`

Новые поля в `RunFinishResponse`:

- `new_achievements: list[AchievementUnlockedOut]`
- `level_up: LevelUpOut | None`
- `profile_xp: int`
- `profile_level: int`

### `python_backend/app/routers/runs.py`

Изменения:

- импортировать сервис достижений
- после завершения расчёта пробежки вызвать `evaluate_user_achievements(...)`
- вернуть новые поля в `RunFinishResponse`

### `python_backend/app/routers/me.py`

Изменения:

- расширить запрос `GET /me/profile`
- подтягивать новые поля из `user_stats`

Дополнительно:

- добавить новый endpoint `GET /me/achievements`

### `python_backend/app/main.py`

Проверить:

- если будет отдельный router для достижений, подключить его в приложение

## 5.6 Нужен ли отдельный router достижений

Есть два допустимых варианта.

### Вариант A. Добавить endpoint в `routers/me.py`

Например:

- `GET /me/achievements`

Плюсы:

- быстро
- логично для "моих" достижений

### Вариант B. Сделать отдельный router

Например:

- `python_backend/app/routers/achievements.py`

Плюсы:

- чище структура
- проще расширять потом

### Рекомендация

Для MVP достаточно:

- оставить это в `routers/me.py`

Когда появятся публичные профили, рейтинги достижений или каталоги, тогда вынести в отдельный router.

## 6. Изменения в моделях и API Flutter

## 6.1 Файлы runs

### `flutter_fronted/lib/src/features/runs/domain/run_models.dart`

Расширить `FinishRunResponse`.

Добавить модели:

- `UnlockedAchievement`
- `LevelUpInfo`

Новые поля в `FinishRunResponse`:

- `List<UnlockedAchievement> newAchievements`
- `LevelUpInfo? levelUp`
- `int profileXp`
- `int profileLevel`

### `flutter_fronted/lib/src/features/runs/data/runs_api.dart`

Проверить:

- новый JSON корректно прокидывается без изменений

### `flutter_fronted/lib/src/features/runs/application/run_tracker_controller.dart`

Ничего кардинально менять не нужно:

- `lastFinish` уже хранится
- popup можно открыть на экране итогов, используя `lastFinish`

Опционально:

- если popup захотите показывать раньше, можно открывать его ещё до перехода на `run_summary_page`

## 6.2 Файлы profile

### `flutter_fronted/lib/src/features/profile/domain/me_profile.dart`

Расширить `MeProfileStats`:

- `successfulCapturesCount`
- `totalCapturedAreaM2`
- `totalVictimsCount`
- `profileXp`
- `profileLevel`

Если achievements будут приходить отдельным endpoint, можно добавить новые модели:

- `AchievementItem`
- `AchievementsOverview`

### `flutter_fronted/lib/src/features/profile/data/profile_api.dart`

Добавить методы:

- `Future<Map<String, dynamic>> getMyAchievements()`

### `flutter_fronted/lib/src/features/profile/domain/repositories/profile_repository.dart`

Добавить:

- `Future<AchievementsOverview> getMyAchievements()`

### `flutter_fronted/lib/src/features/profile/data/profile_repository.dart`

Добавить:

- парсинг achievement-моделей
- маппинг нового поля `profile_level`
- маппинг `profile_xp`

### `flutter_fronted/lib/src/features/profile/application/profile_controller.dart`

Добавить provider:

- `myAchievementsProvider`

И инвалидировать его после завершения пробежки, если нужно немедленное обновление профиля.

### `flutter_fronted/lib/src/features/profile/presentation/profile_page.dart`

Добавить:

- карточку уровня профиля
- текущий XP
- секцию достижений

## 7. Popup после забега

## 7.1 Где показывать popup

Лучшее MVP-место:

- `flutter_fronted/lib/src/features/runs/presentation/run_summary_page.dart`

Почему:

- экран уже открывается сразу после завершения пробежки
- в нём уже есть `finish`
- не нужно усложнять `router` или `controller`

## 7.2 Как показывать

Рекомендуемый способ:

- `WidgetsBinding.instance.addPostFrameCallback(...)`
- при первом построении страницы проверить:
  - `finish.newAchievements.isNotEmpty`
  - или `finish.levelUp != null`
- показать `showDialog(...)` или `showModalBottomSheet(...)`

## 7.3 Что добавить на фронте

Рекомендуется создать:

- `flutter_fronted/lib/src/features/runs/presentation/widgets/achievements_popup.dart`

Если папки `widgets/` нет, её можно создать.

Содержимое popup:

- заголовок `Новое достижение`
- список новых достижений
- иконка
- название
- описание
- XP
- при наличии `levelUp` блок:
  - `Уровень повышен`
  - `2 -> 3`

## 7.4 Защита от повторного открытия popup

Нужно, чтобы popup не открывался каждый rebuild.

Варианты:

- сделать `RunSummaryPage` stateful и хранить флаг `_popupShown`
- или очищать специальный локальный флаг после первого показа

Рекомендация:

- перевести `RunSummaryPage` в `ConsumerStatefulWidget`
- добавить `bool _didShowAchievementsPopup = false`

## 8. Иконки и визуальная система

На этапе MVP лучше не делать десятки уникальных файлов.

## 8.1 Подход

Использовать:

- один базовый шаблон badge
- разные символы по категории
- разные цвета по редкости

## 8.2 Где хранить

Варианты:

- Flutter `IconData`
- SVG-ассеты
- PNG-ассеты

Рекомендация для MVP:

- начать с `IconData`
- сделать mapper `icon_key -> IconData`

Например:

- `run_count -> Icons.directions_run`
- `distance_single -> Icons.route`
- `distance_total -> Icons.timeline`
- `capture_single -> Icons.crop_square`
- `capture_total -> Icons.public`
- `captures_count -> Icons.flag`
- `victims -> Icons.gps_fixed`
- `owned_area -> Icons.map`
- `level_up -> Icons.military_tech`

Позже можно заменить это на SVG без изменения backend-контрактов.

## 8.3 Где реализовать mapper

Создать utility-файл, например:

- `flutter_fronted/lib/src/features/profile/presentation/achievement_icon_mapper.dart`

или общий UI helper:

- `flutter_fronted/lib/src/core/ui/achievement_icon_mapper.dart`

## 9. Предлагаемые backend DTO

## 9.1 `AchievementUnlockedOut`

Поля:

- `code`
- `title`
- `description`
- `icon_key`
- `xp`
- `unlocked_at`

## 9.2 `LevelUpOut`

Поля:

- `old_level`
- `new_level`

## 9.3 `AchievementsResponseOut`

Поля:

- `profile_xp`
- `profile_level`
- `items: list[AchievementItemOut]`

## 9.4 `AchievementItemOut`

Поля:

- `code`
- `title`
- `description`
- `category`
- `icon_key`
- `xp`
- `unlocked_at`

## 10. Предлагаемые Flutter-модели

## 10.1 Для завершения пробежки

В `run_models.dart`:

- `class UnlockedAchievement`
- `class LevelUpInfo`

## 10.2 Для профиля

Можно добавить новый файл:

- `flutter_fronted/lib/src/features/profile/domain/achievement_models.dart`

В нём:

- `class AchievementItem`
- `class AchievementsOverview`

Это лучше, чем перегружать `me_profile.dart`.

## 11. Поэтапный план реализации

## Этап 1. Миграции и схема

Сделать:

- новые таблицы достижений
- новые поля в `user_stats`
- seed каталога достижений

Проверить:

- миграции накатываются на чистую БД
- seed выполняется повторно без дублей

## Этап 2. SQL-агрегаты

Изменить:

- `db/functions.sql`

Добавить обновление:

- `successful_captures_count`
- `total_captured_area_m2`
- `total_victims_count`

Проверить:

- пустой захват
- успешный захват
- захват с жертвами

## Этап 3. Backend models и service

Сделать:

- новые Pydantic-модели
- `achievements_service.py`
- расчёт XP и уровня

Проверить:

- достижение выдаётся только один раз
- при большом событии может открыться несколько достижений
- уровень пересчитывается корректно

## Этап 4. Интеграция в `finish_run`

Изменить:

- `python_backend/app/routers/runs.py`

Сделать:

- вызвать сервис оценки достижений
- вернуть новые поля в `RunFinishResponse`

Проверить:

- старый сценарий завершения пробежки не ломается
- фронт получает новые поля

## Этап 5. Профиль и endpoint достижений

Изменить:

- `python_backend/app/routers/me.py`

Сделать:

- отдать `profile_xp`
- отдать `profile_level`
- добавить `GET /me/achievements`

Проверить:

- профиль корректно открывается у старых пользователей
- achievements endpoint возвращает пустой список для новых аккаунтов

## Этап 6. Flutter profile

Изменить:

- `me_profile.dart`
- `profile_api.dart`
- `profile_repository.dart`
- `profile_controller.dart`
- `profile_page.dart`

Сделать:

- карточку уровня
- список достижений

## Этап 7. Flutter popup

Изменить:

- `run_models.dart`
- `run_summary_page.dart`

Добавить:

- `achievements_popup.dart`

Сделать:

- popup новых достижений
- отображение `level up`

## Этап 8. Локализация и тексты

Изменить:

- `flutter_fronted/lib/l10n/app_ru.arb`
- `flutter_fronted/lib/l10n/app_en.arb`

Добавить тексты:

- popup достижений
- уровень профиля
- XP
- заголовки секций

## 12. Минимальный технический чек-лист

- [ ] Добавлены миграции достижений
- [ ] Добавлены новые поля в `user_stats`
- [ ] Обновлён `finalize_run_capture(...)` или эквивалентный слой обновления агрегатов
- [ ] Добавлен `achievements_service.py`
- [ ] Расширен `RunFinishResponse`
- [ ] Добавлен `GET /me/achievements`
- [ ] Расширен `MeProfileOut`
- [ ] Обновлены Flutter-модели
- [ ] Добавлен popup после забега
- [ ] Добавлен блок уровня и достижений в профиле

## 13. Рекомендация по первой итерации

Чтобы быстрее получить рабочий результат, первую реализацию лучше делать в таком урезанном порядке:

1. БД и seed достижений.
2. Backend-проверка достижений.
3. Расширенный ответ `finish_run`.
4. Popup на `run_summary_page`.
5. Только после этого экран достижений в профиле.

Почему:

- popup после забега даст быстрый видимый эффект
- проще проверить корректность логики достижений
- профиль можно спокойно доделать второй итерацией

## 14. Итог

Для текущего проекта оптимальный путь такой:

- хранить каталог достижений и факт выдачи в PostgreSQL
- считать достижения в Python после `finish_run`
- агрегаты для условий хранить в `user_stats`
- popup показывать на `run_summary_page`
- уровень профиля строить от XP уже выданных достижений

Это самый безопасный и понятный вариант внедрения без лишнего усложнения архитектуры.
