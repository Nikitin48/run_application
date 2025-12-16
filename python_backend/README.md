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

Файл `env.example` — пример. Можно:
- либо экспортировать переменные в shell,
- либо (локально) скопировать в `.env`:

```bash
cp env.example .env
```

4) Запуск сервера:

```bash
uvicorn app.main:app --reload --port 8000
```

Проверка:
- `GET /health` → `{"ok": true}`

## Auth (email+пароль)

Эндпоинты:
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh` (rotation refresh token)
- `GET /me` (Bearer access token)

Перед запуском примените SQL из `db/` (в корне репозитория): `db/schema.sql`, `db/functions.sql`.

## Runs / Territories

- `POST /runs/finish` — загрузить завершённую пробежку (points + pauses), сохранить в БД и выполнить захват территорий.
- `GET /territories?minLng&minLat&maxLng&maxLat` — получить территории в bbox (GeoJSON FeatureCollection).
- `GET /notifications/last` — последнее уведомление “у вас отжали” (для текущего пользователя).

Пример (после логина, с `ACCESS_TOKEN`):

```bash
curl -s "http://127.0.0.1:8000/territories?minLng=37.60&minLat=55.74&maxLng=37.63&maxLat=55.76"
curl -s "http://127.0.0.1:8000/notifications/last" -H "Authorization: Bearer ACCESS_TOKEN"
```







