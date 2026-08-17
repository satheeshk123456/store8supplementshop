"""
One-time Firebase Admin SDK init, shared across the whole app.

The Admin SDK is what lets this backend read/write Firestore and send FCM pushes with full
trust — it authenticates with a *service account*, not a user, and Firestore security rules
don't even apply to it (see firestore.rules: everything is denied to normal clients on purpose,
so the service account + this API are the only way in).
"""
import base64
import json
import logging

import firebase_admin
from firebase_admin import credentials, firestore, messaging, storage

from app.config import get_settings

logger = logging.getLogger("store8")

_settings = get_settings()
_app = None


def _load_credentials() -> credentials.Certificate:
    if _settings.firebase_service_account_b64:
        raw = base64.b64decode(_settings.firebase_service_account_b64)
        info = json.loads(raw)
        return credentials.Certificate(info)
    return credentials.Certificate(_settings.firebase_service_account_file)


def init_firebase():
    global _app
    if _app is not None:
        return _app
    cred = _load_credentials()
    options = {}
    if _settings.firebase_storage_bucket:
        options["storageBucket"] = _settings.firebase_storage_bucket
    _app = firebase_admin.initialize_app(cred, options or None)
    logger.info("Firebase Admin SDK initialized (project=%s)", cred.project_id)
    return _app


def get_db():
    """Firestore client. Calls init_firebase() itself (idempotent, see above) rather than only
    relying on the app's lifespan startup event — some serverless hosts don't reliably run ASGI
    lifespan hooks per invocation, so every accessor here is self-sufficient on its own."""
    init_firebase()
    return firestore.client()


def get_messaging():
    init_firebase()
    return messaging


def get_bucket():
    """Default Storage bucket (needs FIREBASE_STORAGE_BUCKET set — see config.py)."""
    init_firebase()
    return storage.bucket()


__all__ = ["init_firebase", "get_db", "get_messaging", "get_bucket", "firestore"]
