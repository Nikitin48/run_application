# FaaS: Yandex Cloud Functions

Облачные функции для Run Application. Сейчас: очистка refresh-токенов.

## token_cleanup

Удаляет из таблицы `refresh_tokens` строки с `expires_at < now()` или `revoked_at IS NOT NULL`. Запуск по расписанию (cron).

- Код: `token_cleanup/handler.py`, точка входа: `handler.handler`
- Документация: [docs/guide/faas_token_cleanup_doc.md](../docs/guide/faas_token_cleanup_doc.md), [docs/guide/faas_token_cleanup_plan.md](../docs/guide/faas_token_cleanup_plan.md)

### Локальная проверка

Из корня проекта, с настроенным `.env` или `.env.release` (те же переменные, что для backend):

```bash
cd faas/token_cleanup
pip install -r requirements.txt

# Экспорт переменных из .env.release (пример для release-БД)
export $(grep -v '^#' ../../python_backend/.env.release | xargs)

# Вызов handler
python -c "
from handler import handler
r = handler({}, None)
print(r)
"
```

Убедись, что в БД есть только тестовые/мёртвые токены, либо используй копию БД.

### Переменные окружения функции

Скопируй один из блоков ниже, подставь вместо `HOST`, `USER`, `PASSWORD` свои данные из консоли Yandex Cloud (Managed PostgreSQL), затем вставляй в консоль функции: каждую строку как «Ключ» = часть до `=`, «Значение» = часть после `=` (или вставь весь блок, если консоль принимает формат `KEY=VALUE`).

**Вариант 1 — одна переменная:**

```
DATABASE_URL=postgresql://USER:PASSWORD@HOST:6432/run_app?sslmode=require
```

**Вариант 2 — по отдельности (удобно править по полям):**

```
DB_HOST=HOST
DB_PORT=6432
DB_NAME=run_app
DB_USER=USER
DB_PASSWORD=PASSWORD
DB_SSLMODE=sslmode=require
```

Файл-шпаргалка: `faas/token_cleanup/env.example`. Для Managed PostgreSQL обязателен `sslmode=require`.

**Если ошибка «password authentication failed»:** пароль в консоли должен совпадать с паролем пользователя БД. Если в пароле есть спецсимволы (`&`, `?`, `` ` ``, `\`, кавычки и т.п.), консоль может их исказить — тогда задай пользователю БД новый пароль без спецсимволов (только буквы/цифры) и укажи его в `DB_PASSWORD`, либо храни пароль в Lockbox и подключай как секрет.

**Если ошибка «Name or service not known» (не резолвится хост):** в среде Cloud Functions DNS для `*.mdb.yandexcloud.net` может быть недоступен. Задай в `DB_HOST` **IP-адрес** кластера вместо имени: консоль Yandex Cloud → Managed Service for PostgreSQL → свой кластер → в карточке указан хост и/или IP. Подставь этот IP в переменную `DB_HOST`. (IP может меняться при пересоздании кластера — тогда обнови значение.)

### Деплой через консоль в браузере

Все шаги делаются в [консоли Yandex Cloud](https://console.yandex.cloud) → каталог → **Serverless** → **Cloud Functions**.

#### 1. Подготовить zip с кодом (локально)

На своей машине в терминале:

```bash
cd faas/token_cleanup
zip -r token_cleanup.zip handler.py requirements.txt
```

Файл `token_cleanup.zip` скачай или перетащи в браузер на шаге 3.

#### 2. Создать функцию

- **Cloud Functions** → **Создать функцию**.
- Имя: `token-cleanup` (или любое, 3–63 символа, латиница/цифры/дефис).
- **Создать**. Откроется карточка функции.

#### 3. Создать версию с кодом

- В блоке **Версии** нажми **Создать версию** (или **Редактировать** у последней версии).
- **Среда выполнения:** Python 3.12 (или актуальный Python 3.x).
- **Способ загрузки кода:** ZIP-архив → **Выбрать файл** → укажи `token_cleanup.zip`.
- **Точка входа:** `handler.handler` (модуль `handler`, функция `handler`).
- **Таймаут:** 30 сек. **Память:** 128 МБ.
- **Переменные окружения** — см. блоки выше («Переменные окружения функции»). Нажми **Добавить переменную** и вставляй по одной строке: ключ = имя переменной, значение = часть после `=`.
- **Создать версию**.

#### 4. Проверить вызов вручную

- На странице функции нажми **Запустить тест** / **Вызвать** (если есть кнопка тестового вызова).
- Либо: вкладка **Тестирование** → пустой payload `{}` → **Запустить**.
- Во вкладке **Логи** или в ответе должно быть что-то вроде `{"ok": true, "deleted": N}`. Ошибки подключения к БД будут в логах.

#### 5. Триггер по расписанию

В консоли раздел с триггерами может называться по-разному и находиться в разных местах. Посмотри:

- В левом меню: **Serverless** или **Бессерверные технологии** → пункт вроде **Триггеры** (Triggers). Либо **Cloud Functions** → внутри каталога может быть **Триггеры**.
- Либо на странице своей функции: вкладка **Триггеры** / **Интеграции** и кнопка **Создать триггер** / **Добавить триггер**.

Если такого раздела нет — создай триггер через **CLI** (одна команда, см. ниже).

**Параметры триггера (если создаёшь в консоли):**
- Тип: **Таймер** (Timer).
- Имя: `token-cleanup-daily`.
- Расписание: cron `0 3 * * ? *` (каждый день в 03:00 UTC) или шаблон «Раз в день».
- Функция: `token-cleanup`, версия — последняя.

**Через CLI (если в консоли нет триггеров):**

Установи [YC CLI](https://yandex.cloud/en/docs/cli/quickstart), выполни `yc init`, затем:

```bash
yc serverless trigger create timer \
  --name=token-cleanup-daily \
  --cron-expression="0 3 * * ? *" \
  --invoke-function-name=token-cleanup
```

(Имя функции должно совпадать с тем, что в консоли.) После этого функция будет вызываться по расписанию. Логи: **Cloud Functions** → твоя функция → **Логи** / **Мониторинг**.

---

### Деплой через YC CLI (альтернатива)

Если будешь деплоить всё через CLI:

1. `yc init`, затем создай zip (см. выше).
2. `yc serverless function create --name=token-cleanup --runtime=python312`
3. `yc serverless function version create --function-name=token-cleanup --runtime=python312 --entrypoint=handler.handler --memory=128m --execution-timeout=30s --source-path=token_cleanup.zip --environment="DATABASE_URL=..."`
4. Триггер — команда из шага 5 выше.

Ручной вызов: `yc serverless function invoke token-cleanup`.
