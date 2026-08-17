from fastapi import APIRouter, Depends, HTTPException

from app.firebase import get_db, firestore
from app.schemas import Category, CategoryIn
from app.security import get_current_admin
from app.utils import doc_to_dict, now_iso, slugify

router = APIRouter(tags=["categories"])
COLLECTION = "categories"


@router.get("/categories", response_model=list[Category])
def list_categories():
    """Public: active categories, storefront home page."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .order_by("order")
        .stream()
    )
    return [doc_to_dict(d) for d in docs]


@router.get("/categories/{category_id}", response_model=Category)
def get_category(category_id: str):
    """Public: single category (used for breadcrumbs on the products page)."""
    db = get_db()
    doc = db.collection(COLLECTION).document(category_id).get()
    if not doc.exists or not doc.to_dict().get("is_active", False):
        raise HTTPException(404, "Category not found")
    return doc_to_dict(doc)


@router.get("/admin/categories", response_model=list[Category])
def admin_list_categories(admin=Depends(get_current_admin)):
    db = get_db()
    docs = db.collection(COLLECTION).order_by("order").stream()
    return [doc_to_dict(d) for d in docs]


@router.post("/admin/categories", response_model=Category, status_code=201)
def create_category(payload: CategoryIn, admin=Depends(get_current_admin)):
    db = get_db()
    doc_id = slugify(payload.name)
    ref = db.collection(COLLECTION).document(doc_id)
    if ref.get().exists:
        raise HTTPException(409, "A category with this name already exists")
    data = payload.model_dump()
    data["created_at"] = data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.set(data)
    return doc_to_dict(ref.get())


@router.put("/admin/categories/{category_id}", response_model=Category)
def update_category(category_id: str, payload: CategoryIn, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(category_id)
    if not ref.get().exists:
        raise HTTPException(404, "Category not found")
    data = payload.model_dump()
    data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.update(data)
    return doc_to_dict(ref.get())


@router.delete("/admin/categories/{category_id}", status_code=204)
def delete_category(category_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(category_id)
    if not ref.get().exists:
        raise HTTPException(404, "Category not found")
    in_use = (
        db.collection("products")
        .where(filter=firestore.FieldFilter("category_ids", "array_contains", category_id))
        .limit(1)
        .get()
    )
    if in_use:
        raise HTTPException(409, "Category has products in it — move or delete those first")
    ref.delete()
