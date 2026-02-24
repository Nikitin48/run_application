# Примеры SQL запросов для презентации

Эти запросы можно показать на слайдах для демонстрации работы с БД.

---

## 1. Структура таблицы territories

```sql
-- Показать структуру таблицы территорий
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'territories';
```

**Результат:**
- `user_id` → uuid (PK)
- `geom` → geometry(MultiPolygon, 4326) ← **PostGIS тип**
- `updated_at` → timestamptz

---

## 2. Пример создания территории

```sql
-- Создание территории из полигона
INSERT INTO territories (user_id, geom)
VALUES (
    'user-uuid-here',
    ST_SetSRID(
        ST_GeomFromText('MULTIPOLYGON(((37.62 55.75, 37.63 55.75, 37.63 55.76, 37.62 55.76, 37.62 55.75)))'),
        4326
    )
);
```

---

## 3. Получение территорий в bounding box (используется API)

```sql
-- Эндпоинт GET /territories использует этот запрос
SELECT 
    t.user_id,
    u.display_name,
    ST_AsGeoJSON(t.geom) as geometry
FROM territories t
JOIN users u ON u.id = t.user_id
WHERE ST_Intersects(
    t.geom,
    ST_MakeEnvelope(
        37.60, 55.74,  -- minLng, minLat
        37.63, 55.76,  -- maxLng, maxLat
        4326
    )
);
```

---

## 4. Вычисление захваченных полигонов из трека

```sql
-- Функция compute_capture_polygons в действии
SELECT 
    run_id,
    ST_AsText(
        compute_capture_polygons(
            track_line,
            10,    -- tol_m (допуск замыкания в метрах)
            150    -- min_area_m2 (минимальная площадь)
        )
    ) as captured_polygons
FROM runs
WHERE id = 'run-uuid-here';
```

---

## 5. Завершение пробежки и захват территории

```sql
-- Полный процесс (выполняется в транзакции)
BEGIN;

-- 1. Вставка пробежки (уже сделано через API)
-- INSERT INTO runs (...) VALUES (...);

-- 2. Вызов функции захвата
SELECT capture_area_m2, victims_count
FROM finalize_run_capture(
    'run-uuid-here',
    10,   -- tol_m
    150   -- min_area_m2
);

COMMIT;
```

**Что происходит внутри `finalize_run_capture`:**
1. Вычисляет захваченные полигоны
2. Находит жертв (территории пересекаются)
3. Убирает захват у жертв (`ST_Difference`)
4. Добавляет захват бегуну (`ST_Union`)
5. Обновляет статистику
6. Создает уведомления

---

## 6. Статистика пользователя

```sql
-- Получить статистику пользователя
SELECT 
    u.display_name,
    us.run_count,
    ROUND(us.total_distance_m / 1000, 2) as total_distance_km,
    ROUND(us.owned_area_m2 / 1000000, 2) as owned_area_km2,
    us.total_moving_s / 60 as total_moving_minutes
FROM user_stats us
JOIN users u ON u.id = us.user_id
WHERE us.user_id = 'user-uuid-here';
```

---

## 7. Найти жертв (территории, которые пересекаются с захватом)

```sql
-- Это часть функции finalize_run_capture
-- Показывает, как находятся жертвы
SELECT 
    t.user_id,
    u.display_name,
    ST_Area(ST_Transform(
        ST_Intersection(t.geom, :capture_polygon),
        3857
    )) as stolen_area_m2
FROM territories t
JOIN users u ON u.id = t.user_id
WHERE t.user_id <> :runner_id
  AND ST_Intersects(t.geom, :capture_polygon);
```

---

## 8. Последнее уведомление пользователя

```sql
-- Эндпоинт GET /notifications/last использует этот запрос
SELECT 
    un.kind,
    un.stolen_area_m2,
    attacker.display_name as attacker_name,
    un.created_at
FROM user_last_notification un
LEFT JOIN users attacker ON attacker.id = un.attacker_user_id
WHERE un.user_id = 'user-uuid-here';
```

---

## 9. Показать все пробежки пользователя

```sql
-- Список пробежек с метриками
SELECT 
    r.id,
    r.started_at,
    r.ended_at,
    ROUND(r.distance_m / 1000, 2) as distance_km,
    r.elapsed_s / 60 as elapsed_minutes,
    r.moving_s / 60 as moving_minutes,
    r.status
FROM runs r
WHERE r.user_id = 'user-uuid-here'
ORDER BY r.started_at DESC
LIMIT 10;
```

---

## 10. Пространственный индекс (GIST)

```sql
-- Показать индексы для таблицы territories
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'territories';

-- Результат покажет GIST индекс:
-- territories_geom_gix ON territories USING GIST (geom)
```

**Почему это важно:**
- GIST индекс ускоряет пространственные запросы (`ST_Intersects`, `ST_Contains`)
- Без индекса запросы на больших данных будут очень медленными

---

## Для презентации

**Рекомендуется показать:**
1. **Слайд 2 (Проектирование БД)**: запросы #1, #3 (структура и пространственные запросы)
2. **Слайд 3 (Реализация БД)**: запросы #4, #5 (функции захвата)
3. **Слайд 4 (Backend)**: можно упомянуть, что API использует запросы #3, #8

**Не показывайте весь код!** Только ключевые части:
- Название функции
- Основные параметры
- Что возвращает



