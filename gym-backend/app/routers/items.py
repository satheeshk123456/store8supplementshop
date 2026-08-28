from fastapi import APIRouter, Depends, HTTPException

from app.firebase import get_db, firestore
from app.schemas import Item, ItemIn, format_variant_label
from app.security import get_current_admin
from app.utils import doc_to_dict, short_id

router = APIRouter(tags=["items"])
COLLECTION = "items"


def _with_variant_labels(data: dict) -> dict:
    for v in data.get("variants", []):
        v["label"] = format_variant_label(v["unit"], v["value"])
    return data


def _load_refs(db, product_id: str, brand_id: str) -> tuple[dict, dict]:
    p = db.collection("products").document(product_id).get()
    if not p.exists:
        raise HTTPException(400, "Unknown product_id")
    b = db.collection("brands").document(brand_id).get()
    if not b.exists:
        raise HTTPException(400, "Unknown brand_id")
    return p.to_dict(), b.to_dict()


@router.get("/products/{product_id}/items", response_model=list[Item])
def list_items_for_product(product_id: str):
    """Public: step 3 — brands available for a chosen product."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .where(filter=firestore.FieldFilter("product_id", "==", product_id))
        .stream()
    )
    return [_with_variant_labels(doc_to_dict(d)) for d in docs]


@router.get("/brands/{brand_id}/items", response_model=list[Item])
def list_items_for_brand(brand_id: str):
    """Public: reverse browse — pick a brand first, see everything Store 8 carries for it."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .where(filter=firestore.FieldFilter("brand_id", "==", brand_id))
        .stream()
    )
    return [_with_variant_labels(doc_to_dict(d)) for d in docs]


@router.get("/featured-items", response_model=list[Item])
def list_featured_items():
    """Public: homepage 'featured products' strip — items the admin has flagged is_featured."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .where(filter=firestore.FieldFilter("is_featured", "==", True))
        .limit(12)
        .stream()
    )
    return [_with_variant_labels(doc_to_dict(d)) for d in docs]


@router.get("/items/{item_id}", response_model=Item)
def get_item(item_id: str):
    """Public: step 4 — variant/size picker for one brand's product."""
    db = get_db()
    doc = db.collection(COLLECTION).document(item_id).get()
    if not doc.exists:
        raise HTTPException(404, "Item not found")
    return _with_variant_labels(doc_to_dict(doc))


@router.get("/admin/items", response_model=list[Item])
def admin_list_items(admin=Depends(get_current_admin)):
    db = get_db()
    docs = db.collection(COLLECTION).stream()
    return [_with_variant_labels(doc_to_dict(d)) for d in docs]


@router.post("/admin/items", response_model=Item, status_code=201)
def create_item(payload: ItemIn, admin=Depends(get_current_admin)):
    db = get_db()
    product, brand = _load_refs(db, payload.product_id, payload.brand_id)

    data = payload.model_dump()
    data["variants"] = [{**v, "id": short_id()} for v in data["variants"]]
    data["product_name"] = product["name"]
    data["brand_name"] = brand["name"]
    data["unit_kind"] = product["unit_kind"]
    data["created_at"] = data["updated_at"] = firestore.SERVER_TIMESTAMP

    ref = db.collection(COLLECTION).document()
    ref.set(data)
    return _with_variant_labels(doc_to_dict(ref.get()))


@router.put("/admin/items/{item_id}", response_model=Item)
def update_item(item_id: str, payload: ItemIn, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(item_id)
    existing = ref.get()
    if not existing.exists:
        raise HTTPException(404, "Item not found")
    product, brand = _load_refs(db, payload.product_id, payload.brand_id)

    old_variants = {v["id"]: v for v in existing.to_dict().get("variants", [])}
    data = payload.model_dump()
    new_variants = []
    for v in data["variants"]:
        # keep stable ids for variants the admin already had (matched by unit+value) so
        # in-flight cart links / order history keep making sense; new sizes get fresh ids.
        match = next(
            (ov for ov in old_variants.values() if ov["unit"] == v["unit"] and ov["value"] == v["value"]),
            None,
        )
        new_variants.append({**v, "id": match["id"] if match else short_id()})
    data["variants"] = new_variants
    data["product_name"] = product["name"]
    data["brand_name"] = brand["name"]
    data["unit_kind"] = product["unit_kind"]
    data["updated_at"] = firestore.SERVER_TIMESTAMP

    ref.update(data)
    return _with_variant_labels(doc_to_dict(ref.get()))


@router.delete("/admin/items/{item_id}", status_code=204)
def delete_item(item_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(item_id)
    if not ref.get().exists:
        raise HTTPException(404, "Item not found")
    ref.delete()
