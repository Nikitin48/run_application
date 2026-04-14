# План улучшения backend (2 итерации)

Цель: повысить соответствие лучшим практикам без большого переписывания и без долгой остановки разработки фич.

## Итерация 1 (1-2 дня): разгрузить роутеры и закрыть базовые риски

### 1) Вынести бизнес-логику из роутеров
- `app/routers/auth.py`: оставить только HTTP-слой, SQL и token flow перенести в сервис + репозиторий.
- `app/routers/runs.py`: вынести `finish_run` use-case в `RunService`, оставить в роутере только валидацию входа/ответ.
- `app/routers/me.py`: вынести profile update / password change / stats load в сервисы.

Рекомендуемая структура:
- `app/services/auth_service.py`
- `app/services/run_service.py`
- `app/services/profile_service.py`
- `app/repositories/auth_repo.py`
- `app/repositories/runs_repo.py`
- `app/repositories/users_repo.py`

### 2) Единый подход к data-access
- SQL хранить в репозиториях, не в роутерах.
- Сервисы должны работать с доменными объектами/DTO, а не с `cursor` напрямую.
- Минимум дублирования SQL-кусочков (особенно проверка пользователя, загрузка профиля, refresh flow).

### 3) Безопасность и fail-fast настройки
- В `settings` добавить проверку: в `release` запрещать `jwt_secret == "change_me"`.
- Добавить CORS middleware в `app/main.py` (разрешенные origins через env).
- Добавить глобальный handler для ожидаемых ошибок (стабильный формат ответа без утечки деталей).

### 4) Тесты на критичные потоки (минимальный набор)
- `tests/test_auth_flow.py`: register/login/refresh/invalid token.
- `tests/test_runs_finish.py`: happy-path + invalid payload + empty track.
- `tests/test_me_profile.py`: update profile + password change.

Критерий готовности итерации:
- В роутерах нет длинных SQL-блоков и сложной бизнес-логики.
- Критичные потоки покрыты smoke/integration тестами.

---

## Итерация 2 (1-2 дня): стабилизация и эксплуатационные практики

### 1) Тестовая инфраструктура
- Вынести общие фикстуры в `tests/conftest.py` (клиент, auth helper, seed helper).
- Отделить unit-тесты сервисов от интеграционных тестов API.
- Добавить запуск тестов одной командой (`pytest`) и короткую инструкцию в README.

### 2) Наблюдаемость и операционка
- Стандартизировать логирование: request id / user id / ключевые события use-case.
- Добавить health/readiness с проверкой БД (опционально отдельный endpoint).
- Зафиксировать prod-runbook: env, миграции, smoke-check после деплоя.

### 3) Гигиена зависимостей и quality gate
- Добавить линтер/форматтер (например, `ruff` + `black`) и базовый конфиг.
- Добавить pre-commit или CI-шаг на lint + tests.
- Проверить неиспользуемые зависимости в `requirements.txt`.

Критерий готовности итерации:
- Проект проверяется автоматически (`lint + tests`) и имеет предсказуемый runtime-конфиг.

---

## Приоритет выполнения (если времени мало)
1. `runs.py` и `auth.py` -> сервисы/репозитории.
2. Fail-fast по `jwt_secret` + CORS.
3. Тесты auth/run happy-path и ошибки.
4. Остальное из итерации 2.
