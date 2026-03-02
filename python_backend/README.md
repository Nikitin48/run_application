# Python backend (FastAPI) — отдельный проект в корне репозитория

Минимальный скелет FastAPI для локального API (позже сюда добавим эндпоинты под пробежки/территории).

## Запуск

1) Войти в папку:

```bash
cd python_backend
```

### Требование по версии Python

Используйте **Python 3.11–3.13**. На **Python 3.14** сейчас часто ломается установка `pydantic-core` (FastAPI/Pydantic v2).

2) Создать виртуальное окружение и поставить зависимости:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3) Переменные окружения:

**Разделение local / release (локальная БД vs облачная):**

- `.env` — общие настройки (JWT, порт и т.п.)
- `.env.local` — `DATABASE_URL` для разработки (локальный PostgreSQL)
- `.env.release` — `DATABASE_URL` для релиза (Yandex Managed PostgreSQL)

```bash
cp env.example .env
cp env.example.local .env.local
cp env.example.release .env.release   # заполни после создания облачной БД
```

**Переключение:**

| Режим | Команда | БД |
|-------|---------|-----|
| Разработка | `uvicorn app.main:app --reload` | ` .env.local` (по умолчанию) |
| Релиз | `APP_ENV=release uvicorn app.main:app --reload` | `.env.release` |

`GET /health` возвращает `env: "local"` или `env: "release"` — текущий режим.

4) Запуск сервера:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Проверка:
- `GET /health` → `{"ok": true}`

Если Flutter запускается на **физическом устройстве**, используйте IP вашего Mac в `API_BASE_URL` (см. ниже).

## Auth (email+пароль)

Эндпоинты:
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh` (rotation refresh token)
- `GET /me` (Bearer access token)
- `GET /me/profile` (персональные данные + агрегированная статистика)
- `PATCH /me/profile` (обновление `display_name` и/или `avatar_url`; `email` не изменяется)
- `PATCH /me/password` (смена пароля по текущему паролю)
- `PATCH /me/territory-color` (смена цвета территории пользователя)

Перед запуском примените SQL из `db/` (в корне репозитория): `db/schema.sql`, `db/functions.sql`.

## Runs / Territories

- `POST /runs/finish` — загрузить завершённую пробежку (points + pauses), сохранить в БД и выполнить захват территорий.
- `GET /runs/history?limit&offset` — история пробежек текущего пользователя.
- `GET /territories?minLng&minLat&maxLng&maxLat` — получить территории в bbox (GeoJSON FeatureCollection, включая `territory_color` владельца).
- `GET /notifications/last` — последнее уведомление “у вас отжали” (для текущего пользователя).

Пример (после логина, с `ACCESS_TOKEN`):

```bash
curl -s "http://127.0.0.1:8000/territories?minLng=37.60&minLat=55.74&maxLng=37.63&maxLat=55.76"
curl -s "http://127.0.0.1:8000/notifications/last" -H "Authorization: Bearer ACCESS_TOKEN"
```

## Документация и Swagger

- Swagger UI: `http://127.0.0.1:8000/docs`
- OpenAPI JSON: `http://127.0.0.1:8000/openapi.json`
- Примеры использования API (curl): `python_backend/API_USAGE.md`

## Flutter: доступ к локальному бекенду “везде”

- Android Emulator (по умолчанию): `http://10.0.2.2:8000`
- iOS Simulator (по умолчанию): `http://127.0.0.1:8000`
- Физическое устройство: запускать с
  - `--dart-define=API_BASE_URL=http://<MAC_IP>:8000`







