# Changelog (2026-04-11): достижения, уровни профиля и экран коллекции

## Добавлено

### БД и миграции

- В `user_stats` добавлены новые агрегаты:
  - `successful_captures_count`
  - `total_captured_area_m2`
  - `total_victims_count`
  - `profile_xp`
  - `profile_level`
- Добавлены новые таблицы:
  - `achievement_definitions`
  - `user_achievements`
- Добавлена миграция:
  - `db/migrations/20260411_achievements_mvp.sql`
- В каталог достижений добавлен seed из `35` ачивок.

### SQL-логика обработки пробежки

- Обновлена `finalize_run_capture(...)` в `db/functions.sql`:
  - теперь пробежки без захвата территории тоже попадают в `user_stats`,
  - при успешном захвате обновляются новые achievement-агрегаты,
  - статистика становится пригодной для ачивок и уровней.

### Backend API достижений

- Добавлен service layer:
  - `python_backend/app/services/achievements_service.py`
- Добавлен endpoint:
  - `GET /me/achievements`
- Endpoint отдаёт:
  - `profile_xp`
  - `profile_level`
  - полный каталог достижений
  - признак `is_unlocked`
  - `unlocked_at` для уже открытых достижений

### Backend профиль и завершение пробежки

- Расширен `GET /me/profile`:
  - возвращает новые поля achievement-статистики и уровень профиля
- Расширен `POST /runs/finish`:
  - `new_achievements`
  - `level_up`
  - `profile_xp`
  - `profile_level`
- После завершения пробежки backend:
  - проверяет новые достижения,
  - записывает их в `user_achievements`,
  - пересчитывает XP и уровень.

### Backend модели

- Обновлены `python_backend/app/models.py`:
  - `UserStatsOut`
  - `RunFinishResponse`
  - `AchievementsResponseOut`
  - новые DTO для достижений и `level_up`

### Flutter: коллекция достижений

- Добавлен экран:
  - `flutter_fronted/lib/src/features/profile/presentation/achievements_page.dart`
- Экран показывает:
  - все достижения, а не только открытые,
  - открытые цветные карточки,
  - закрытые тусклые серые карточки,
  - вертикальную ленту карточек на всю ширину.

### Flutter: навигация

- В нижний бар добавлены отдельные вкладки:
  - `Achievements`
  - `Leaderboard`
- Обновлены:
  - `flutter_fronted/lib/src/app/router.dart`
  - `flutter_fronted/lib/src/app/home_shell_page.dart`

### Flutter: popup после пробежки

- Добавлен popup новых достижений:
  - `flutter_fronted/lib/src/features/runs/presentation/widgets/achievements_popup.dart`
- Popup показывает:
  - новые достижения,
  - XP,
  - `level up`, если уровень повысился.

### Flutter: UI-компоненты

- Добавлен общий виджет карточки достижения:
  - `flutter_fronted/lib/src/core/ui/achievement_badge_card.dart`
- Добавлен summary-виджет коллекции:
  - `flutter_fronted/lib/src/features/profile/presentation/widgets/profile_achievements_summary_card.dart`

### Flutter: локализация

- Добавлены новые ключи в:
  - `flutter_fronted/lib/l10n/app_ru.arb`
  - `flutter_fronted/lib/l10n/app_en.arb`
- Перегенерированы:
  - `app_localizations.dart`
  - `app_localizations_ru.dart`
  - `app_localizations_en.dart`
- Добавлен helper для локализации названий и описаний достижений по `code`:
  - `flutter_fronted/lib/src/core/utils/achievement_localization.dart`

## Изменено

### Профиль

- Из профиля убрана плашка коллекции достижений.
- Summary-блок уровня и количества достижений перенесён на экран `Все достижения`.
- В профиле оставлены achievement-метрики в статистике:
  - уровень профиля,
  - XP,
  - успешные захваты,
  - суммарно захваченная площадь,
  - количество затронутых соперников.

### Экран достижений

- После последних правок:
  - внизу списка добавлен дополнительный отступ `SizedBox(height: 20)`.

## Документация

- Добавлен продуктовый план:
  - `docs/plans/ACHIEVEMENTS_MVP_PLAN.md`
- Добавлен технический план:
  - `docs/plans/ACHIEVEMENTS_IMPLEMENTATION_PLAN.md`
- Добавлен runbook VPS-деплоя:
  - `docs/guide/vps_deploy_achievements_profile_levels.md`

## Проверено

- Локально применена миграция `20260411_achievements_mvp.sql`.
- В локальной БД `run_app` каталог достижений создан и засеян (`35` записей).
- `python3 -m compileall python_backend/app` проходит.
- `flutter gen-l10n` проходит.
- `flutter analyze` не показывает новых ошибок по изменённым файлам.

## Важно перед продом

- На VPS обязательно применить:
  - `db/migrations/20260411_achievements_mvp.sql`
- После миграции обязательно пересобрать backend-образ.
- Проверить на проде:
  - `/me/profile`
  - `/me/achievements`
  - реальный сценарий `POST /runs/finish`
- Учесть, что вкладки и новый экран достижений — это часть Flutter-клиента, а не VPS-инфраструктуры.
