# Переключение между локальной и облачной БД

## Схема

| Режим | APP_ENV | Файл с DATABASE_URL | БД |
|-------|---------|---------------------|-----|
| Разработка | `local` (по умолчанию) | `.env.local` | Локальный PostgreSQL |
| Релиз | `release` | `.env.release` | Yandex Managed PostgreSQL |

## Настройка

1. Создай файлы (в `python_backend/`):

```bash
cp env.example .env
cp env.example.local .env.local
cp env.example.release .env.release
```

2. Заполни `.env.local` — твой локальный `DATABASE_URL`.

3. Заполни `.env.release` — URL облачной БД из консоли Yandex Cloud.

## Запуск

Удобнее всего выбирать БД при запуске скриптом `run.sh`:

**Разработка (локальная БД):**
```bash
./run.sh
# или явно
./run.sh local
```

**Релиз (облачная БД):**
```bash
./run.sh release
```

Через uvicorn напрямую:
```bash
# локальная (по умолчанию)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# облачная
APP_ENV=release uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Проверка

`GET /health` возвращает `{"ok": true, "env": "local"}` или `"env": "release"` — текущий режим.

## Важно

- `APP_ENV` задаётся **переменной окружения** при запуске, не в `.env`.
- Файлы `.env`, `.env.local`, `.env.release` в `.gitignore` — не коммить секреты.
