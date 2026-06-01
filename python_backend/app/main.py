from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from .background.territory_contest_resolver import run_territory_contest_resolver
from .settings import settings
from .routers import admin as admin_router
from .routers import auth as auth_router
from .routers import leaderboard as leaderboard_router
from .routers import locations as locations_router
from .routers import me as me_router
from .routers import notifications as notifications_router
from .routers import push_tokens as push_tokens_router
from .routers import runs as runs_router
from .routers import territories as territories_router


def _log_database_target() -> None:
    log = logging.getLogger("uvicorn.error")
    db_url = settings.database_url_resolved
    if "@" in db_url and "?" in db_url:
        host_part = db_url.split("@", 1)[1].split("?", 1)[0]
    elif "@" in db_url:
        host_part = db_url.split("@", 1)[1]
    else:
        host_part = db_url
    log.info("Backend started | env=%s | database=%s", settings.app_env, host_part)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _log_database_target()
    stop = asyncio.Event()
    resolver_task = asyncio.create_task(run_territory_contest_resolver(stop))
    try:
        yield
    finally:
        stop.set()
        resolver_task.cancel()
        try:
            await resolver_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="Run Application API",
    version="0.1.0",
    lifespan=lifespan,
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
        {"name": "push-tokens", "description": "Register/remove device push tokens (requires Bearer token)."},
        {"name": "locations", "description": "Reference locations for country/region/city profile selection."},
        {"name": "leaderboard", "description": "Leaderboard by city/region/country and metric."},
        {"name": "admin", "description": "Admin-only user management."},
    ],
)

app.include_router(admin_router.router)
app.include_router(auth_router.router)
app.include_router(me_router.router)
app.include_router(runs_router.router)
app.include_router(territories_router.router)
app.include_router(notifications_router.router)
app.include_router(push_tokens_router.router)
app.include_router(locations_router.router)
app.include_router(leaderboard_router.router)


@app.get("/health")
def health() -> dict:
    return {"ok": True, "env": settings.app_env}
