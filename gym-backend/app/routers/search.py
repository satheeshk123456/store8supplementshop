from fastapi import APIRouter

from app.firebase import get_db, firestore
from app.routers.items import _with_variant_labels
from app.schemas import Item
from app.utils import doc_to_dict

router = APIRouter(tags=["search"])


@router.get("/search", response_model=list[Item])
def search_items(q: str = ""):
    """
    Public: simple, no-cost search — a case-insensitive substring match over product name,
    brand name, title and flavor, done in Python rather than a paid search service. Fine at
    this catalog's size (tens to a few hundred items); worth revisiting only if the catalog
    grows into the thousands and this starts reading too many documents per request.
    """
    q = q.strip().lower()
    if len(q) < 2:
        return []

    db = get_db()
    docs = db.collection("items").where(filter=firestore.FieldFilter("is_active", "==", True)).stream()

    results = []
    for d in docs:
        data = doc_to_dict(d)
        haystack = " ".join(
            [data.get("product_name") or "", data.get("brand_name") or "", data.get("title") or "", data.get("flavor") or ""]
        ).lower()
        if q in haystack:
            results.append(_with_variant_labels(data))

    return results[:40]
