from fastapi import APIRouter, Depends, HTTPException

from app.firebase import get_db, firestore
from app.schemas import Brand, BrandIn
from app.security import get_current_admin
from app.utils import doc_to_dict, slugify

router = APIRouter(tags=["brands"])
COLLECTION = "brands"


@router.get("/brands", response_model=list[Brand])
def list_brands():
    """Public: active brands (used for the brand filter after picking a product)."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .order_by("name")
        .stream()
    )
    return [doc_to_dict(d) for d in docs]


@router.get("/admin/brands", response_model=list[Brand])
def admin_list_brands(admin=Depends(get_current_admin)):
    db = get_db()
    docs = db.collection(COLLECTION).order_by("name").stream()
    return [doc_to_dict(d) for d in docs]


@router.post("/admin/brands", response_model=Brand, status_code=201)
def create_brand(payload: BrandIn, admin=Depends(get_current_admin)):
    db = get_db()
    doc_id = slugify(payload.name)
    ref = db.collection(COLLECTION).document(doc_id)
    if ref.get().exists:
        raise HTTPException(409, "A brand with this name already exists")
    data = payload.model_dump()
    data["created_at"] = data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.set(data)
    return doc_to_dict(ref.get())


@router.put("/admin/brands/{brand_id}", response_model=Brand)
def update_brand(brand_id: str, payload: BrandIn, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(brand_id)
    if not ref.get().exists:
        raise HTTPException(404, "Brand not found")
    data = payload.model_dump()
    data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.update(data)
    return doc_to_dict(ref.get())


@router.delete("/admin/brands/{brand_id}", status_code=204)
def delete_brand(brand_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(brand_id)
    if not ref.get().exists:
        raise HTTPException(404, "Brand not found")
    in_use = (
        db.collection("items")
        .where(filter=firestore.FieldFilter("brand_id", "==", brand_id))
        .limit(1)
        .get()
    )
    if in_use:
        raise HTTPException(409, "Brand has products listed — remove those first")
    ref.delete()
