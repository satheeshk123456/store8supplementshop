import logging

from fastapi import APIRouter, Depends

from app.firebase import firestore, get_db
from app.schemas import CustomerProfile, CustomerProfileIn, Order
from app.security import CurrentCustomer, get_current_customer
from app.utils import doc_to_dict

router = APIRouter(prefix="/customers/me", tags=["customers"])
logger = logging.getLogger("store8")


def _get_or_create_profile(db, customer: CurrentCustomer) -> dict:
    ref = db.collection("customers").document(customer.uid)
    snap = ref.get()
    if snap.exists:
        return doc_to_dict(snap)
    # First time this uid has ever called an authenticated endpoint (e.g. right after they
    # registered) — create a minimal profile automatically so GET never 404s for a real account.
    data = {
        "email": customer.email,
        "name": "",
        "phone": "",
        "created_at": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }
    ref.set(data)
    return doc_to_dict(ref.get())


@router.get("", response_model=CustomerProfile)
def get_my_profile(customer: CurrentCustomer = Depends(get_current_customer)):
    db = get_db()
    return _get_or_create_profile(db, customer)


@router.put("", response_model=CustomerProfile)
def update_my_profile(payload: CustomerProfileIn, customer: CurrentCustomer = Depends(get_current_customer)):
    """Called right after registration (to save name/phone collected on the sign-up form) and
    any time the customer edits their details from the Account page."""
    db = get_db()
    ref = db.collection("customers").document(customer.uid)
    snap = ref.get()
    update = {
        "name": payload.name.strip(),
        "phone": payload.phone.strip(),
        "email": customer.email,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }
    if snap.exists:
        ref.update(update)
    else:
        update["created_at"] = firestore.SERVER_TIMESTAMP
        ref.set(update)
    return doc_to_dict(ref.get())


@router.get("/orders", response_model=list[Order])
def list_my_orders(customer: CurrentCustomer = Depends(get_current_customer)):
    """Order history for the logged-in customer — every order they placed while logged in
    (customer_uid was attached at checkout, see routers/orders.py's create_order). Orders placed
    as a guest, before they had an account, still only show up via the order-number + phone
    tracker on the storefront's My Orders page, same as always."""
    db = get_db()
    docs = (
        db.collection("orders")
        .where(filter=firestore.FieldFilter("customer_uid", "==", customer.uid))
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .limit(100)
        .stream()
    )
    return [doc_to_dict(d) for d in docs]
