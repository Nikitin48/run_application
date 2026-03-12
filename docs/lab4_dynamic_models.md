# Лабораторная работа №4

## Дисциплина: «Проектирование автоматизированных систем»

### Тема: «Разработка динамических моделей классового уровня»

---

## Задание кафедры

На основе моделей, созданных на предыдущих этапах, реализовать этап 6. Поскольку на каждом этапе могут быть введены элементы, не имеющие соответствия с элементами моделей предыдущих этапов, то такие новые элементы необходимо выделить.

**Проект:** Run Application — мобильное приложение для трекинга пробежек с элементами геймификации (захват территорий на карте). Стек: Flutter (клиент), FastAPI (backend REST API), PostgreSQL + PostGIS (база данных).

---

## 6.1 Диаграмма кооперации, спецификация диаграммы кооперации

Диаграмма кооперации описывает, как именно объекты системы взаимодействуют при выполнении одного сценария. В отличие от диаграммы последовательности, она акцентирует внимание на структуре связей между объектами и направлениях обмена данными.

### 6.1.1. Кооперация «Авторизация пользователя»

**Сценарий:** Пользователь вводит email и пароль; система проверяет данные через БД и при успехе предоставляет доступ к экрану карты.

```plantuml
@startuml
title Диаграмма кооперации «Авторизация пользователя»

skinparam rectangle {
  BorderColor black
  BackgroundColor white
}
skinparam actorBorderColor black

actor "Пользователь" as User

rectangle "Экран\nавторизации" as Auth
rectangle "БД" as DB
rectangle "Экран карты\n(главная)" as Map

User <-right-> Auth : Вход /\nОшибка входа
Auth <-down-> DB : Отправка учётных\nданных /\nВерные/неверные\nданные
Auth -right-> Map : Доступ

@enduml
```

*Рисунок 1 – Диаграмма кооперации «Авторизация пользователя»*

| Параметр | Значение |
|----------|----------|
| Количество элементов | 4 |
| Количество связей | 3 |
| Топология | Иерархическая |

---

### 6.1.2. Кооперация «Трекинг пробежки»

**Сценарий:** Пользователь запускает пробежку на экране карты; система подписывается на GPS-поток, записывает координаты и обновляет трек на экране в реальном времени.

```plantuml
@startuml
title Диаграмма кооперации «Трекинг пробежки»

skinparam rectangle {
  BorderColor black
  BackgroundColor white
}
skinparam actorBorderColor black

actor "Пользователь" as User

rectangle "Экран карты\n(пробежка)" as Map
rectangle "GPS-служба" as GPS

User <-right-> Map : Запуск пробежки /\nОтображение\nтрека/ошибка
Map <-right-> GPS : Запрос\nкоординат /\nПоток GPS-позиций

@enduml
```

*Рисунок 2 – Диаграмма кооперации «Трекинг пробежки»*

| Параметр | Значение |
|----------|----------|
| Количество элементов | 3 |
| Количество связей | 2 |
| Топология | Линейная |

---

### 6.1.3. Кооперация «Завершение пробежки и захват территории»

**Сценарий:** Пользователь нажимает «Финиш»; данные маршрута отправляются в БД, где вычисляются полигоны захвата; итоги отображаются на экране результатов.

```plantuml
@startuml
title Диаграмма кооперации «Завершение пробежки и захват территории»

skinparam rectangle {
  BorderColor black
  BackgroundColor white
}
skinparam actorBorderColor black

actor "Пользователь" as User

rectangle "Экран\nпробежки" as Run
rectangle "БД\n(PostGIS)" as DB
rectangle "Экран итогов\nпробежки" as Summary

User <-right-> Run : Завершение\nпробежки /\nОшибка отправки
Run <-down-> DB : Отправка маршрута /\nРезультаты захвата\n(площадь, жертвы)
Run -right-> Summary : Отображение\nитогов

@enduml
```

*Рисунок 3 – Диаграмма кооперации «Завершение пробежки и захват территории»*

| Параметр | Значение |
|----------|----------|
| Количество элементов | 4 |
| Количество связей | 3 |
| Топология | Иерархическая |

---

### 6.1.4. Кооперация «Просмотр территорий и уведомлений»

**Сценарий:** Пользователь просматривает карту; система загружает территории для видимой области и проверяет наличие уведомления о захвате территории другим игроком.

```plantuml
@startuml
title Диаграмма кооперации «Просмотр территорий и уведомлений»

skinparam rectangle {
  BorderColor black
  BackgroundColor white
}
skinparam actorBorderColor black

actor "Пользователь" as User

rectangle "Экран карты" as Map
rectangle "БД\n(PostGIS)" as DB

User <-right-> Map : Просмотр карты /\nОтображение\nтерриторий /\nУведомление
Map <-right-> DB : Запрос территорий\nи уведомлений /\nGeoJSON-полигоны\nи данные уведомления

@enduml
```

*Рисунок 4 – Диаграмма кооперации «Просмотр территорий и уведомлений»*

| Параметр | Значение |
|----------|----------|
| Количество элементов | 3 |
| Количество связей | 2 |
| Топология | Линейная |

---

## 6.2 Диаграмма последовательности сообщений, спецификация объектов и сообщений, исходный код

Диаграмма последовательности позволяет показать временную последовательность обмена сообщениями между объектами системы при выполнении конкретного варианта использования. Она иллюстрирует, какие вызовы происходят, в каком порядке и кто их инициирует.

### 6.2.1. Последовательность «Авторизация пользователя»

**Спецификация объектов:**

| Объект | Класс | Описание |
|--------|-------|----------|
| User | Актор | Пользователь приложения |
| LoginPage | StatefulWidget | Экран входа с полями email/пароль |
| AuthController | StateNotifier | Управляет состоянием авторизации |
| AuthApi | Класс | HTTP-клиент для эндпоинтов `/auth` |
| Dio | HttpClient | HTTP-клиент с interceptor'ами |
| AuthRouter | FastAPI Router | Обрабатывает `/auth/login`, `/auth/register`, `/auth/refresh` |
| PostgreSQL | СУБД | Таблицы `users`, `auth_identities`, `refresh_tokens` |
| TokenStorage | Класс | Secure Storage для access/refresh токенов |

**Спецификация сообщений:**

| № | Отправитель → Получатель | Сообщение | Тип |
|---|--------------------------|-----------|-----|
| 1 | User → LoginPage | Ввод email, пароля, нажатие «Войти» | Пользовательское действие |
| 2 | LoginPage → AuthController | login(email, password) | Вызов метода |
| 3 | AuthController → AuthApi | login(LoginRequest) | Async вызов |
| 4 | AuthApi → Dio | POST /auth/login | HTTP запрос |
| 5 | Dio → AuthRouter | HTTP POST {email, password} | Сетевой вызов |
| 6 | AuthRouter → PostgreSQL | SELECT … FROM auth_identities | SQL запрос |
| 7 | PostgreSQL → AuthRouter | user_id, password_hash | Результат |
| 8 | AuthRouter → AuthRouter | verify_password(password, hash) | Внутренний вызов |
| 9 | AuthRouter → PostgreSQL | INSERT INTO refresh_tokens | SQL запрос |
| 10 | AuthRouter → Dio | AuthResponse {access_token, refresh_token} | HTTP ответ |
| 11 | Dio → AuthApi | AuthResponse | Ответ |
| 12 | AuthApi → AuthController | AuthResponse | Возврат |
| 13 | AuthController → TokenStorage | saveTokens(access, refresh) | Вызов метода |
| 14 | AuthController → LoginPage | state = authenticated | Уведомление |

```plantuml
@startuml
title Последовательность «Авторизация пользователя»

actor User as "Пользователь"
participant LP as "LoginPage"
participant AC as "AuthController"
participant API as "AuthApi"
participant Dio as "Dio"
participant AR as "AuthRouter\n(FastAPI)"
database DB as "PostgreSQL"
participant TS as "TokenStorage"

User -> LP: ввод email, пароля, нажатие «Войти»
activate LP

LP -> AC: login(email, password)
activate AC

AC -> API: login(LoginRequest)
activate API

API -> Dio: POST /auth/login
activate Dio

Dio -> AR: HTTP POST {email, password}
activate AR

AR -> DB: SELECT user_id, password_hash\nFROM auth_identities\nWHERE provider='email'\nAND identifier=email
activate DB
DB --> AR: user_id, password_hash
deactivate DB

AR -> AR: verify_password(password, hash)

alt пароль верный
  AR -> DB: INSERT INTO refresh_tokens\n(user_id, token_hash, expires_at)
  activate DB
  DB --> AR: OK
  deactivate DB

  AR -> AR: create_access_token(user_id)

  AR --> Dio: 200 OK\n{access_token, refresh_token, access_expires_at}
  deactivate AR

  Dio --> API: AuthResponse
  deactivate Dio

  API --> AC: AuthResponse
  deactivate API

  AC -> TS: saveTokens(access, refresh)
  AC --> LP: state = authenticated
  deactivate AC

  LP --> User: Переход на экран карты
  deactivate LP

else пароль неверный
  AR --> Dio: 401 Unauthorized
  Dio --> API: HttpException
  API --> AC: ошибка
  AC --> LP: state = error
  LP --> User: «Неверный email или пароль»
end

@enduml
```

*Рисунок 5 – Диаграмма последовательности «Авторизация пользователя»*

**Фрагмент исходного кода backend (auth.py):**

```python
@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, request: Request) -> AuthResponse:
    email = payload.email.strip().lower()
    refresh = new_refresh_token()
    refresh_hash = refresh_token_hash(refresh)
    refresh_expires_at = int(time.time()) + settings.refresh_token_ttl_seconds

    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT u.id, ai.password_hash, u.is_banned "
                "FROM auth_identities ai JOIN users u ON u.id = ai.user_id "
                "WHERE ai.provider = 'email' AND ai.identifier = %s",
                (email,),
            )
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=401, detail="invalid credentials")

            user_id, pw_hash, is_banned = row
            if not verify_password(payload.password, pw_hash):
                raise HTTPException(status_code=401, detail="invalid credentials")

            cur.execute(
                "INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip) "
                "VALUES (%s, %s, to_timestamp(%s), %s, %s)",
                (user_id, refresh_hash, refresh_expires_at,
                 request.headers.get("user-agent"),
                 request.client.host if request.client else None),
            )

    access = create_access_token(user_id=str(user_id))
    return AuthResponse(
        access_token=access.token,
        access_expires_at=access.expires_at,
        refresh_token=refresh,
    )
```

---

### 6.2.2. Последовательность «Трекинг пробежки»

**Спецификация объектов:**

| Объект | Класс | Описание |
|--------|-------|----------|
| User | Актор | Пользователь |
| MapPage | StatefulWidget | Экран карты с кнопкой старта |
| RunTrackerController | StateNotifier | Управляет жизненным циклом пробежки |
| Geolocator | SDK | Поток GPS-координат |
| ConnectivityPlus | SDK | Мониторинг интернет-соединения |

**Спецификация сообщений:**

| № | Отправитель → Получатель | Сообщение | Тип |
|---|--------------------------|-----------|-----|
| 1 | User → MapPage | Нажатие «Начать пробежку» | Действие |
| 2 | MapPage → RunTrackerController | start() | Вызов метода |
| 3 | RunTrackerController → RunTrackerController | countdown(3 секунды) | Таймер |
| 4 | RunTrackerController → Geolocator | getPositionStream(accuracy: best, interval: 800ms) | Подписка |
| 5 | RunTrackerController → ConnectivityPlus | onConnectivityChanged | Подписка |
| 6 | Geolocator → RunTrackerController | Position(lat, lng, accuracy, speed, ts) | Событие (loop) |
| 7 | RunTrackerController → RunTrackerController | addPoint() / createPause(gps_lost) | Внутренний |
| 8 | RunTrackerController → MapPage | state update (distance, elapsed, track) | Уведомление |

```plantuml
@startuml
title Последовательность «Трекинг пробежки»

actor User as "Пользователь"
participant MP as "MapPage"
participant RTC as "RunTrackerController"
participant Geo as "Geolocator\n(GPS SDK)"
participant Conn as "ConnectivityPlus"

User -> MP: нажимает «Начать пробежку»
activate MP
MP -> RTC: start()
activate RTC

RTC -> RTC: state = countdown (3 с)
RTC --> MP: показать обратный отсчёт
... 3 секунды ...

RTC -> Geo: getPositionStream(\naccuracy: best,\ninterval: 800ms)
activate Geo

RTC -> Conn: onConnectivityChanged
activate Conn

RTC -> RTC: state = running

loop Пока пробежка активна
  Geo --> RTC: Position(lat, lng,\naccuracy, speed, ts)

  alt accuracy <= 35 м
    RTC -> RTC: addPoint(lat, lng, ts)\nобновить дистанцию
    RTC --> MP: обновить трек,\nдистанцию, время
    MP --> User: UI обновлён
  else accuracy > 35 м
    RTC -> RTC: createPause(gps_lost)
    RTC --> MP: показать индикатор\nпотери GPS
  end
end

opt Потеря интернета
  Conn --> RTC: connectivity = none
  RTC -> RTC: createPause(internet_lost)
  RTC --> MP: показать индикатор\nпотери сети
end

opt Ручная пауза
  User -> MP: нажимает «Пауза»
  MP -> RTC: pause()
  RTC -> RTC: createPause(manual)
  RTC --> MP: state = paused
end

deactivate Conn
deactivate Geo
deactivate RTC
deactivate MP

@enduml
```

*Рисунок 6 – Диаграмма последовательности «Трекинг пробежки»*

**Фрагмент исходного кода Flutter (run_tracker_controller.dart) — логика старта и записи точек:**

```dart
Future<void> start() async {
  state = state.copyWith(phase: RunPhase.countdown);
  for (var i = 3; i > 0; i--) {
    state = state.copyWith(countdownValue: i);
    await Future.delayed(const Duration(seconds: 1));
  }
  state = state.copyWith(phase: RunPhase.running);
  _startGpsStream();
  _startConnectivityMonitor();
}

void _onPosition(Position pos) {
  if (pos.accuracy > 35) {
    _createPause(PauseReason.gpsLost);
    return;
  }
  _resumeIfAutoPaused(PauseReason.gpsLost);
  final point = TrackPoint(lat: pos.latitude, lng: pos.longitude, ...);
  _points.add(point);
  _updateDistance(point);
  state = state.copyWith(points: _points, distance: _totalDistance);
}
```

---

### 6.2.3. Последовательность «Завершение пробежки и захват территории»

**Спецификация объектов:**

| Объект | Класс | Описание |
|--------|-------|----------|
| User | Актор | Пользователь |
| RunOverlay | Widget | Оверлей с кнопками управления пробежкой |
| RunTrackerController | StateNotifier | Контроллер активности |
| RunsApi | Класс | HTTP-клиент для `/runs` |
| RunsRouter | FastAPI Router | Обработка `/runs/finish` |
| PostgreSQL+PostGIS | СУБД | Хранение данных, пространственные вычисления |
| RunSummaryPage | StatelessWidget | Экран итогов пробежки |

**Спецификация сообщений:**

| № | Отправитель → Получатель | Сообщение | Тип |
|---|--------------------------|-----------|-----|
| 1 | User → RunOverlay | Нажатие «Финиш» | Действие |
| 2 | RunOverlay → RunTrackerController | finish() | Вызов |
| 3 | RunTrackerController → RunTrackerController | closeOpenPauses(), buildRequest() | Внутренний |
| 4 | RunTrackerController → RunsApi | POST /runs/finish (RunFinishRequest) | Async |
| 5 | RunsApi → RunsRouter | HTTP POST | Сетевой |
| 6 | RunsRouter → RunsRouter | haversine_m(), wkt_linestring() | Внутренний |
| 7 | RunsRouter → PostgreSQL+PostGIS | INSERT INTO runs, run_points, run_pauses | SQL |
| 8 | RunsRouter → PostgreSQL+PostGIS | SELECT finalize_run_capture(run_id) | SQL (функция) |
| 9 | PostgreSQL+PostGIS → PostgreSQL+PostGIS | compute_capture_polygons(), ST_Union, ST_Difference | PostGIS |
| 10 | PostgreSQL+PostGIS → RunsRouter | capture_area_m2, victims_count | Результат |
| 11 | RunsRouter → RunsApi | RunFinishResponse | HTTP ответ |
| 12 | RunsApi → RunTrackerController | RunFinishResponse | Возврат |
| 13 | RunTrackerController → RunSummaryPage | Открытие экрана итогов | Навигация |

```plantuml
@startuml
title Последовательность «Завершение пробежки и захват территории»

actor User as "Пользователь"
participant RO as "RunOverlay"
participant RTC as "RunTrackerController"
participant RAPI as "RunsApi"
participant RR as "RunsRouter\n(FastAPI)"
database DB as "PostgreSQL\n+ PostGIS"
participant RSP as "RunSummaryPage"

User -> RO: нажимает «Финиш»
activate RO
RO -> RTC: finish()
activate RTC

RTC -> RTC: closeOpenPauses()\nbuildRunFinishRequest()
RTC -> RTC: state = finishing

RTC -> RAPI: POST /runs/finish\n(points, pauses, started_at, ended_at)
activate RAPI

RAPI -> RR: HTTP POST (RunFinishRequest)
activate RR

RR -> RR: haversine_m() → distance_m\nwkt_linestring() → track_wkt

RR -> DB: INSERT INTO runs\n(user_id, track_line, distance_m, …)
activate DB
DB --> RR: run_id
deactivate DB

RR -> DB: INSERT INTO run_points\n(run_id, seq, lat, lng, …)
RR -> DB: INSERT INTO run_pauses\n(run_id, started_at, ended_at, reason)

RR -> DB: SELECT capture_area_m2, victims_count\nFROM finalize_run_capture(run_id)
activate DB


DB --> RR: capture_area_m2 = 1250.5,\nvictims_count = 2
deactivate DB

RR -> DB: UPDATE runs SET capture_area_m2, victims_count

RR --> RAPI: RunFinishResponse
deactivate RR

RAPI --> RTC: RunFinishResponse
deactivate RAPI

RTC -> RSP: navigate(RunSummaryPage,\n{distance, elapsed, capture_area, victims})
activate RSP

RSP --> User: Экран итогов:\nдистанция, время, захват, жертвы
deactivate RSP

deactivate RTC
deactivate RO

@enduml
```

*Рисунок 7 – Диаграмма последовательности «Завершение пробежки и захват территории»*

**Фрагмент исходного кода backend (runs.py):**

```python
@router.post("/finish", response_model=RunFinishResponse)
def finish_run(payload: RunFinishRequest, user_id: str = Depends(current_user_id)):
    # ... расчёт дистанции и формирование track_wkt ...
    track_wkt = wkt_linestring(coords)
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO runs (user_id, status, started_at, ended_at, "
                "distance_m, elapsed_s, paused_s, moving_s, points, track_line) "
                "VALUES (%s, 'finished', %s, %s, %s, %s, %s, %s, %s, "
                "ST_SetSRID(ST_GeomFromText(%s), 4326)) RETURNING id",
                (user_id, payload.started_at, payload.ended_at,
                 float(distance_m), elapsed_s, paused_s, moving_s,
                 points_jsonb, track_wkt),
            )
            run_id = cur.fetchone()[0]
            # ... insert run_points, run_pauses ...
            cur.execute(
                "SELECT capture_area_m2, victims_count "
                "FROM finalize_run_capture(%s)", (run_id,))
            cap_area, victims = cur.fetchone()
    return RunFinishResponse(run_id=str(run_id), distance_m=float(distance_m),
                             capture_area_m2=float(cap_area), victims_count=int(victims), ...)
```

---

### 6.2.4. Последовательность «Просмотр территорий и уведомлений»

**Спецификация объектов:**

| Объект | Класс | Описание |
|--------|-------|----------|
| User | Актор | Пользователь |
| MapPage | StatefulWidget | Экран карты |
| TerritoriesController | StateNotifier | Загрузка территорий по bbox |
| TerritoriesApi | Класс | HTTP-клиент для `/territories` |
| TerritoriesRouter | FastAPI Router | Обработка `/territories` |
| LastNotificationProvider | Provider | Провайдер последнего уведомления |
| NotificationsRouter | FastAPI Router | Обработка `/notifications/last` |
| PostgreSQL+PostGIS | СУБД | Территории и уведомления |

```plantuml
@startuml
title Последовательность «Просмотр территорий и уведомлений»

actor User as "Пользователь"
participant MP as "MapPage"
participant TC as "TerritoriesController"
participant TAPI as "TerritoriesApi"
participant TR as "TerritoriesRouter\n(FastAPI)"
participant LNP as "LastNotificationProvider"
participant NR as "NotificationsRouter\n(FastAPI)"
database DB as "PostgreSQL\n+ PostGIS"

User -> MP: прокрутка / масштабирование карты
activate MP

MP -> TC: loadForBbox(minLng, minLat, maxLng, maxLat)
activate TC

TC -> TAPI: GET /territories?minLng=…&minLat=…&maxLng=…&maxLat=…
activate TAPI

TAPI -> TR: HTTP GET
activate TR

TR -> DB: SELECT user_id, territory_color,\nST_AsGeoJSON(geom), ST_Area(...)\nFROM territories\nWHERE ST_Intersects(geom, ST_MakeEnvelope(...))
activate DB
DB --> TR: rows (user_id, color, geojson, area_m2)
deactivate DB

TR --> TAPI: FeatureCollection {features: [...]}
deactivate TR

TAPI --> TC: List<Territory>
deactivate TAPI

TC --> MP: отрисовать цветные полигоны на карте
deactivate TC

MP --> User: Карта с территориями

par Параллельная загрузка уведомления
  MP -> LNP: getLastNotification()
  activate LNP

  LNP -> NR: GET /notifications/last
  activate NR

  NR -> DB: SELECT kind, attacker_user_id,\nstolen_area_m2, created_at\nFROM user_last_notification\nWHERE user_id = %s
  activate DB
  DB --> NR: уведомление или NULL
  deactivate DB

  NR --> LNP: {has_notification: true,\nstolen_area_m2: 320.5, ...}
  deactivate NR

  LNP --> MP: показать баннер:\n«Игрок X захватил 320 м² вашей территории»
  deactivate LNP

  MP --> User: баннер уведомления
end

deactivate MP

@enduml
```

*Рисунок 8 – Диаграмма последовательности «Просмотр территорий и уведомлений»*

**Фрагмент исходного кода backend (territories.py):**

```python
@router.get("")
def get_territories(
    min_lng: float = Query(..., alias="minLng"),
    min_lat: float = Query(..., alias="minLat"),
    max_lng: float = Query(..., alias="maxLng"),
    max_lat: float = Query(..., alias="maxLat"),
) -> dict:
    with db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.user_id::text, u.territory_color, "
                "ST_AsGeoJSON(t.geom)::text, "
                "ST_Area(ST_Transform(t.geom, 3857))::double precision "
                "FROM territories t JOIN users u ON u.id = t.user_id "
                "WHERE ST_Intersects(t.geom, ST_MakeEnvelope(%s,%s,%s,%s,4326))",
                (min_lng, min_lat, max_lng, max_lat),
            )
            features = [{"type": "Feature",
                         "geometry": json.loads(geojson),
                         "properties": {"user_id": uid, "territory_color": color,
                                        "area_m2": area}}
                        for uid, color, geojson, area in cur.fetchall()]
    return {"type": "FeatureCollection", "features": features}
```

---

## 6.3 Диаграмма состояний классов системы, спецификация состояний и переходов, исходный код

Диаграмма состояний описывает жизненный цикл одного конкретного класса, фиксируя, какие состояния он может принимать, события, запускающие переходы между состояниями, и действия, выполняемые при входе/выходе из них.

### 6.3.1. Состояния класса AuthController

**Описание:** `AuthController` (Flutter, StateNotifier) управляет состоянием аутентификации пользователя: от начального экрана входа до авторизованного состояния.

**Спецификация состояний:**

| Состояние | Описание | Действие при входе |
|-----------|----------|--------------------|
| Initial | Проверка наличия сохранённых токенов | Чтение TokenStorage |
| Unauthenticated | Токены отсутствуют или невалидны | Показать экран входа |
| Authenticating | Выполняется запрос login/register | Показать индикатор загрузки |
| Authenticated | Успешная авторизация, токены сохранены | Перейти на карту |
| AuthError | Ошибка авторизации | Показать сообщение об ошибке |
| Refreshing | Обновление access-токена через refresh | — (фоновый процесс) |

**Спецификация переходов:**

| Из | В | Событие / Условие | Действие |
|----|---|-------------------|----------|
| [*] | Initial | Запуск приложения | Проверить TokenStorage |
| Initial | Authenticated | Токены найдены и валидны | Инициализировать контекст |
| Initial | Unauthenticated | Токены не найдены | — |
| Unauthenticated | Authenticating | Пользователь нажал «Войти» / «Регистрация» | POST /auth/login или /auth/register |
| Authenticating | Authenticated | 200 OK (AuthResponse) | Сохранить токены |
| Authenticating | AuthError | 401/409/422 | Установить текст ошибки |
| AuthError | Unauthenticated | Пользователь закрыл ошибку | Сбросить ошибку |
| Authenticated | Refreshing | access_token истёк (401) | POST /auth/refresh |
| Refreshing | Authenticated | Новые токены получены | Обновить TokenStorage |
| Refreshing | Unauthenticated | Refresh провалился | Очистить TokenStorage |
| Authenticated | Unauthenticated | Пользователь нажал «Выйти» | Очистить TokenStorage |

```plantuml
@startuml
title Диаграмма состояний класса AuthController

hide empty description
skinparam state {
  BackgroundColor White
  BorderColor Black
}

[*] --> Initial : запуск приложения

state Initial : entry / читать TokenStorage

Initial --> Authenticated : [токены найдены\nи валидны]
Initial --> Unauthenticated : [токены не найдены]

state Unauthenticated : entry / показать LoginPage

Unauthenticated --> Authenticating : login(email, password)\nregister(email, password, name)

state Authenticating : entry / POST /auth/login\nили /auth/register\ndo / показать загрузку

Authenticating --> Authenticated : [200 OK]\n/ сохранить токены
Authenticating --> AuthError : [401/409/422]\n/ установить ошибку

state AuthError : entry / показать сообщение

AuthError --> Unauthenticated : dismiss() / сбросить ошибку

state Authenticated : entry / перейти на MapPage

Authenticated --> Refreshing : [access_token истёк, 401]\n/ POST /auth/refresh
Authenticated --> Unauthenticated : logout()\n/ очистить TokenStorage

state Refreshing : entry / POST /auth/refresh

Refreshing --> Authenticated : [200 OK]\n/ обновить токены
Refreshing --> Unauthenticated : [ошибка refresh]\n/ очистить TokenStorage

@enduml
```

*Рисунок 9 – Диаграмма состояний класса AuthController*

---

### 6.3.2. Состояния класса RunTrackerController

**Описание:** `RunTrackerController` (Flutter, StateNotifier) управляет жизненным циклом пробежки: от ожидания старта через обратный отсчёт, активную запись трека, паузы до завершения и отправки результатов.

**Спецификация состояний:**

| Состояние | Описание | Действие при входе |
|-----------|----------|--------------------|
| Idle | Ожидание старта, пробежка не активна | Кнопка «Старт» доступна |
| Countdown | Обратный отсчёт 3 секунды | Таймер 3→2→1 |
| Running | Активная запись GPS-точек | Geolocator stream, таймер |
| Paused | Пауза (ручная / gps_lost / internet_lost) | Запись паузы |
| Finishing | Отправка результатов на сервер | POST /runs/finish |
| Finished | Результаты получены | Открыть RunSummaryPage |
| Error | Ошибка (GPS недоступен / ошибка сервера) | Показать сообщение |

**Спецификация переходов:**

| Из | В | Событие | Действие |
|----|---|---------|----------|
| [*] | Idle | Инициализация | — |
| Idle | Countdown | start() при доступном GPS | Запуск отсчёта 3 с |
| Idle | Error | start() при недоступном GPS | Показать ошибку |
| Countdown | Running | Отсчёт завершён | Подписка на GPS и сеть |
| Countdown | Idle | cancel() | Сброс отсчёта |
| Running | Paused | pause(manual) | Создать ручную паузу |
| Running | Paused | accuracy > 35 м | Создать паузу gps_lost |
| Running | Paused | connectivity = none | Создать паузу internet_lost |
| Paused | Running | resume() | Закрыть паузу |
| Paused | Running | accuracy ≤ 35 м | Закрыть auto-паузу |
| Paused | Running | connectivity восстановлена | Закрыть auto-паузу |
| Running | Finishing | finish() | Закрыть паузы, POST /runs/finish |
| Paused | Finishing | finish() | Закрыть паузы, POST /runs/finish |
| Finishing | Finished | 200 OK | Сохранить RunFinishResponse |
| Finishing | Error | Ошибка сервера | Показать ошибку |
| Error | Running | retry() | Восстановить активную фазу |
| Finished | Idle | done() | Сброс всех данных |

```plantuml
@startuml
title Диаграмма состояний класса RunTrackerController

hide empty description
skinparam state {
  BackgroundColor White
  BorderColor Black
}

[*] --> Idle

state Idle : entry / кнопка «Старт» активна

Idle --> Countdown : start()\n[GPS доступен]\n/ запустить отсчёт 3 с
Idle --> Error : start()\n[GPS недоступен]\n/ показать причину

state Countdown : entry / таймер 3→2→1
Countdown --> Running : [отсчёт завершён]\n/ подписка на GPS stream\nи connectivity monitor
Countdown --> Idle : cancel()\n/ сброс отсчёта

state Running : entry / запись точек\ndo / addPoint на каждую GPS-позицию

Running --> Paused : pause(manual)\n/ создать ручную паузу
Running --> Paused : [accuracy > 35 м]\n/ создать паузу gps_lost
Running --> Paused : [connectivity = none]\n/ создать паузу internet_lost
Running --> Finishing : finish()\n/ закрыть паузы,\nсобрать RunFinishRequest

state Paused : entry / приостановить запись точек

Paused --> Running : resume()\n/ закрыть паузу
Paused --> Running : [accuracy ≤ 35 м]\n/ закрыть auto-паузу
Paused --> Running : [connectivity восстановлена]\n/ закрыть auto-паузу
Paused --> Finishing : finish()\n/ закрыть паузы,\nотправить данные

state Finishing : entry / POST /runs/finish

Finishing --> Finished : [200 OK]\n/ сохранить RunFinishResponse
Finishing --> Error : [ошибка сервера]\n/ показать сообщение

state Finished : entry / открыть RunSummaryPage
Finished --> Idle : done()\n/ сброс данных пробежки

state Error : entry / показать ошибку
Error --> Running : retry()\n/ восстановить запись

@enduml
```

*Рисунок 10 – Диаграмма состояний класса RunTrackerController*

---

### 6.3.3. Состояния класса TerritoriesController

**Описание:** `TerritoriesController` (Flutter, StateNotifier) управляет загрузкой и отображением территорий на карте при изменении области просмотра (bounding box).

**Спецификация состояний:**

| Состояние | Описание | Действие при входе |
|-----------|----------|--------------------|
| Empty | Территории не загружены | — |
| Loading | Выполняется запрос GET /territories | Показать индикатор |
| Loaded | Территории получены и отрисованы | Отобразить полигоны |
| Error | Ошибка загрузки | Показать ошибку |

**Спецификация переходов:**

| Из | В | Событие | Действие |
|----|---|---------|----------|
| [*] | Empty | Инициализация | — |
| Empty | Loading | onMapMove(bbox) | GET /territories?minLng=…&… |
| Loading | Loaded | 200 OK (FeatureCollection) | Преобразовать в полигоны |
| Loading | Error | Ошибка сети / сервера | Установить ошибку |
| Loaded | Loading | onMapMove(newBbox) | Новый GET /territories |
| Error | Loading | retry() / onMapMove(bbox) | Повторить запрос |

```plantuml
@startuml
title Диаграмма состояний класса TerritoriesController

hide empty description
skinparam state {
  BackgroundColor White
  BorderColor Black
}

[*] --> Empty

state Empty : Территории не загружены

Empty --> Loading : onMapMove(bbox)\n/ GET /territories

state Loading : entry / выполнить запрос\ndo / показать индикатор

Loading --> Loaded : [200 OK]\n/ преобразовать GeoJSON\nв полигоны на карте
Loading --> Error : [ошибка сети/сервера]\n/ установить текст ошибки

state Loaded : entry / отрисовать полигоны

Loaded --> Loading : onMapMove(newBbox)\n/ GET /territories\nдля нового bbox
Loaded --> Loaded : [тот же bbox]\n/ игнорировать

state Error : entry / показать ошибку

Error --> Loading : retry()\n/ повторить запрос
Error --> Loading : onMapMove(bbox)\n/ новый запрос

@enduml
```

*Рисунок 11 – Диаграмма состояний класса TerritoriesController*

---

### 6.3.4. Состояния класса ProfileActionsController

**Описание:** `ProfileActionsController` (Flutter, StateNotifier) управляет состояниями профиля пользователя: загрузка данных, редактирование имени и аватара, изменение цвета территории, смена пароля.

**Спецификация состояний:**

| Состояние | Описание | Действие при входе |
|-----------|----------|--------------------|
| Initial | Профиль не загружен | — |
| Loading | Загрузка данных профиля | GET /me/profile |
| Loaded | Данные профиля получены | Отобразить профиль |
| Saving | Сохранение изменений | PATCH /me/profile или /me/territory-color |
| ChangingPassword | Выполняется смена пароля | PATCH /me/password |
| Error | Ошибка загрузки или сохранения | Показать ошибку |

**Спецификация переходов:**

| Из | В | Событие | Действие |
|----|---|---------|----------|
| [*] | Initial | Инициализация | — |
| Initial | Loading | Вкладка «Профиль» выбрана | GET /me/profile |
| Loading | Loaded | 200 OK | Показать профиль |
| Loading | Error | Ошибка | Показать ошибку |
| Loaded | Saving | saveProfile(displayName, avatarUrl) | PATCH /me/profile |
| Loaded | Saving | saveColor(color) | PATCH /me/territory-color |
| Loaded | ChangingPassword | changePassword(old, new) | PATCH /me/password |
| Saving | Loaded | 200 OK | Показать успех, обновить данные |
| Saving | Error | Ошибка | Показать ошибку |
| ChangingPassword | Loaded | 200 OK | Показать успех, очистить поля |
| ChangingPassword | Error | Ошибка | Показать ошибку |
| Error | Loading | retry() / pull-to-refresh | Повторить загрузку |
| Loaded | Loading | pull-to-refresh | Перезагрузить профиль |

```plantuml
@startuml
title Диаграмма состояний класса ProfileActionsController

hide empty description
skinparam state {
  BackgroundColor White
  BorderColor Black
}

[*] --> Initial

state Initial : Профиль не загружен

Initial --> Loading : openProfileTab()\n/ GET /me/profile

state Loading : entry / выполнить запрос\ndo / показать скелетон

Loading --> Loaded : [200 OK]\n/ показать профиль
Loading --> Error : [ошибка сети]\n/ установить ошибку

state Loaded : entry / отобразить\nимя, аватар, цвет, статистику

Loaded --> Saving : saveProfile(displayName, avatarUrl)\n/ PATCH /me/profile
Loaded --> Saving : saveColor(color)\n/ PATCH /me/territory-color
Loaded --> ChangingPassword : changePassword(old, new)\n/ PATCH /me/password
Loaded --> Loading : pull-to-refresh\n/ перезагрузить

state Saving : entry / отправить изменения

Saving --> Loaded : [200 OK]\n/ показать уведомление,\nобновить данные
Saving --> Error : [ошибка]\n/ показать ошибку

state ChangingPassword : entry / PATCH /me/password

ChangingPassword --> Loaded : [200 OK]\n/ «Пароль изменён»,\nочистить поля
ChangingPassword --> Error : [ошибка]\n/ показать ошибку

state Error : entry / показать сообщение

Error --> Loading : retry()\n/ повторить загрузку

@enduml
```

*Рисунок 12 – Диаграмма состояний класса ProfileActionsController*

---

## 6.4 Диаграмма активности (activity diagram)

Диаграмма активности описывает алгоритм или поток управления внутри метода или процесса.

### 6.4.1. Активность «Авторизация пользователя»

```plantuml
@startuml
title Активность «Авторизация пользователя»

start

:Пользователь открывает экран входа;

:Ввод email и пароля;

:Нажатие «Войти»;

:AuthController.login(email, password);

:AuthApi → POST /auth/login;

:AuthRouter: SELECT password_hash
FROM auth_identities
WHERE provider='email' AND identifier=email;

if (Пользователь найден?) then (нет)
  :Вернуть 401 «invalid credentials»;
  :Показать ошибку на экране;
  stop
else (да)
endif

:verify_password(password, hash);

if (Пароль верный?) then (нет)
  :Вернуть 401 «invalid credentials»;
  :Показать ошибку на экране;
  stop
else (да)
endif

if (is_banned = true?) then (да)
  :Вернуть 403 «user banned»;
  :Показать ошибку на экране;
  stop
else (нет)
endif

if (password_hash_needs_update?) then (да)
  :UPDATE auth_identities
  SET password_hash = argon2(password);
else (нет)
endif

:new_refresh_token() → refresh;
:refresh_token_hash(refresh) → hash;
:INSERT INTO refresh_tokens
(user_id, token_hash, expires_at);

:create_access_token(user_id) → access;

:Вернуть AuthResponse
{access_token, refresh_token, access_expires_at};

:AuthController: сохранить токены
в TokenStorage;

:Переход на экран карты;

stop

@enduml
```

*Рисунок 13 – Диаграмма активности «Авторизация пользователя»*

---

### 6.4.2. Активность «Трекинг пробежки»

```plantuml
@startuml
title Активность «Трекинг пробежки»

start

:Пользователь нажимает «Начать пробежку»;

:RunTrackerController.start();

:Проверить доступность GPS;

if (GPS доступен?) then (нет)
  :Показать ошибку «GPS недоступен»;
  stop
else (да)
endif

:Обратный отсчёт 3 → 2 → 1;

if (Пользователь отменил старт?) then (да)
  :Сбросить обратный отсчёт;
  stop
else (нет)
endif

:state = Running;
:Подписка на Geolocator.getPositionStream();
:Подписка на ConnectivityPlus;

while (Пользователь не нажал «Финиш»?) is (да)
  :Получить Position от GPS;

  if (accuracy > 35 м?) then (да)
    :createPause(gps_lost);
    :state = Paused;
  else (нет)
    if (connectivity = none?) then (да)
      :createPause(internet_lost);
      :state = Paused;
    else (нет)
      :addPoint(lat, lng, ts);
      :Обновить дистанцию (haversine);
      :Обновить UI (трек, дистанция, время);
    endif
  endif

  if (state = Paused И условие устранено?) then (да)
    :closePause();
    :state = Running;
  else (нет)
  endif
endwhile (нет)

:Закрыть открытые паузы;
:Собрать RunFinishRequest
(points, pauses, started_at, ended_at);

stop

@enduml
```

*Рисунок 14 – Диаграмма активности «Трекинг пробежки»*

---

### 6.4.3. Активность «Завершение пробежки и захват территории»

```plantuml
@startuml
title Активность «Завершение пробежки и захват территории»

start

:RunTrackerController.finish();
:Отправить POST /runs/finish
(points, pauses, started_at, ended_at);

:RunsRouter: валидация
ended_at > started_at;

if (Данные валидны?) then (нет)
  :Вернуть 422 «ended_at must be after started_at»;
  stop
else (да)
endif

:Рассчитать distance_m
(haversine для каждой пары точек);

:Построить WKT LineString из координат;

if (Менее 2 точек?) then (да)
  :Вернуть RunFinishResponse
  с нулевыми capture и victims;
  stop
else (нет)
endif

:INSERT INTO runs
(user_id, track_line, distance_m, …);
:run_id = RETURNING id;

:INSERT INTO run_points
(для каждой точки);

:INSERT INTO run_pauses
(для каждой паузы);

:SELECT finalize_run_capture(run_id);

fork
  :compute_capture_polygons(track_line,
  tolerance=10м, min_area=150м²);
  note right
    ST_Transform → EPSG:3857
    ST_Snap → замкнуть контуры
    ST_Node → разбить на сегменты
    ST_Polygonize → полигоны
    Фильтр по площади ≥ 150 м²
    ST_Transform → EPSG:4326
  end note
fork again
  :Определить пострадавших
  (ST_Intersects с территориями
  других пользователей);
end fork

:Для каждой жертвы:
ST_Difference → вырезать территорию;

:Для бегуна:
ST_Union → добавить к территории;

:UPDATE user_stats
(площадь, количество пробежек);

:INSERT user_last_notification
для каждой жертвы;

:UPDATE runs SET capture_area_m2,
victims_count;

:Вернуть RunFinishResponse
{run_id, distance_m, capture_area_m2,
victims_count, elapsed_s, …};

:Открыть экран итогов RunSummaryPage;

stop

@enduml
```

*Рисунок 15 – Диаграмма активности «Завершение пробежки и захват территории»*

---

### 6.4.4. Активность «Просмотр территорий и уведомлений»

```plantuml
@startuml
title Активность «Просмотр территорий и уведомлений»

start

:Пользователь прокручивает
или масштабирует карту;

:MapPage: определить новый bbox
(minLng, minLat, maxLng, maxLat);

fork
  :TerritoriesController.loadForBbox(bbox);

  :GET /territories?minLng=…&minLat=…
  &maxLng=…&maxLat=…;

  :TerritoriesRouter: SELECT user_id,
  territory_color, ST_AsGeoJSON(geom),
  ST_Area(ST_Transform(geom, 3857))
  FROM territories
  WHERE ST_Intersects(geom,
  ST_MakeEnvelope(bbox, 4326));

  if (Территории найдены?) then (да)
    :Сформировать FeatureCollection
    {type, features: [{geometry, properties}]};
  else (нет)
    :Вернуть пустой FeatureCollection;
  endif

  :Отрисовать цветные полигоны
  на карте (flutter_map);

fork again
  :LastNotificationProvider:
  GET /notifications/last;

  :NotificationsRouter: SELECT kind,
  attacker_user_id, stolen_area_m2
  FROM user_last_notification
  WHERE user_id = current_user;

  if (Уведомление есть?) then (да)
    :Показать баннер:
    «Игрок X захватил Y м²
    вашей территории»;
  else (нет)
    :Не показывать баннер;
  endif
end fork

:Пользователь видит карту
с территориями и уведомлением;

stop

@enduml
```

*Рисунок 16 – Диаграмма активности «Просмотр территорий и уведомлений»*

---

## Вопрос к лабораторной работе №4

**Иерархия** — вид структуры, отношения в которой характеризуются состоянием подчинённости и невозможностью существования / функционирования вышестоящих уровней без нижестоящих.

**Пример из проекта Run Application:**

В архитектуре приложения присутствует иерархия зависимостей между слоями:

```
MapPage (UI)
  └── RunTrackerController (логика)
        └── RunsApi (сетевой слой)
              └── Dio + TokenInterceptor (HTTP-клиент)
                    └── FastAPI Backend (сервер)
                          └── PostgreSQL + PostGIS (хранение данных)
```

Вышестоящий уровень (UI — `MapPage`) не может функционировать без нижестоящего (`RunTrackerController`), который в свою очередь зависит от `RunsApi`, и так далее до уровня базы данных. Без PostgreSQL backend не может обработать запрос; без backend клиент не может завершить пробежку; без контроллера UI не может управлять процессом трекинга.

Аналогия с организационной структурой: `MapPage` — начальник управления (даёт команду «начать пробежку»), `RunTrackerController` — начальник отдела (координирует GPS, паузы, отправку), `RunsApi` — сотрудник (выполняет конкретный HTTP-запрос). Ни один вышестоящий уровень не может выполнить свою функцию без нижестоящих.
