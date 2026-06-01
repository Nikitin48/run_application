# Changelog

Все значимые изменения проекта документируются здесь. Формат ориентирован на разработчиков: что изменилось, где искать код, как применить локально.

Спецификация правил захвата: `docs/territory_capture_rules.md`.

---

## Unreleased

### Кратко

Реализованы правила захвата территорий **protected / contested / vulnerable**:

- Территории хранятся как **независимые фрагменты** (не один полигон на пользователя).
- Пересечение с **защищённой** территорией создаёт **спорную область**; остаток фрагмента остаётся у владельца.
- Пересечение с **уязвимой** территорией — **мгновенный захват** (steal).
- Спорные области разрешаются по таймеру (`resolve_at` = `protected_until` исходного фрагмента); победитель — `current_winner_user_id`.
- **Авторазрешение:** фоновый цикл в backend (~15 с) на VPS; карта/пробежка — только запасной вызов.
- **Слияние фрагментов:** только между **уязвимыми** кусками одного игрока; protected остаются отдельными до истечения таймеров.
- **Свой повторный захват:** пересечение с ещё protected-фрагментом выделяется в отдельный кусок с **новым 6 ч**, остаток сохраняет старый таймер.
- Карта, bottom sheet, push и экран уведомлений различают `territory_contested` и `territory_stolen`.

---

### База данных

#### Миграция

**Файл:** `db/migrations/20260528_territory_capture_rules.sql`

- Переименование старой таблицы `territories` → `territories_legacy_one_row_per_user` (если ещё нет колонки `id`).
- Новая таблица `territories`:
  - `id uuid PK`
  - `user_id`, `geom`, `captured_at`
  - `protected_until`, `protection_duration_hours` (2–6 ч)
  - `status`: `protected` | `vulnerable` (см. ниже про contested)
- Данные из legacy-таблицы **переносятся**, а не удаляются; legacy затем дропается.
- Новые таблицы:
  - `territory_contested_areas` — геометрия спора, `current_winner_user_id`, `resolve_at`
  - `territory_contested_area_participants` — участники спора (владелец + претенденты)

**Файл:** `db/schema.sql` — приведён к актуальной схеме.

#### PostGIS-функции

**Файл:** `db/functions.sql`

| Функция | Назначение |
|---------|------------|
| `territory_clean_multipolygon` | Нормализация геометрии, отсечение мелких кусков |
| `territory_owned_area_m2` | Суммарная площадь фрагментов пользователя |
| `territory_merge_adjacent_fragments` | Объединяет соприкасающиеся/пересекающиеся фрагменты **одного** user_id, только если **оба** `protected_until <= now()` |
| `territory_merge_all_vulnerable_adjacent` | Прогон merge для всех пользователей с несколькими фрагментами (фоновый tick) |
| `refresh_territory_statuses` | `protected` / `vulnerable` только по `protected_until`; **не** помечает весь фрагмент contested |
| `resolve_expired_territory_contests` | По истечении `resolve_at` передаёт спорную геометрию победителю, удаляет contest, merge уязвимых у затронутых игроков |
| `finalize_run_capture` | Основная логика захвата после пробежки |

**Логика `finalize_run_capture`:**

1. Вызывает `resolve_expired_territory_contests` и `refresh_territory_statuses`.
2. Строит полигон захвата из трека пробежки.
3. **Свой protected-фрагмент:** если новый маршрут пересекает ещё защищённую территорию того же игрока — overlap вырезается в **новый** фрагмент (6 ч), у остатка **сохраняется** прежний `protected_until`.
4. Если владелец пересекает **свой** активный contest — обновляет `current_winner_user_id`.
5. Для **чужих** фрагментов с пересечением:
   - **`protected_until > now()`** → пересечение в `territory_contested_areas`, из захвата бегуна вычитается overlap; уведомление `territory_contested`.
   - **Иначе** → мгновенный steal (разность геометрий); уведомление `territory_stolen`.
6. Чисто **новая** геометрия (вне уже owned) → отдельный protected-фрагмент (6 ч).
7. **Не** склеивает protected с vulnerable сразу; `territory_merge_adjacent_fragments` — только для пары уязвимых.
8. Обновляет `user_stats`, возвращает `capture_area_m2`, `victims_count`.

**Логика `resolve_expired_territory_contests` (победитель ≠ владелец):**

1. Вычитает спорную геометрию из фрагмента проигравшего (`ST_Difference`); пустой фрагмент удаляется.
2. Создаёт у победителя новый protected-фрагмент (таймер `protection_duration_hours - 1`, мин. 2 ч).
3. После всех споров — merge **только уязвимых** соседних фрагментов у затронутых игроков.

**Слияние фрагментов одного игрока:**

| Ситуация | Поведение |
|----------|-----------|
| Новый protected + старый vulnerable, соприкасаются | Два полигона до истечения защиты нового |
| Оба vulnerable, соприкасаются | Merge (фоновый tick или конец capture/resolve) |
| Protected + protected с разными таймерами | Не merge |
| Повторный захват overlap на своём protected | Три (или более) фрагмента с разными таймерами |

**Важно для разработки:** contested — отдельная сущность в `territory_contested_areas`, а не `status = 'contested'` у родительского фрагмента. Статус фрагмента отражает только таймер защиты.

#### Применение локально

```bash
export DATABASE_URL="postgresql://USER@127.0.0.1:5432/run_app"  # свой URL

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/20260528_territory_capture_rules.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/functions.sql
psql "$DATABASE_URL" -c "SELECT refresh_territory_statuses();"
```

После миграции — перезапуск Python backend и hot restart Flutter.

**Типичная ошибка без миграции:** `relation "territory_contested_areas" does not exist` при завершении пробежки.

#### Авторазрешение споров (resolve_at)

| Компонент | Файл | Когда срабатывает |
|-----------|------|-------------------|
| **Фоновый цикл API** | `python_backend/app/background/territory_contest_resolver.py` | Каждые `TERRITORY_CONTEST_RESOLVE_INTERVAL_SECONDS` (по умолчанию 15 с), пока backend на VPS (`docker compose`, `restart: unless-stopped`) |
| **Сервис + lock** | `python_backend/app/services/territory_maintenance.py` | `resolve_expired_territory_contests` + `territory_merge_all_vulnerable_adjacent`; `pg_try_advisory_lock` |
| **Запасной вызов** | `GET /territories`, `finalize_run_capture` | Идемпотентно, если фон уже отработал |

**Деплой:** отдельных FaaS/cron-функций в проекте нет — фоновые задачи только в контейнере backend (см. `deploy/README.md` §6).

Env (backend):

```bash
TERRITORY_CONTEST_RESOLVE_ENABLED=true
TERRITORY_CONTEST_RESOLVE_INTERVAL_SECONDS=15
```

Лог при старте: `Territory contest background resolver started (interval=15s)`.

Каждый tick: `Territory contest resolve tick (interval=15s): resolved=N`.

При `resolved > 0` споры закрыты; merge уязвимых выполняется в том же tick.

---

### Backend (Python / FastAPI)

#### `GET /territories`

**Файл:** `python_backend/app/routers/territories.py`

- Перед выборкой: `resolve_due_territory_contests()` (запасной вызов; основное — фоновый цикл).
- В `stats.owned_area_m2` — **суммарная** площадь владельца (`user_stats` / `territory_owned_area_m2`), не площадь одного фрагмента.
- GeoJSON FeatureCollection с двумя видами features:
  - `feature_kind: "territory"` — фрагменты владельцев (`territory_id`, `status`, `protected_until`, stats, …).
  - `feature_kind: "contested_area"` — спорные overlay (`contested_area_id`, `participants`, `current_winner_*`, `resolve_at`, `status: "contested"`).

#### Завершение пробежки

**Файл:** `python_backend/app/routers/runs.py`

- Push-таргеты группируются по `(attacker_name, kind)`.
- `kind` берётся из результата `finalize_run_capture` (`territory_contested` | `territory_stolen`).

#### Push

**Файл:** `python_backend/app/push.py`

| `kind` | Заголовок | Текст |
|--------|-----------|-------|
| `territory_contested` | Часть территории стала спорной | `{attacker} оспаривает часть вашей территории` |
| `territory_stolen` | Часть территории захвачена | `{attacker} забрал уязвимую часть вашей территории` |

В `data` push: `kind`, `attacker_display_name`.

---

### Flutter

#### Модель и парсинг

**Файлы:**

- `lib/src/features/territories/domain/territory.dart`
- `lib/src/features/territories/data/territories_repository.dart`

Добавлено:

- `TerritoryFeatureKind`: `territory` | `contestedArea`
- `TerritoryStatus`: `protected`, `contested`, `vulnerable`
- Поля: `territoryId`, `contestedAreaId`, `protectedUntil`, `resolveAt`, `participants`, `currentWinnerDisplayName`, …

**Тест:** `test/features/territories/data/territories_repository_test.dart` — парсинг contested feature; отдельный тест на `owned_area_m2` ≠ `area_m2` фрагмента.

#### Карта

**Файлы:**

- `lib/src/features/territories/presentation/map_page.dart`
- `lib/src/features/territories/presentation/neon_map_layers.dart`
- `lib/src/features/territories/presentation/territory_map_label.dart`

Изменения:

- Сначала рисуются фрагменты владельцев, поверх — спорные overlay.
- Спорная заливка — смесь цветов участников (`appendContestedTerritoryRing`).
- Спорная зона — **сетка** поверх заливки (`appendContestedTerritoryGrid`, ground-aligned, clipped к полигону).
- Метки на карте: ключ `territory-label-${territoryId}-$i` (исправлен дубликат ключей).
- Защита на метке: SVG-щит `assets/icon/shield-alt-svgrepo-com.svg` вместо текста «(защ.)».
- Зависимость: `flutter_svg` в `pubspec.yaml`.

#### Bottom sheet территории

**Файл:** `map_page.dart` (`_TerritoryOwnerBottomSheet`)

- Крупный статус под именем: **ЗАЩИЩЕНА** / **СПОРНАЯ** / **УЯЗВИМА** (+ подпись «До …» / «До решения: …»).
- Статус вынесен из блока площади.
- **Тап по спорной области:**
  - показывается только карточка «Спорная область» (участники, претендент, таймер);
  - **скрыты** «Статистика данной области» и «Общая статистика пользователя».

#### Уведомления

**Файлы:**

- `lib/src/core/notifications/local_notifications_service.dart`
- `lib/src/features/notifications/application/push_messaging_provider.dart`
- `lib/src/features/notifications/data/notifications_repository.dart`
- `lib/src/features/notifications/domain/last_notification.dart`
- `lib/src/features/notifications/presentation/notifications_page.dart`

- Поддержка `kind`: `territory_contested` | `territory_stolen`.
- Разные тексты в списке уведомлений и локальных push.

#### Завершение пробежки (UI)

**Файл:** `lib/src/app/home_shell_page.dart`

- При ошибке finish: FAB снова раскрывается, показывается SnackBar с текстом ошибки (раньше кнопки «схлопывались» без feedback).
- После успешного finish: invalidate `territoriesForBboxProvider`, `notificationsHistoryProvider`, `runHistoryProvider`.

---

### Исправленные баги

| Проблема | Решение |
|----------|---------|
| Синтаксис миграции (`territories_legacy_one_row_per_user`) | `INSERT` обёрнут в `EXECUTE` внутри `DO` |
| Весь фрагмент становился contested / терял защиту | Contest только в `territory_contested_areas`; `refresh_territory_statuses` по `protected_until` |
| Дублирующиеся ключи маркеров на карте | `ValueKey('territory-label-${t.territoryId}-$i')` |
| Finish run без ошибки, но FAB исчезал | Обработка неуспешного finish в `home_shell_page.dart` |
| `territory_contested_areas does not exist` | Нужна миграция + `functions.sql` |
| «Доля от всей территории» всегда ~100% | В API `owned_area_m2` ошибочно брался из `area_m2` фрагмента; исправлено в `territories.py` |
| Новый маршрут + старая vulnerable → вся область protected | Мгновенный merge с `GREATEST(protected_until)`; merge теперь только для пары vulnerable |
| Повторный захват своей protected с 1 ч → весь фрагмент 6 ч | Overlap вырезается в отдельный фрагмент 6 ч, остаток сохраняет старый таймер |
| Споры разрешались только при открытии карты | Фоновый resolver в `main.py` (lifespan) |

---

### Что проверить вручную

1. Миграция на чистой и на legacy БД (данные сохраняются).
2. Захват уязвимого фрагмента → steal + push `territory_stolen`.
3. Захват protected → только overlap contested, remainder protected на карте.
4. Спорная зона: multi-color fill + сетка; bottom sheet без лишних блоков.
5. Истечение `resolve_at` → contest исчезает в течение ~15 с без действий пользователя (backend запущен).
6. Завершение пробежки при остановленном backend → SnackBar, FAB доступен.
7. «Доля от всей территории» при нескольких фрагментах — доля полигона от **общей** площади игрока.
8. Новый маршрут рядом с **своей vulnerable** → два контура (новый protected, старый vulnerable); после истечения 6 ч — merge в один vulnerable.
9. Новый маршрут через **свою protected** (осталось ~1 ч) → overlap с 6 ч, остаток с прежним таймером.
10. После спора в пользу другого игрока — у проигравшего вырезается геометрия; у победителя новый protected-фрагмент.

---

### Возможные следующие шаги

- E2E / интеграционные тесты capture flow (PostGIS + API).
- Push при автоматическом разрешении спора (сейчас только при захвате).
- SQL-тесты на merge/split геометрий (self-capture, vulnerable merge).
- Отдельная метка/легенда для спорных зон на карте.
- Настройка шага/стиля сетки contested (сейчас ~22 m, белые линии α≈0.42).
- Версионирование API GeoJSON (`feature_kind`) при breaking changes.
- CI-шаг: прогон миграции + smoke `finalize_run_capture` на тестовой БД.

---

### Затронутые файлы (ориентир)

```
db/migrations/20260528_territory_capture_rules.sql
db/schema.sql
db/functions.sql
python_backend/app/main.py
python_backend/app/background/territory_contest_resolver.py
python_backend/app/services/territory_maintenance.py
python_backend/app/routers/territories.py
python_backend/app/routers/runs.py
python_backend/app/push.py
python_backend/app/settings.py
python_backend/env.example
python_backend/README.md
deploy/README.md
flutter_fronted/pubspec.yaml
flutter_fronted/assets/icon/shield-alt-svgrepo-com.svg
flutter_fronted/lib/src/app/home_shell_page.dart
flutter_fronted/lib/src/features/territories/**
flutter_fronted/lib/src/features/notifications/**
flutter_fronted/test/features/territories/data/territories_repository_test.dart
```
