from fastapi import APIRouter, Depends, HTTPException

from app.firebase import get_db, firestore
from app.schemas import Product, ProductIn
from app.security import get_current_admin
from app.utils import doc_to_dict, slugify

router = APIRouter(tags=["products"])
COLLECTION = "products"


@router.get("/categories/{category_id}/products", response_model=list[Product])
def list_products_by_category(category_id: str):
    """Public: step 2 of the storefront flow — products inside a chosen category."""
    db = get_db()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("is_active", "==", True))
        .where(filter=firestore.FieldFilter("category_ids", "array_contains", category_id))
        .stream()
    )
    return [doc_to_dict(d) for d in docs]


@router.get("/products/{product_id}", response_model=Product)
def get_product(product_id: str):
    db = get_db()
    doc = db.collection(COLLECTION).document(product_id).get()
    if not doc.exists:
        raise HTTPException(404, "Product not found")
    return doc_to_dict(doc)


@router.get("/admin/products", response_model=list[Product])
def admin_list_products(admin=Depends(get_current_admin)):
    db = get_db()
    docs = db.collection(COLLECTION).order_by("name").stream()
    return [doc_to_dict(d) for d in docs]


@router.post("/admin/products", response_model=Product, status_code=201)
def create_product(payload: ProductIn, admin=Depends(get_current_admin)):
    db = get_db()
    _validate_categories(db, payload.category_ids)
    doc_id = slugify(payload.name)
    ref = db.collection(COLLECTION).document(doc_id)
    if ref.get().exists:
        raise HTTPException(409, "A product with this name already exists")
    data = payload.model_dump()
    data["created_at"] = data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.set(data)
    return doc_to_dict(ref.get())


@router.put("/admin/products/{product_id}", response_model=Product)
def update_product(product_id: str, payload: ProductIn, admin=Depends(get_current_admin)):
    db = get_db()
    _validate_categories(db, payload.category_ids)
    ref = db.collection(COLLECTION).document(product_id)
    if not ref.get().exists:
        raise HTTPException(404, "Product not found")
    data = payload.model_dump()
    data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.update(data)
    return doc_to_dict(ref.get())


@router.delete("/admin/products/{product_id}", status_code=204)
def delete_product(product_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(product_id)
    if not ref.get().exists:
        raise HTTPException(404, "Product not found")
    in_use = (
        db.collection("items")
        .where(filter=firestore.FieldFilter("product_id", "==", product_id))
        .limit(1)
        .get()
    )
    if in_use:
        raise HTTPException(409, "Product has brand listings — remove those first")
    ref.delete()


def _validate_categories(db, category_ids: list[str]) -> None:
    for cid in category_ids:
        if not db.collection("categories").document(cid).get().exists:
            raise HTTPException(400, f"Unknown category_id: {cid}")
