МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РФ

ФЕДЕРАЛЬНОЕ ГОСУДАРСТВЕННОЕ БЮДЖЕТНОЕ ОБРАЗОВАТЕЛЬНОЕ УЧРЕЖДЕНИЕ ВЫСШЕГО ОБРАЗОВАНИЯ «ЛИПЕЦКИЙ ГОСУДАРСТВЕННЫЙ ТЕХНИЧЕСКИЙ УНИВЕРСИТЕТ»

Институт — компьютерных наук
Кафедра — автоматизированных систем управления

---

# Лабораторная работа №3

по дисциплине «Проектирование автоматизированных систем»

**«Разработка концептуальных статических моделей классового уровня»**

Студент ПИ-22-1 ____________________ Никитин М. С.
                       (подпись, дата)

Профессор ____________________ Ведищев В.В.
                (подпись, дата)

Липецк 2026 г.

---

## Задание кафедры

На основе моделей системы, созданных на предыдущих этапах, реализовать этап 5. Во всех созданных артефактах выделить новые элементы.

Этап 5 Разработка концептуальных статических моделей классового уровня:
- 5.1 Диаграмма пакетов и спецификация пакетов
- 5.2 Классовая диаграмма системы, спецификации классовой диаграммы, классов, атрибутов, операций, отношений между классами, исходный код.
- 5.3 Диаграмма объектов

**Название системы:** Разработка мобильного приложения-трекера пробежек с геймификацией захвата территорий (Run Application)

---

## 5.1 Диаграмма пакетов и спецификация пакетов

Диаграмма пакетов на рисунке 1.

> **[КАРТИНКА]** Рисунок 1 — Диаграмма пакетов. *Вставить рендер `docs/lab3_package_diagram.puml`.*

---

### Спецификация пакетов

**Таблица 1 — Спецификация пакетов**

| Имя | Родительский пакет | Список классов | Список пакетов | Описание |
|-----|--------------------|----------------|----------------|----------|
| FlutterApp | RunApplication | — | App, Core, Auth, Runs, Territories, Profile, Notifications, Histories | Мобильное приложение Flutter — клиентская часть системы |
| App | FlutterApp | RunApp, HomeShellPage | — | Корневой виджет приложения, навигационная оболочка (shell) с нижней панелью, GoRouter |
| Core | FlutterApp | — | Config, Theme, Network, Storage, Utils | Общие инфраструктурные компоненты: конфигурация, тема, сетевой слой, хранилище, утилиты |
| Config | Core | ApiConfig | — | Конфигурация API-сервера (базовый URL) |
| Theme | Core | AppTheme | — | Тема оформления приложения (Material 3) |
| Network | Core | TokenInterceptor, Dio | — | HTTP-клиент Dio с перехватчиком JWT-токенов |
| Storage | Core | TokenStorage | — | Безопасное хранилище JWT-токенов на устройстве |
| Utils | Core | — (утилитарные функции) | — | Вспомогательные функции: форматирование, цвета |
| Auth | FlutterApp | AuthTokens, AuthRepository, AuthRepositoryImpl, AuthApi, LoginUseCase, RegisterUseCase, AuthStatus, AuthState, AuthController, LoginPage | Auth::Domain, Auth::Data, Auth::Application, Auth::Presentation | Аутентификация: вход, регистрация, управление JWT-сессией |
| Runs | FlutterApp | RunPoint, PauseReason, RunPause, FinishRunRequest, FinishRunResponse, RunHistoryItem, RunsRepository, RunsRepositoryImpl, RunsApi, FinishRunUseCase, RunPhase, RunTrackerState, RunTrackerController, RunSummaryPage | Runs::Domain, Runs::Data, Runs::Application, Runs::Presentation | Пробежки: GPS-трекинг, паузы, завершение, отправка на сервер, отображение итогов |
| Territories | FlutterApp | Territory, Bbox, TerritoriesRepository, TerritoriesRepositoryImpl, TerritoriesApi, GetTerritoriesForBboxUseCase, MapPage | Territories::Domain, Territories::Data, Territories::Application, Territories::Presentation | Территории: загрузка и отрисовка полигонов на карте по видимой области (bbox) |
| Profile | FlutterApp | MeProfile, MeProfileStats, ProfileRepository, ProfileRepositoryImpl, ProfileApi, GetMeProfileUseCase, UpdateMeProfileUseCase, UpdateTerritoryColorUseCase, ChangePasswordUseCase, ProfileActionsController, ProfilePage | Profile::Domain, Profile::Data, Profile::Application, Profile::Presentation | Профиль: персональные данные, цвет территории, смена пароля, статистика |
| Notifications | FlutterApp | LastNotification, NotificationsRepository, NotificationsRepositoryImpl, NotificationsApi, GetLastNotificationUseCase | Notifications::Domain, Notifications::Data, Notifications::Application | Уведомления: получение последнего уведомления о захвате территории |
| Histories | FlutterApp | GetRunHistoryUseCase, HistoriesPage | Histories::Domain, Histories::Presentation | История забегов: просмотр списка прошлых пробежек |
| PythonBackend | RunApplication | — | Routers, Models, Security, Settings, Geo | Серверная часть на FastAPI: REST API, бизнес-логика, база данных |
| Routers | PythonBackend | AuthRouter, MeRouter, RunsRouter, TerritoriesRouter, NotificationsRouter | — | REST-контроллеры (роутеры FastAPI) |
| Models | PythonBackend | RegisterRequest, LoginRequest, AuthResponse, RefreshRequest, RunFinishRequest, RunPointIn, RunPauseIn, RunFinishResponse, RunHistoryItemOut, MeProfileOut, UserStatsOut, UserOut, UpdateMeProfileRequest, UpdateTerritoryColorRequest, ChangePasswordRequest, TerritoryColorOut | — | Pydantic-модели для валидации запросов/ответов API |
| Security | PythonBackend | AccessToken, SecurityModule | — | Хеширование паролей (argon2/bcrypt), создание и декодирование JWT, refresh-токены |
| Settings | PythonBackend | Settings | — | Конфигурация сервера из переменных окружения |
| Geo | PythonBackend | GeoModule | — | Геовычисления: расстояние Хаверсина, WKT LineString, работа с интервалами пауз |
| External | RunApplication | GPS SDK, Connectivity SDK, OSM Tile Server, Flutter Secure Storage, PostgreSQL + PostGIS | — | Внешнее окружение системы: геолокация, сеть, картография, хранилище, СУБД |

**Метрики диаграммы пакетов:**
- Количество пакетов: 24
- Количество уровней вложенности: 3
- Количество зависимостей между пакетами: 36

---

## 5.2 Классовая диаграмма системы

Классовая диаграмма на рисунке 2.

> **[КАРТИНКА]** Рисунок 2 — Классовая диаграмма системы. *Вставить рендер `docs/lab3_class_diagram.puml`.*

---

### Спецификация классовой диаграммы

- Количество классов: 62
- Количество интерфейсов: 5
- Количество перечислений (enum): 4
- Количество ассоциаций: 28
- Количество зависимостей: 30
- Количество реализаций (implements): 5
- Количество композиций: 7
- Количество агрегаций: 3
- Количество HTTP-зависимостей: 5
- Количество уровней наследования: 0
- Количество уровней реализации: 1

---

### Таблица 2 — Спецификация классов

| Имя класса | Пакет | Тип | Степень допуст. | Множеств. | Параллельность | Сохраняемость | Отношения |
|------------|-------|-----|------------------|-----------|----------------|---------------|-----------|
| RunApp | App | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с HomeShellPage |
| HomeShellPage | App | конечный | публичный | 1/1 | последовательные | не сохраняется | Агрегирует MapPage, HistoriesPage, ProfilePage; Ассоциирован с RunTrackerController |
| ApiConfig | Core::Config | конечный | публичный | 1/1 | последовательные | не сохраняется | — |
| AppTheme | Core::Theme | конечный | публичный | 1/1 | последовательные | не сохраняется | — |
| TokenStorage | Core::Storage | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Flutter Secure Storage |
| TokenInterceptor | Core::Network | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с TokenStorage |
| Dio | Core::Network | конечный | публичный | 1/1 | последовательные | не сохраняется | Композиция с TokenInterceptor |
| AuthTokens | Auth::Domain | конечный | публичный | N/1 | последовательные | сохраняется | Ассоциирован с AuthState, TokenStorage |
| AuthRepository | Auth::Domain | интерфейс | публичный | N/1 | последовательные | не сохраняется | Реализуется AuthRepositoryImpl |
| AuthRepositoryImpl | Auth::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Реализует AuthRepository; Ассоциирован с AuthApi |
| AuthApi | Auth::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Dio; HTTP-зависимость от AuthRouter |
| LoginUseCase | Auth::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с AuthRepository |
| RegisterUseCase | Auth::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с AuthRepository |
| AuthStatus | Auth::Application | перечисление | публичный | — | — | не сохраняется | — |
| AuthState | Auth::Application | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с AuthStatus, AuthTokens |
| AuthController | Auth::Application | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от LoginUseCase, RegisterUseCase, TokenStorage |
| LoginPage | Auth::Presentation | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от AuthController |
| RunPoint | Runs::Domain | конечный | публичный | N/1 | последовательные | сохраняется | Композиция в FinishRunRequest, RunTrackerState |
| PauseReason | Runs::Domain | перечисление | публичный | — | — | не сохраняется | — |
| RunPause | Runs::Domain | конечный | публичный | N/1 | последовательные | сохраняется | Композиция в FinishRunRequest, RunTrackerState |
| FinishRunRequest | Runs::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Композиция с RunPoint, RunPause |
| FinishRunResponse | Runs::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с RunTrackerState |
| RunHistoryItem | Runs::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | — |
| RunsRepository | Runs::Domain | интерфейс | публичный | N/1 | последовательные | не сохраняется | Реализуется RunsRepositoryImpl |
| RunsRepositoryImpl | Runs::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Реализует RunsRepository; Ассоциирован с RunsApi |
| RunsApi | Runs::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Dio; HTTP-зависимость от RunsRouter |
| FinishRunUseCase | Runs::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с RunsRepository |
| RunPhase | Runs::Application | перечисление | публичный | — | — | не сохраняется | — |
| RunTrackerState | Runs::Application | конечный | публичный | 1/1 | последовательные | не сохраняется | Композиция с RunPoint, RunPause; Ассоциирован с FinishRunResponse |
| RunTrackerController | Runs::Application | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от FinishRunUseCase, GPS SDK, Connectivity SDK |
| RunSummaryPage | Runs::Presentation | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от RunTrackerController |
| Territory | Territories::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | — |
| Bbox | Territories::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | — |
| TerritoriesRepository | Territories::Domain | интерфейс | публичный | N/1 | последовательные | не сохраняется | Реализуется TerritoriesRepositoryImpl |
| TerritoriesRepositoryImpl | Territories::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Реализует TerritoriesRepository; Ассоциирован с TerritoriesApi |
| TerritoriesApi | Territories::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Dio; HTTP-зависимость от TerritoriesRouter |
| GetTerritoriesForBboxUseCase | Territories::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с TerritoriesRepository |
| MapPage | Territories::Presentation | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от GetTerritoriesForBboxUseCase, RunTrackerController, GetLastNotificationUseCase; Зависит от OSM Tile Server |
| MeProfileStats | Profile::Domain | конечный | публичный | 1/1 | последовательные | не сохраняется | Композиция в MeProfile |
| MeProfile | Profile::Domain | конечный | публичный | 1/1 | последовательные | не сохраняется | Композиция с MeProfileStats |
| ProfileRepository | Profile::Domain | интерфейс | публичный | N/1 | последовательные | не сохраняется | Реализуется ProfileRepositoryImpl |
| ProfileRepositoryImpl | Profile::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Реализует ProfileRepository; Ассоциирован с ProfileApi |
| ProfileApi | Profile::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Dio; HTTP-зависимость от MeRouter |
| GetMeProfileUseCase | Profile::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с ProfileRepository |
| UpdateMeProfileUseCase | Profile::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с ProfileRepository |
| UpdateTerritoryColorUseCase | Profile::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с ProfileRepository |
| ChangePasswordUseCase | Profile::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с ProfileRepository |
| ProfileActionsController | Profile::Application | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от UpdateMeProfileUseCase, UpdateTerritoryColorUseCase, ChangePasswordUseCase |
| ProfilePage | Profile::Presentation | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от ProfileActionsController, GetMeProfileUseCase |
| LastNotification | Notifications::Domain | конечный | публичный | 1/1 | последовательные | не сохраняется | — |
| NotificationsRepository | Notifications::Domain | интерфейс | публичный | N/1 | последовательные | не сохраняется | Реализуется NotificationsRepositoryImpl |
| NotificationsRepositoryImpl | Notifications::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Реализует NotificationsRepository; Ассоциирован с NotificationsApi |
| NotificationsApi | Notifications::Data | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с Dio; HTTP-зависимость от NotificationsRouter |
| GetLastNotificationUseCase | Notifications::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с NotificationsRepository |
| GetRunHistoryUseCase | Histories::Domain | конечный | публичный | N/1 | последовательные | не сохраняется | Ассоциирован с RunsRepository |
| HistoriesPage | Histories::Presentation | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от GetRunHistoryUseCase |
| AuthRouter | Routers | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от SecurityModule, Settings; Ассоциирован с PostgreSQL |
| MeRouter | Routers | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от SecurityModule; Ассоциирован с PostgreSQL |
| RunsRouter | Routers | конечный | публичный | 1/1 | последовательные | не сохраняется | Зависит от GeoModule; Ассоциирован с PostgreSQL |
| TerritoriesRouter | Routers | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с PostgreSQL |
| NotificationsRouter | Routers | конечный | публичный | 1/1 | последовательные | не сохраняется | Ассоциирован с PostgreSQL |
| Settings | Settings | конечный | публичный | 1/1 | последовательные | не сохраняется | — |
| AccessToken | Security | конечный | публичный | N/1 | последовательные | не сохраняется | — |

---

### Таблица 3 — Спецификация атрибутов

#### Класс AuthTokens

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| accessToken | String | public | null | JWT access-токен для авторизации запросов |
| accessExpiresAt | int | public | null | UNIX-время истечения access-токена |
| refreshToken | String | public | null | Токен обновления сессии |

#### Класс RunPoint

| Атрибут | Тип | Видимость | Начальное | Мин. | Макс. | Описание |
|---------|-----|-----------|-----------|------|-------|----------|
| lat | double | public | null | −90.0 | 90.0 | Широта GPS-точки |
| lng | double | public | null | −180.0 | 180.0 | Долгота GPS-точки |
| ts | DateTime | public | null | — | — | Метка времени фиксации точки |
| accuracyM | double? | public | null | 0 | — | Точность GPS в метрах |
| speedMps | double? | public | null | 0 | — | Скорость в м/с |
| altitudeM | double? | public | null | — | — | Высота над уровнем моря |

#### Класс RunPause

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| startedAt | DateTime | public | null | Время начала паузы |
| endedAt | DateTime? | public | null | Время окончания паузы (null = пауза активна) |
| reason | PauseReason | public | null | Причина паузы: manual, gpsLost, internetLost |

#### Класс FinishRunRequest

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| startedAt | DateTime | public | null | Время начала пробежки |
| endedAt | DateTime | public | null | Время окончания пробежки |
| points | List\<RunPoint\> | public | [] | Собранные GPS-точки маршрута |
| pauses | List\<RunPause\> | public | [] | Интервалы пауз во время пробежки |

#### Класс FinishRunResponse

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| runId | String | public | null | UUID завершённой пробежки |
| distanceM | double | public | 0 | Пройденная дистанция в метрах |
| elapsedS | int | public | 0 | Общее время в секундах |
| pausedS | int | public | 0 | Время на паузе в секундах |
| movingS | int | public | 0 | Время в движении в секундах |
| captureAreaM2 | double | public | 0 | Захваченная площадь в м² |
| victimsCount | int | public | 0 | Кол-во пользователей, чья территория захвачена |

#### Класс RunHistoryItem

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| runId | String | public | null | UUID пробежки |
| status | String | public | null | Статус: draft, finished, processed, failed |
| startedAt | DateTime? | public | null | Время начала |
| endedAt | DateTime? | public | null | Время окончания |
| distanceM | double | public | 0 | Дистанция (м) |
| elapsedS | int | public | 0 | Общее время (с) |
| pausedS | int | public | 0 | Время на паузе (с) |
| movingS | int | public | 0 | Время в движении (с) |
| captureAreaM2 | double | public | 0 | Захваченная площадь (м²) |
| victimsCount | int | public | 0 | Кол-во «жертв» |
| createdAt | DateTime | public | null | Дата создания записи |

#### Класс RunTrackerState

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| phase | RunPhase | public | idle | Фаза трекера: idle, running, paused, finishing |
| startedAt | DateTime? | public | null | Время старта пробежки |
| points | List\<RunPoint\> | public | [] | Собранные точки |
| pauses | List\<RunPause\> | public | [] | Паузы |
| countdownSeconds | int? | public | null | Секунды обратного отсчёта |
| lastFinish | FinishRunResponse? | public | null | Результат последней завершённой пробежки |
| error | String? | public | null | Сообщение об ошибке |

#### Класс Territory

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| userId | String | public | null | UUID владельца территории |
| areaM2 | double | public | 0 | Площадь территории в м² |
| territoryColorHex | String | public | "#3B82F6" | Цвет территории (hex) |
| polygons | List\<List\<LatLng\>\> | public | [] | Список полигонов (координаты) |

#### Класс Bbox

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| minLng | double | public | null | Минимальная долгота |
| minLat | double | public | null | Минимальная широта |
| maxLng | double | public | null | Максимальная долгота |
| maxLat | double | public | null | Максимальная широта |

#### Класс MeProfile

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| id | String | public | null | UUID пользователя |
| username | String | public | null | Уникальный логин |
| displayName | String | public | null | Отображаемое имя |
| avatarUrl | String? | public | null | URL аватара |
| email | String? | public | null | Email пользователя |
| territoryColor | String | public | "#3B82F6" | Цвет территории |
| createdAt | DateTime | public | null | Дата регистрации |
| stats | MeProfileStats | public | null | Агрегированная статистика |

#### Класс MeProfileStats

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| runCount | int | public | 0 | Количество пробежек |
| totalDistanceM | double | public | 0 | Общая дистанция (м) |
| totalElapsedS | int | public | 0 | Общее время (с) |
| totalPausedS | int | public | 0 | Общее время на паузе (с) |
| totalMovingS | int | public | 0 | Общее время в движении (с) |
| ownedAreaM2 | double | public | 0 | Площадь собственной территории (м²) |

#### Класс LastNotification

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| kind | String | public | "territory_stolen" | Тип уведомления |
| attackerUserId | String? | public | null | UUID атакующего пользователя |
| runId | String? | public | null | UUID пробежки-атаки |
| stolenAreaM2 | double | public | 0 | Площадь украденной территории (м²) |
| createdAt | DateTime | public | null | Время создания уведомления |

#### Класс AuthState

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| status | AuthStatus | public | unknown | Статус авторизации |
| tokens | AuthTokens? | public | null | Текущие JWT-токены |

#### Класс TokenStorage

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| _key | String | private, static | "auth_tokens" | Ключ хранилища |
| _storage | FlutterSecureStorage | private | — | Экземпляр безопасного хранилища |

#### Класс Settings (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| app_env | str | public | "local" | Окружение (local/prod) |
| app_host | str | public | "127.0.0.1" | Хост сервера |
| app_port | int | public | 8000 | Порт сервера |
| database_url | str | public | "postgresql://…" | Строка подключения к PostgreSQL |
| jwt_secret | str | public | "change_me" | Секрет подписи JWT |
| jwt_issuer | str | public | "run-application" | Issuer JWT-токена |
| access_token_ttl_seconds | int | public | 900 | Время жизни access-токена (15 мин) |
| refresh_token_ttl_seconds | int | public | 2592000 | Время жизни refresh-токена (30 дней) |

#### Класс AccessToken (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| token | str | public | null | Сгенерированный JWT-токен |
| expires_at | int | public | null | UNIX-время истечения |

#### Класс RegisterRequest (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| email | EmailStr | public | null | Email для регистрации |
| password | str | public | null | Пароль (8–200 символов) |
| display_name | str? | public | null | Отображаемое имя (до 80 символов) |

#### Класс LoginRequest (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| email | EmailStr | public | null | Email для входа |
| password | str | public | null | Пароль (1–200 символов) |

#### Класс AuthResponse (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| access_token | str | public | null | JWT access-токен |
| access_expires_at | int | public | null | UNIX-время истечения |
| refresh_token | str | public | null | Refresh-токен |

#### Класс RunPointIn (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| lat | float | public | null | Широта |
| lng | float | public | null | Долгота |
| ts | datetime | public | null | Метка времени |
| accuracy_m | float? | public | null | Точность GPS |
| speed_mps | float? | public | null | Скорость |
| altitude_m | float? | public | null | Высота |

#### Класс RunPauseIn (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| started_at | datetime | public | null | Начало паузы |
| ended_at | datetime? | public | null | Конец паузы |
| reason | str | public | null | Причина: manual/gps_lost/internet_lost |

#### Класс MeProfileOut (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| id | str | public | null | UUID пользователя |
| username | str | public | null | Логин |
| display_name | str | public | null | Отображаемое имя |
| avatar_url | str? | public | null | URL аватара |
| email | EmailStr? | public | null | Email |
| territory_color | str | public | null | Цвет территории (hex) |
| created_at | datetime | public | null | Дата регистрации |
| stats | UserStatsOut | public | null | Статистика |

#### Класс UserStatsOut (Backend)

| Атрибут | Тип | Видимость | Начальное | Описание |
|---------|-----|-----------|-----------|----------|
| run_count | int | public | null | Количество пробежек |
| total_distance_m | float | public | null | Общая дистанция |
| total_elapsed_s | int | public | null | Общее время |
| total_paused_s | int | public | null | Время на паузе |
| total_moving_s | int | public | null | Время в движении |
| owned_area_m2 | float | public | null | Площадь территории |

---

### Таблица 4 — Спецификация операций

#### Класс AuthController

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| build() | AuthState | — | public | Конструктор | Инициализация состояния авторизации |
| login(email, password) | Future\<void\> | email: String, password: String | public | Модификатор | Выполнить вход пользователя |
| register(email, password, displayName) | Future\<void\> | email: String, password: String, displayName: String | public | Модификатор | Зарегистрировать нового пользователя |
| logout() | Future\<void\> | — | public | Модификатор | Выйти из системы, очистить токены |

#### Класс RunTrackerController

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| build() | RunTrackerState | — | public | Конструктор | Инициализация состояния трекера |
| start() | Future\<void\> | — | public | Модификатор | Запуск обратного отсчёта и начало записи GPS |
| pauseManual() | void | — | public | Модификатор | Ручная пауза пробежки |
| resume() | void | — | public | Модификатор | Возобновление пробежки |
| finish() | Future\<void\> | — | public | Модификатор | Завершить пробежку и отправить на сервер |
| clearLastFinish() | void | — | public | Модификатор | Сбросить результат последней пробежки |
| addSimulatedPoint(lat, lng) | void | lat: double, lng: double | public | Модификатор | Добавить точку в тестовом режиме |

#### Класс ProfileActionsController

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| build() | AsyncValue\<void\> | — | public | Конструктор | Инициализация |
| saveProfile(displayName, avatarUrl?) | Future\<void\> | displayName: String, avatarUrl: String? | public | Модификатор | Сохранить данные профиля |
| saveTerritoryColor(color) | Future\<void\> | territoryColor: String | public | Модификатор | Сохранить цвет территории |
| changePassword(currentPwd, newPwd) | Future\<void\> | currentPassword: String, newPassword: String | public | Модификатор | Сменить пароль |

#### Интерфейс AuthRepository

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| login(email, password) | Future\<AuthTokens\> | email: String, password: String | public | Селектор | Вход |
| register(email, password, displayName) | Future\<AuthTokens\> | email: String, password: String, displayName: String | public | Модификатор | Регистрация |
| refresh(refreshToken) | Future\<AuthTokens\> | refreshToken: String | public | Модификатор | Обновление токенов |

#### Интерфейс RunsRepository

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| finish(request) | Future\<FinishRunResponse\> | request: FinishRunRequest | public | Модификатор | Отправить результат пробежки |
| history(limit, offset) | Future\<List\<RunHistoryItem\>\> | limit: int, offset: int | public | Селектор | Получить историю пробежек |

#### Интерфейс TerritoriesRepository

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| fetchByBbox(...) | Future\<List\<Territory\>\> | minLng, minLat, maxLng, maxLat: double | public | Селектор | Получить территории в видимой области |

#### Интерфейс ProfileRepository

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| getMeProfile() | Future\<MeProfile\> | — | public | Селектор | Получить профиль пользователя |
| updateMeProfile(displayName?, avatarUrl?) | Future\<MeProfile\> | displayName: String?, avatarUrl: String? | public | Модификатор | Обновить профиль |
| updateTerritoryColor(color) | Future\<String\> | color: String | public | Модификатор | Обновить цвет территории |
| changePassword(currentPwd, newPwd) | Future\<void\> | currentPassword, newPassword: String | public | Модификатор | Сменить пароль |

#### Интерфейс NotificationsRepository

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| last() | Future\<LastNotification?\> | — | public | Селектор | Последнее уведомление |

#### Класс TokenInterceptor

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| onRequest(options, handler) | void | options: RequestOptions, handler | public | Модификатор | Подставить access-токен в заголовок |
| onError(err, handler) | void | err: DioException, handler | public | Модификатор | При 401 обновить токен и повторить запрос |

#### Класс TokenStorage

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| read() | Future\<AuthTokens?\> | — | public | Селектор | Прочитать токены из хранилища |
| write(tokens) | Future\<void\> | tokens: AuthTokens | public | Модификатор | Сохранить токены |
| clear() | Future\<void\> | — | public | Модификатор | Удалить токены |

#### Класс AuthRouter (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| register(payload) | AuthResponse | payload: RegisterRequest | public | Модификатор | Зарегистрировать пользователя в БД |
| login(payload) | AuthResponse | payload: LoginRequest | public | Селектор | Авторизовать и выдать токены |
| refresh(payload) | AuthResponse | payload: RefreshRequest | public | Модификатор | Обновить пару токенов |

#### Класс MeRouter (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| me(userId) | UserOut | userId: str | public | Селектор | Получить базовые данные пользователя |
| meProfile(userId) | MeProfileOut | userId: str | public | Селектор | Получить профиль со статистикой |
| updateTerritoryColor(payload, userId) | TerritoryColorOut | payload: UpdateTerritoryColorRequest, userId: str | public | Модификатор | Обновить цвет территории |
| updateMeProfile(payload, userId) | MeProfileOut | payload: UpdateMeProfileRequest, userId: str | public | Модификатор | Обновить профиль |
| changePassword(payload, userId) | dict | payload: ChangePasswordRequest, userId: str | public | Модификатор | Сменить пароль |

#### Класс RunsRouter (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| finishRun(payload, userId) | RunFinishResponse | payload: RunFinishRequest, userId: str | public | Модификатор | Обработать завершённую пробежку, вычислить захват территорий |
| runsHistory(userId, limit, offset) | list\[RunHistoryItemOut\] | userId: str, limit: int, offset: int | public | Селектор | Получить историю пробежек |

#### Класс TerritoriesRouter (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| getTerritories(minLng, minLat, maxLng, maxLat) | dict (GeoJSON) | minLng, minLat, maxLng, maxLat: float | public | Селектор | Получить территории в bounding box |

#### Класс NotificationsRouter (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| lastNotification(userId) | dict | userId: str | public | Селектор | Получить последнее уведомление |

#### Класс SecurityModule (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| hash_password(password) | str | password: str | public | Модификатор | Хеширование пароля (argon2) |
| verify_password(password, hash) | bool | password: str, hash: str | public | Селектор | Проверка пароля по хешу |
| new_refresh_token() | str | — | public | Модификатор | Генерация refresh-токена |
| refresh_token_hash(token) | str | token: str | public | Селектор | Хеш refresh-токена (SHA-256) |
| create_access_token(user_id) | AccessToken | user_id: str | public | Модификатор | Создание JWT access-токена |
| decode_access_token(token) | dict | token: str | public | Селектор | Декодирование и валидация JWT |

#### Класс GeoModule (Backend)

| Операция | Возвращает | Параметры | Видимость | Классификация | Описание |
|----------|-----------|-----------|-----------|---------------|----------|
| haversine_m(lat1, lng1, lat2, lng2) | float | lat1, lng1, lat2, lng2: float | public | Селектор | Расстояние между двумя координатами (м) |
| wkt_linestring(points) | str | points: list[tuple] | public | Селектор | Формирование WKT LineString из точек |
| clip_interval(a_start, a_end, b_start, b_end) | float | a_start, a_end, b_start, b_end: datetime | public | Селектор | Пересечение временных интервалов (с) |
| seconds_between(started_at, ended_at) | int | started_at, ended_at: datetime | public | Селектор | Разница во времени в секундах |

---

### Таблица 5 — Спецификация отношений между классами

| Отношение | Тип | Класс-источник | Класс-цель | Описание |
|-----------|-----|----------------|------------|----------|
| 1 | Ассоциация | RunApp | HomeShellPage | Корневой виджет содержит оболочку навигации |
| 2 | Агрегация | HomeShellPage | MapPage | Оболочка включает экран карты (вкладка) |
| 3 | Агрегация | HomeShellPage | HistoriesPage | Оболочка включает экран истории (вкладка) |
| 4 | Агрегация | HomeShellPage | ProfilePage | Оболочка включает экран профиля (вкладка) |
| 5 | Ассоциация | HomeShellPage | RunTrackerController | Оболочка управляет FAB через контроллер трекера |
| 6 | Зависимость | AuthController | LoginUseCase | Контроллер вызывает use case входа |
| 7 | Зависимость | AuthController | RegisterUseCase | Контроллер вызывает use case регистрации |
| 8 | Зависимость | AuthController | TokenStorage | Контроллер сохраняет/удаляет токены |
| 9 | Ассоциация | LoginUseCase | AuthRepository | Use case использует репозиторий |
| 10 | Ассоциация | RegisterUseCase | AuthRepository | Use case использует репозиторий |
| 11 | Реализация | AuthRepositoryImpl | AuthRepository | Реализует интерфейс |
| 12 | Ассоциация | AuthRepositoryImpl | AuthApi | Реализация делегирует вызовы API-клиенту |
| 13 | Ассоциация | AuthApi | Dio | API использует HTTP-клиент |
| 14 | Зависимость | LoginPage | AuthController | UI зависит от контроллера |
| 15 | Зависимость | RunTrackerController | FinishRunUseCase | Контроллер вызывает use case завершения |
| 16 | Зависимость | RunTrackerController | GPS SDK | Контроллер получает GPS-позиции |
| 17 | Зависимость | RunTrackerController | Connectivity SDK | Контроллер проверяет интернет-соединение |
| 18 | Ассоциация | FinishRunUseCase | RunsRepository | Use case использует репозиторий |
| 19 | Реализация | RunsRepositoryImpl | RunsRepository | Реализует интерфейс |
| 20 | Ассоциация | RunsRepositoryImpl | RunsApi | Делегирует API-клиенту |
| 21 | Ассоциация | RunsApi | Dio | Использует HTTP-клиент |
| 22 | Зависимость | RunSummaryPage | RunTrackerController | UI зависит от контроллера |
| 23 | Композиция | FinishRunRequest | RunPoint | Запрос содержит точки |
| 24 | Композиция | FinishRunRequest | RunPause | Запрос содержит паузы |
| 25 | Композиция | RunTrackerState | RunPoint | Состояние содержит точки |
| 26 | Композиция | RunTrackerState | RunPause | Состояние содержит паузы |
| 27 | Ассоциация | GetTerritoriesForBboxUseCase | TerritoriesRepository | Use case использует репозиторий |
| 28 | Реализация | TerritoriesRepositoryImpl | TerritoriesRepository | Реализует интерфейс |
| 29 | Ассоциация | TerritoriesRepositoryImpl | TerritoriesApi | Делегирует API-клиенту |
| 30 | Ассоциация | TerritoriesApi | Dio | Использует HTTP-клиент |
| 31 | Зависимость | MapPage | GetTerritoriesForBboxUseCase | Экран запрашивает территории |
| 32 | Зависимость | MapPage | RunTrackerController | Экран отрисовывает трек пробежки |
| 33 | Зависимость | MapPage | GetLastNotificationUseCase | Экран запрашивает уведомления |
| 34 | Зависимость | MapPage | OSM Tile Server | Экран загружает тайлы карты |
| 35 | Ассоциация | GetMeProfileUseCase | ProfileRepository | Use case использует репозиторий |
| 36 | Ассоциация | UpdateMeProfileUseCase | ProfileRepository | Use case использует репозиторий |
| 37 | Ассоциация | UpdateTerritoryColorUseCase | ProfileRepository | Use case использует репозиторий |
| 38 | Ассоциация | ChangePasswordUseCase | ProfileRepository | Use case использует репозиторий |
| 39 | Реализация | ProfileRepositoryImpl | ProfileRepository | Реализует интерфейс |
| 40 | Ассоциация | ProfileRepositoryImpl | ProfileApi | Делегирует API-клиенту |
| 41 | Ассоциация | ProfileApi | Dio | Использует HTTP-клиент |
| 42 | Зависимость | ProfileActionsController | UpdateMeProfileUseCase | Контроллер вызывает use case |
| 43 | Зависимость | ProfileActionsController | UpdateTerritoryColorUseCase | Контроллер вызывает use case |
| 44 | Зависимость | ProfileActionsController | ChangePasswordUseCase | Контроллер вызывает use case |
| 45 | Зависимость | ProfilePage | ProfileActionsController | UI зависит от контроллера |
| 46 | Зависимость | ProfilePage | GetMeProfileUseCase | UI зависит от use case профиля |
| 47 | Ассоциация | GetLastNotificationUseCase | NotificationsRepository | Use case использует репозиторий |
| 48 | Реализация | NotificationsRepositoryImpl | NotificationsRepository | Реализует интерфейс |
| 49 | Ассоциация | NotificationsRepositoryImpl | NotificationsApi | Делегирует API-клиенту |
| 50 | Ассоциация | NotificationsApi | Dio | Использует HTTP-клиент |
| 51 | Ассоциация | GetRunHistoryUseCase | RunsRepository | Use case использует репозиторий |
| 52 | Зависимость | HistoriesPage | GetRunHistoryUseCase | UI зависит от use case |
| 53 | Ассоциация | TokenInterceptor | TokenStorage | Перехватчик читает/пишет токены |
| 54 | Композиция | Dio | TokenInterceptor | HTTP-клиент содержит перехватчик |
| 55 | Ассоциация | TokenStorage | Flutter Secure Storage | Хранилище использует платформенный API |
| 56 | Композиция | MeProfile | MeProfileStats | Профиль содержит статистику |
| 57 | HTTP-зависимость | AuthApi | AuthRouter | REST: POST /auth/register, POST /auth/login, POST /auth/refresh |
| 58 | HTTP-зависимость | RunsApi | RunsRouter | REST: POST /runs/finish, GET /runs/history |
| 59 | HTTP-зависимость | TerritoriesApi | TerritoriesRouter | REST: GET /territories |
| 60 | HTTP-зависимость | NotificationsApi | NotificationsRouter | REST: GET /notifications/last |
| 61 | HTTP-зависимость | ProfileApi | MeRouter | REST: GET /me/profile, PATCH /me/profile, PATCH /me/territory-color, PATCH /me/password |
| 62 | Ассоциация | AuthRouter | PostgreSQL + PostGIS | Роутер читает/пишет в БД |
| 63 | Ассоциация | MeRouter | PostgreSQL + PostGIS | Роутер читает/пишет в БД |
| 64 | Ассоциация | RunsRouter | PostgreSQL + PostGIS | Роутер читает/пишет в БД |
| 65 | Ассоциация | TerritoriesRouter | PostgreSQL + PostGIS | Роутер читает из БД |
| 66 | Ассоциация | NotificationsRouter | PostgreSQL + PostGIS | Роутер читает из БД |
| 67 | Зависимость | AuthRouter | SecurityModule | Роутер использует хеширование и JWT |
| 68 | Зависимость | MeRouter | SecurityModule | Роутер использует проверку пароля |
| 69 | Зависимость | RunsRouter | GeoModule | Роутер использует геовычисления |
| 70 | Зависимость | AuthRouter | Settings | Конфигурация JWT |
| 71 | Композиция | RunFinishRequest (BE) | RunPointIn | Запрос содержит точки |
| 72 | Композиция | RunFinishRequest (BE) | RunPauseIn | Запрос содержит паузы |
| 73 | Композиция | MeProfileOut | UserStatsOut | Ответ содержит статистику |

**Итого:**
- Ассоциаций: 28
- Зависимостей: 22
- Реализаций: 5
- Композиций: 8
- Агрегаций: 3
- HTTP-зависимостей: 5
- **Всего отношений: 73** (не считая дублирования фронт/бэк)

---

### Исходный код (фрагменты ключевых классов)

#### RunTrackerController (Flutter, lib/src/features/runs/application/run_tracker_controller.dart)

```dart
class RunTrackerController extends _$RunTrackerController {
  StreamSubscription<Position>? _posSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  RunTrackerState build() => RunTrackerState.idle();

  Future<void> start() async { /* обратный отсчёт, подписка на GPS */ }

  void pauseManual() { /* ручная пауза */ }

  void resume() { /* возобновление */ }

  Future<void> finish() async { /* отправка на сервер */ }

  void clearLastFinish() { /* сброс */ }

  void addSimulatedPoint({required double lat, required double lng}) { /* тест */ }

  Future<void> _dispose() async { /* отписка */ }
}
```

#### AuthRouter (Python, app/routers/auth.py)

```python
router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=AuthResponse, status_code=201)
def register(payload: RegisterRequest, request: Request):
    with db_conn() as conn:
        # создание пользователя, хеширование пароля, генерация токенов
        ...

@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, request: Request):
    with db_conn() as conn:
        # проверка пароля, генерация токенов
        ...

@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest, request: Request):
    with db_conn() as conn:
        # ротация refresh-токена
        ...
```

#### RunsRouter (Python, app/routers/runs.py)

```python
router = APIRouter(prefix="/runs", tags=["runs"])

@router.post("/finish", response_model=RunFinishResponse)
def finish_run(payload: RunFinishRequest, user_id: str = Depends(current_user_id)):
    with db_conn() as conn:
        # вычисление дистанции, времени, WKT LineString
        # вставка в runs, run_points, run_pauses
        # вызов finalize_run_capture (PostGIS)
        # обновление user_stats
        ...

@router.get("/history", response_model=list[RunHistoryItemOut])
def runs_history(user_id: str = Depends(current_user_id), limit: int = 50, offset: int = 0):
    with db_conn() as conn:
        # SELECT из runs ORDER BY created_at DESC
        ...
```

---

## 5.3 Диаграмма объектов

Диаграмма объектов (рисунок 3) описывает конкретный экземпляр системы в момент, когда пользователь **Максим** (`user-001`) только что завершил пробежку и ожидает результат от сервера.

> **[КАРТИНКА]** Рисунок 3 — Диаграмма объектов. *Вставить рендер `docs/lab3_object_diagram.puml`.*

**Описание сценария:**
- Пользователь Максим авторизован (AuthState.status = authenticated), токены сохранены.
- Трекер находится в фазе `finishing` — пробежка завершается.
- Собрано 3 GPS-точки (pt1, pt2, pt3), была одна ручная пауза (pause1).
- На карте видны 2 территории: своя (зелёная) и соперника (красная).
- Имеется уведомление о том, что соперник ранее захватил часть территории Максима.
- Профиль содержит агрегированную статистику за 47 пробежек.
- Настройки бэкенда указывают на локальное окружение.

---

## Вывод

В ходе лабораторной работы были получены навыки разработки концептуальных статических моделей классового уровня, состоящих из:

- Диаграммы пакетов и спецификации пакетов (24 пакета, 3 уровня вложенности);
- Классовой диаграммы системы (62 класса, 5 интерфейсов, 4 перечисления), спецификации классов, атрибутов, операций, отношений между классами (73 отношения), фрагментов исходного кода;
- Диаграммы объектов, демонстрирующей конкретный сценарий завершения пробежки.

Все диаграммы выполнены в формате PlantUML и могут быть отрендерены в графические файлы для включения в отчёт.
