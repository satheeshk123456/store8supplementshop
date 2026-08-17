import logging

from fastapi import APIRouter, Depends, HTTPException, Request

from app.firebase import get_db, firestore
from app.notifications import notify_admins_new_order
from app.rate_limit import limiter
from app.schemas import Order, OrderCreate, OrderLineIn, OrderStatusUpdate, format_variant_label
from app.security import get_current_admin
from app.utils import doc_to_dict, new_order_number

router = APIRouter(tags=["orders"])
COLLECTION = "orders"
logger = logging.getLogger("store8")


@router.post("/orders", response_model=Order, status_code=201)
@limiter.limit("6/minute")
def create_order(request: Request, payload: OrderCreate):
    """
    Public: guest checkout, no login, no payment yet (payment_status stays "not_required").
    Stock is checked and decremented atomically inside a Firestore transaction so two
    customers can't both "win" the last unit of something.
    """
    db = get_db()
    order_ref = db.collection(COLLECTION).document()

    # Merge duplicate (item, variant) lines so stock is decremented correctly even if the
    # same size was sent twice in one request — never trust the client to have deduped its cart.
    payload.lines = _merge_duplicate_lines(payload.lines)

    transaction = db.transaction()
    order_data = _run_order_transaction(transaction, db, order_ref, payload)

    ok = False
    try:
        ok = notify_admins_new_order(
            order_ref.id, order_data["order_number"], order_data["total_amount"], payload.customer.name
        )
    except Exception:
        logger.exception("Failed to send order notification for %s", order_data["order_number"])
    order_ref.update({"notified": ok})
    order_data["notified"] = ok

    return doc_to_dict(order_ref.get())


def _merge_duplicate_lines(lines: list[OrderLineIn]) -> list[OrderLineIn]:
    merged: dict[tuple[str, str], int] = {}
    order: list[tuple[str, str]] = []
    for line in lines:
        key = (line.item_id, line.variant_id)
        if key not in merged:
            order.append(key)
        merged[key] = merged.get(key, 0) + line.qty
    try:
        return [OrderLineIn(item_id=k[0], variant_id=k[1], qty=merged[k]) for k in order]
    except Exception:
        raise HTTPException(400, "Quantity for one of the items is too high")


@firestore.transactional
def _run_order_transaction(transaction, db, order_ref, payload: OrderCreate) -> dict:
    # 1) READS — must all happen before any writes in a Firestore transaction.
    item_refs, item_snaps = [], []
    for line in payload.lines:
        ref = db.collection("items").document(line.item_id)
        snap = ref.get(transaction=transaction)
        if not snap.exists:
            raise HTTPException(400, f"An item in your cart is no longer available")
        item_refs.append(ref)
        item_snaps.append(snap)

    order_lines = []
    subtotal = 0.0
    variant_updates = []  # (ref, new_variants_array)

    for line, ref, snap in zip(payload.lines, item_refs, item_snaps):
        item = snap.to_dict()
        if not item.get("is_active", True):
            raise HTTPException(409, f"{item.get('product_name', 'An item')} is currently unavailable")
        variants = item.get("variants", [])
        idx = next((i for i, v in enumerate(variants) if v["id"] == line.variant_id), None)
        if idx is None:
            raise HTTPException(400, "Selected size is no longer available")
        variant = variants[idx]
        if not variant.get("is_active", True):
            raise HTTPException(409, "Selected size is currently unavailable")
        if variant["stock_qty"] < line.qty:
            raise HTTPException(
                409,
                f"Only {variant['stock_qty']} left of {item.get('product_name')} "
                f"({format_variant_label(variant['unit'], variant['value'])})",
            )

        new_variants = [dict(v) for v in variants]
        new_variants[idx]["stock_qty"] = variant["stock_qty"] - line.qty
        variant_updates.append((ref, new_variants))

        line_subtotal = round(variant["price"] * line.qty, 2)
        subtotal += line_subtotal
        order_lines.append(
            {
                "item_id": ref.id,
                "variant_id": line.variant_id,
                "product_name": item.get("product_name", ""),
                "brand_name": item.get("brand_name", ""),
                "variant_label": format_variant_label(variant["unit"], variant["value"]),
                "unit": variant["unit"],
                "qty": line.qty,
                "price": variant["price"],
                "subtotal": line_subtotal,
            }
        )

    order_data = {
        "order_number": new_order_number(),
        "customer": payload.customer.model_dump(),
        "items": order_lines,
        "subtotal": round(subtotal, 2),
        "total_amount": round(subtotal, 2),
        "status": "pending",
        "payment_status": "not_required",
        "notified": False,
        "created_at": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }

    # 2) WRITES
    transaction.set(order_ref, order_data)
    for ref, new_variants in variant_updates:
        transaction.update(ref, {"variants": new_variants})

    return order_data


@router.get("/admin/orders", response_model=list[Order])
def admin_list_orders(status: str | None = None, limit: int = 50, admin=Depends(get_current_admin)):
    db = get_db()
    query = db.collection(COLLECTION)
    if status:
        query = query.where(filter=firestore.FieldFilter("status", "==", status))
    docs = query.order_by("created_at", direction=firestore.Query.DESCENDING).limit(min(limit, 200)).stream()
    return [doc_to_dict(d) for d in docs]


@router.get("/admin/orders/{order_id}", response_model=Order)
def admin_get_order(order_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    doc = db.collection(COLLECTION).document(order_id).get()
    if not doc.exists:
        raise HTTPException(404, "Order not found")
    return doc_to_dict(doc)


@router.put("/admin/orders/{order_id}/status", response_model=Order)
def admin_update_order_status(order_id: str, payload: OrderStatusUpdate, admin=Depends(get_current_admin)):
    db = get_db()
    ref = db.collection(COLLECTION).document(order_id)
    if not ref.get().exists:
        raise HTTPException(404, "Order not found")
    ref.update({"status": payload.status, "updated_at": firestore.SERVER_TIMESTAMP})
    return doc_to_dict(ref.get())
