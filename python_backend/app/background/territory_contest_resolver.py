from __future__ import annotations

import asyncio
import logging

from ..db import db_conn
from ..services.territory_maintenance import resolve_due_territory_contests
from ..settings import settings

log = logging.getLogger(__name__)


def _resolve_tick() -> int:
    with db_conn() as conn:
        return resolve_due_territory_contests(conn)


async def run_territory_contest_resolver(stop: asyncio.Event) -> None:
    """Periodically resolves territory contests whose resolve_at has passed."""
    if not settings.territory_contest_resolve_enabled:
        log.info("Territory contest background resolver is disabled")
        return

    interval = settings.territory_contest_resolve_interval_seconds
    log.info(
        "Territory contest background resolver started (interval=%ss)",
        interval,
    )

    while not stop.is_set():
        try:
            resolved = await asyncio.to_thread(_resolve_tick)
            log.info(
                "Territory contest resolve tick (interval=%ss): resolved=%d",
                interval,
                resolved,
            )
        except Exception:
            log.exception("Territory contest resolve tick failed")

        try:
            await asyncio.wait_for(stop.wait(), timeout=interval)
        except TimeoutError:
            pass

    log.info("Territory contest background resolver stopped")
