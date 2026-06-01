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


def _resolve_credentials_path() -> str:
    configured = (settings.fcm_service_account_json_path or "").strip()
    candidates: list[str] = []
    if configured:
        candidates.append(configured)
        # Common production mismatch: host path in env, but container mount is /secrets/<file>.
        candidates.append(os.path.join("/secrets", os.path.basename(configured)))
    candidates.extend(
        [
            "/secrets/firebase-adminsdk.json",
            "/secrets/firebase-service-account.json",
        ]
    )

    seen: set[str] = set()
    unique_candidates: list[str] = []
    for path in candidates:
        path = path.strip()
        if not path or path in seen:
            continue
        seen.add(path)
        unique_candidates.append(path)

    for path in unique_candidates:
        if os.path.isfile(path):
            if configured and path != configured:
                log.warning(
                    "Configured FCM_SERVICE_ACCOUNT_JSON_PATH does not exist; using fallback: %s",
                    path,
                )
            return path
    return ""


def _ensure_firebase_ready() -> bool:
    global _APP_READY
    if _APP_READY:
        return True
    if not settings.fcm_enabled:
        return False
    creds_path = _resolve_credentials_path()
    if not creds_path:
        configured = (settings.fcm_service_account_json_path or "").strip()
        log.warning(
            "FCM credentials file not found. configured_path=%r checked_fallbacks=%s",
            configured,
            [
                "/secrets/firebase-adminsdk.json",
                "/secrets/firebase-service-account.json",
            ],
        )
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
    kind: str = "territory_contested",
) -> PushDeliveryResult:
    if not _ensure_firebase_ready():
        return PushDeliveryResult(invalid_tokens=[])

    token_list = [t for t in tokens if t]
    if not token_list:
        return PushDeliveryResult(invalid_tokens=[])

    if kind == "territory_stolen":
        title = "Часть территории захвачена"
        body = f"{attacker_name} забрал уязвимую часть вашей территории"
    else:
        title = "Часть территории стала спорной"
        body = f"{attacker_name} оспаривает часть вашей территории"

    msg = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "kind": kind,
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

