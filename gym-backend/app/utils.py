import random
import re
import string
from datetime import datetime, timezone


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def short_id(n: int = 8) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return "".join(random.choices(alphabet, k=n))


def new_order_number() -> str:
    today = datetime.now(timezone.utc).strftime("%Y%m%d")
    return f"S8-{today}-{short_id(5).upper()}"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def doc_to_dict(doc) -> dict:
    """Firestore DocumentSnapshot -> plain dict with id + ISO timestamps."""
    data = doc.to_dict() or {}
    data["id"] = doc.id
    for key in ("created_at", "updated_at", "last_seen_at"):
        val = data.get(key)
        if hasattr(val, "isoformat"):
            data[key] = val.isoformat()
    return data
