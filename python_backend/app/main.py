from fastapi import FastAPI

from .settings import settings
from .routers import auth as auth_router
from .routers import me as me_router
from .routers import notifications as notifications_router
from .routers import runs as runs_router
from .routers import territories as territories_router


app = FastAPI(
    title="Run Application API",
    version="0.1.0",
    description=(
        "Backend for running tracker with gamification: runs -> capture polygons -> territories repainting.\n\n"
        "Swagger UI: `/docs`\n"
        "OpenAPI JSON: `/openapi.json`"
    ),
    openapi_tags=[
        {"name": "auth", "description": "Registration/login/refresh (email+password)."},
        {"name": "me", "description": "Current user profile (requires Bearer token)."},
        {"name": "runs", "description": "Upload finished runs and trigger territory capture (requires Bearer token)."},
        {"name": "territories", "description": "Read-only territories GeoJSON by bbox."},
        {"name": "notifications", "description": "Last notification about stolen territory (requires Bearer token)."},
    ],
)

app.include_router(auth_router.router)
app.include_router(me_router.router)
app.include_router(runs_router.router)
app.include_router(territories_router.router)
app.include_router(notifications_router.router)


@app.on_event("startup")
def startup_log() -> None:
    """При старте выводим, с какой БД работаем."""
    import logging
    log = logging.getLogger("uvicorn.error")
    # Показываем только хост из DATABASE_URL (без пароля)
    db_url = settings.database_url_resolved
    if "@" in db_url and "?" in db_url:
        host_part = db_url.split("@", 1)[1].split("?", 1)[0]
    elif "@" in db_url:
        host_part = db_url.split("@", 1)[1]
    else:
        host_part = db_url
    log.info("Backend started | env=%s | database=%s", settings.app_env, host_part)


@app.get("/health")
def health() -> dict:
    return {"ok": True, "env": settings.app_env}







