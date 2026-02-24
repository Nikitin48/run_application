# Backend usage (FastAPI)

## Swagger / OpenAPI

- Swagger UI: `http://127.0.0.1:8000/docs`
- OpenAPI JSON: `http://127.0.0.1:8000/openapi.json`

## Запуск

```bash
cd python_backend
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Если вы запускаете Flutter на **физическом устройстве**, бекенд должен слушать `0.0.0.0`, а приложение должно ходить на IP вашего Mac в Wi‑Fi сети:
- `http://<MAC_IP>:8000`

## Настройки (`.env`)

Минимум:
- `DATABASE_URL` (Postgres)
- `JWT_SECRET`

## Авторизация (email+пароль)

### 1) Register

```bash
curl -s -X POST http://127.0.0.1:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"me@example.com","password":"password123","display_name":"Me"}'
```

### 2) Login

```bash
curl -s -X POST http://127.0.0.1:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"me@example.com","password":"password123"}'
```

Ответ содержит `access_token` и `refresh_token`.

### 3) Me (Bearer)

```bash
curl -s http://127.0.0.1:8000/me \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### 3.1) Профиль + статистика (Bearer)

```bash
curl -s http://127.0.0.1:8000/me/profile \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### 3.2) Сменить цвет территории (Bearer)

```bash
curl -s -X PATCH http://127.0.0.1:8000/me/territory-color \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"territory_color":"#22C55E"}'
```

### 4) Refresh

```bash
curl -s -X POST http://127.0.0.1:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"REFRESH_TOKEN"}'
```

## Территории (карта)

Территории выдаются по bbox:

```bash
curl -s "http://127.0.0.1:8000/territories?minLng=37.60&minLat=55.74&maxLng=37.63&maxLat=55.76"
```

Ответ: GeoJSON `FeatureCollection`.
`properties` каждой зоны содержит: `user_id`, `territory_color`, `area_m2`.

## Пробежка → захват → отжим (finish)

```bash
curl -s -X POST http://127.0.0.1:8000/runs/finish \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "started_at":"2025-12-15T10:00:00Z",
    "ended_at":"2025-12-15T10:10:00Z",
    "points":[
      {"lat":55.75396,"lng":37.620393,"ts":"2025-12-15T10:00:00Z"},
      {"lat":55.75420,"lng":37.62250,"ts":"2025-12-15T10:02:00Z"},
      {"lat":55.75350,"lng":37.62200,"ts":"2025-12-15T10:04:00Z"},
      {"lat":55.75396,"lng":37.620393,"ts":"2025-12-15T10:06:00Z"}
    ],
    "pauses":[]
  }'
```

В ответе:
- `victims_count` — сколько пользователей потеряли пересечение
- `capture_area_m2` — площадь захваченной фигуры

## Последнее уведомление

```bash
curl -s http://127.0.0.1:8000/notifications/last \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

Если уведомлений не было: `{"has_notification": false}`.


