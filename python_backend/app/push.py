from __future__ import annotations

from dataclasses import dataclass
import logging
import os
from typing import Iterable

from firebase_admin import credentials, messaging
import firebase_admin

from .settings import settings

log = logging.getLogger(__name__)
_APP_READY = False


@dataclass(frozen=True)
class PushDeliveryResult:
    invalid_tokens: list[str]


def _ensure_firebase_ready() -> bool:
    global _APP_READY
    if _APP_READY:
        return True
    if not settings.fcm_enabled:
        return False
    creds_path = (settings.fcm_service_account_json_path or "").strip()
    if not creds_path:
        log.warning("FCM is enabled, but FCM_SERVICE_ACCOUNT_JSON_PATH is empty")
        return False
    if not os.path.isfile(creds_path):
        log.warning("FCM credentials file not found: %s", creds_path)
        return False

    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(creds_path)
            firebase_admin.initialize_app(cred)
        _APP_READY = True
        return True
    except Exception:
        log.exception("Failed to initialize Firebase Admin SDK")
        return False


def send_territory_attacked_pushes(
    *,
    tokens: Iterable[str],
    attacker_name: str,
) -> PushDeliveryResult:
    if not _ensure_firebase_ready():
        return PushDeliveryResult(invalid_tokens=[])

    token_list = [t for t in tokens if t]
    if not token_list:
        return PushDeliveryResult(invalid_tokens=[])

    msg = messaging.MulticastMessage(
        notification=messaging.Notification(
            title="Ваша территория была атакована",
            body=f"{attacker_name} захватил вашу территорию",
        ),
        data={
            "kind": "territory_stolen",
            "attacker_display_name": attacker_name,
        },
        tokens=token_list,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            headers={"apns-priority": "10"},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default"),
            ),
        ),
    )

    result = messaging.send_each_for_multicast(msg)
    invalid_tokens: list[str] = []
    for idx, r in enumerate(result.responses):
        if r.success:
            continue
        err = r.exception
        if err is None:
            continue
        code = getattr(err, "code", "")
        if code in {"registration-token-not-registered", "invalid-argument"}:
            invalid_tokens.append(token_list[idx])

    return PushDeliveryResult(invalid_tokens=invalid_tokens)

