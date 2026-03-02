# Compact System Class Diagram: описание классов

Ниже приведено описание всех классов, полей и методов из диаграммы `docs/compact_system_class_diagram.puml`.

## Обозначения

- `+` public (публичный элемент)
- `-` private (внутренний элемент класса)
- Типы и сигнатуры указаны в архитектурном виде (high-level), без привязки к конкретной реализации.

## 1) Environment

### `User` (`<<actor>>`)

**Назначение:** внешний пользователь мобильного приложения.

**Методы:**
- `openMap()` - открывает экран карты.
- `tapLogin()` - инициирует действие входа.
- `tapStartRun()` - запускает начало пробежки.

### `GPS` (`GPS SDK`, `<<external>>`)

**Назначение:** внешний SDK геолокации.

**Методы:**
- `streamPosition(): Position` - отдает поток/обновления координат.

### `Net` (`Connectivity SDK`, `<<external>>`)

**Назначение:** внешний SDK проверки сетевого состояния.

**Методы:**
- `isOnline(): bool` - возвращает доступность сети.

### `Storage` (`Secure Storage`, `<<external>>`)

**Назначение:** защищенное локальное хранилище на устройстве.

**Методы:**
- `read(key: String): String?` - читает значение по ключу.
- `write(key: String, value: String): void` - сохраняет значение по ключу.

### `DB` (`PostgreSQL + PostGIS`, `<<external>>`)

**Назначение:** внешняя база данных и геопространственное хранилище.

**Методы:**
- `query(sql: String): ResultSet` - выполняет запрос чтения.
- `execute(sql: String): int` - выполняет запрос изменения данных.

## 2) Flutter App (System)

### `MapPage`

**Назначение:** основной UI-экран карты; точка запуска пользовательских действий.

**Поля:**
- `-authController: AuthController` - ссылка на контроллер авторизации.
- `-runController: RunTrackerController` - ссылка на контроллер трекинга пробежки.

**Методы:**
- `onLoginTap(): void` - обработчик нажатия входа.
- `onRunToggle(): void` - обработчик запуска/остановки пробежки.

### `AuthController`

**Назначение:** управление состоянием аутентификации и auth-сценариями.

**Поля:**
- `-authRepo: AuthRepository` - зависимость на контракт auth-репозитория.
- `-isAuthenticated: bool` - текущее состояние авторизации.

**Методы:**
- `login(email: String, password: String): Future<void>` - выполняет вход пользователя.
- `logout(): Future<void>` - выполняет выход пользователя.

### `RunTrackerController`

**Назначение:** управление жизненным циклом пробежки и отправкой результата.

**Поля:**
- `-runsRepo: RunsRepository` - зависимость на контракт репозитория пробежек.
- `-isRunning: bool` - признак активной пробежки.
- `-points: List<RunPoint>` - собранные точки маршрута.

**Методы:**
- `startRun(): void` - старт записи пробежки.
- `finishRun(): Future<void>` - завершение и отправка результата.

### `AuthRepository` (interface)

**Назначение:** контракт для операций аутентификации.

**Методы:**
- `login(email: String, password: String): Future<AuthTokens>`
- `refreshToken(): Future<AuthTokens>`
- `logout(): Future<void>`

### `RunsRepository` (interface)

**Назначение:** контракт для операций, связанных с пробежками.

**Методы:**
- `finishRun(points: List<RunPoint>): Future<RunFinishResponse>`
- `getHistory(): Future<List<RunSummary>>`

### `AuthRepositoryImpl`

**Назначение:** реализация `AuthRepository` через HTTP/API-клиент.

**Поля:**
- `-api: ApiClient` - клиент сетевого слоя.

**Методы:**
- `login(email: String, password: String): Future<AuthTokens>`
- `refreshToken(): Future<AuthTokens>`
- `logout(): Future<void>`

### `RunsRepositoryImpl`

**Назначение:** реализация `RunsRepository` через HTTP/API-клиент.

**Поля:**
- `-api: ApiClient` - клиент сетевого слоя.

**Методы:**
- `finishRun(points: List<RunPoint>): Future<RunFinishResponse>`
- `getHistory(): Future<List<RunSummary>>`

### `ApiClient`

**Назначение:** общий HTTP-клиент приложения.

**Поля:**
- `-tokenInterceptor: TokenInterceptor` - обработчик токенов и повторов запросов.

**Методы:**
- `get(path: String): Future<Response>` - GET-запрос.
- `post(path: String, body: Object): Future<Response>` - POST-запрос.

### `TokenInterceptor`

**Назначение:** подстановка токена в запросы и обработка `401` с обновлением токена.

**Поля:**
- `-storage: Storage` - доступ к защищенному хранилищу токенов.

**Методы:**
- `attachAccessToken(req: Request): Request` - добавляет access token в запрос.
- `handle401AndRefresh(err: HttpError): Response` - обновляет токен и повторяет запрос.

## 3) Backend API (System)

### `AuthRouter` (`<<router>>`)

**Назначение:** backend endpoint-ы авторизации.

**Поля:**
- `-db: DB` - доступ к базе данных.

**Методы:**
- `login(req: LoginRequest): AuthTokens` - вход пользователя.
- `refresh(req: RefreshRequest): AuthTokens` - обновление токена.

### `RunsRouter` (`<<router>>`)

**Назначение:** backend endpoint-ы завершения пробежки и истории.

**Поля:**
- `-db: DB` - доступ к базе данных.

**Методы:**
- `finishRun(req: RunFinishRequest): RunFinishResponse` - завершение пробежки.
- `history(userId: UUID): List<RunSummary>` - получение истории пробежек.

## 4) Ключевые связи на диаграмме

- `association` (`-->`): пользователь/класс взаимодействует с другим классом.
- `dependency` (`..>`): класс зависит от контракта/сервиса.
- `realization` (`..|>`): реализация интерфейса.
- HTTP-зависимости и связи с БД вынесены отдельно, чтобы показать границу между приложением, API и внешней инфраструктурой.
