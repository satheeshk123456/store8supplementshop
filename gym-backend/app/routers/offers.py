from fastapi import APIRouter, Depends, HTTPException

from app.firebase import get_db, firestore
from app.schemas import Offer, OfferIn
from app.security import get_current_admin
from app.utils import doc_to_dict

router = APIRouter(tags=["offers"])
COLLECTION = "offers"


@router.get("/offers", response_model=list[Offer])
def list_offers():
    """Public: active offer banners for the strip shown at the top of the storefront, in the
    order the admin set. Purely marketing copy — never changes MRP/price on any product.

    Filters on `is_active` and sorts on `order` in Python rather than asking Firestore to sort
    (i.e. no `.order_by()` on the query) — combining a filter on one field with a sort on
    another needs a Firestore composite index, and this collection doesn't have one declared
    (see firestore.indexes.json). Without this, the very first real request 500s until someone
    notices and manually creates that index from a link buried in the server error — same class
    of bug already fixed once for /customers/me/orders, avoided here the same way.
    """
    db = get_db()
    docs = db.collection(COLLECTION).where(filter=firestore.FieldFilter("is_active", "==", True)).stream()
    offers = [doc_to_dict(d) for d in docs]
    offers.sort(key=lambda o: o.get("order", 0))
    return offers


@router.get("/admin/offers", response_model=list[Offer])
def admin_list_offers(admin=Depends(get_current_admin)):
    db = get_db()
    docs = db.collection(COLLECTION).order_by("order").stream()
    return [doc_to_dict(d) for d in docs]


@router.post("/admin/offers", response_model=Offer, status_code=201)
def create_offer(payload: OfferIn, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document()
    data = payload.model_dump()
    data["created_at"] = data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.set(data)
    return doc_to_dict(ref.get())


@router.put("/admin/offers/{offer_id}", response_model=Offer)
def update_offer(offer_id: str, payload: OfferIn, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(offer_id)
    if not ref.get().exists:
        raise HTTPException(404, "Offer not found")
    data = payload.model_dump()
    data["updated_at"] = firestore.SERVER_TIMESTAMP
    ref.update(data)
    return doc_to_dict(ref.get())


@router.delete("/admin/offers/{offer_id}", status_code=204)
def delete_offer(offer_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(offer_id)
    if not ref.get().exists:
        raise HTTPException(404, "Offer not found")
    ref.delete()
