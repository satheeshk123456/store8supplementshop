import logging

from fastapi import APIRouter, Depends, HTTPException, Request

from app.firebase import get_db, firestore
from app.notifications import notify_admins_new_order
from app.rate_limit import limiter
from app.schemas import (
    AlternativeResponseIn,
    AlternativeSuggestionIn,
    CustomerChoiceIn,
    LineAvailabilityIn,
    Order,
    OrderCreate,
    OrderLineIn,
    OrderStatusUpdate,
    PaymentLinkIn,
    format_variant_label,
)
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


@router.get("/orders/track", response_model=Order)
@limiter.limit("15/minute")
def track_order(request: Request, order_number: str, phone: str):
    """
    Public: look up a single order by order_number + the phone number given at checkout — both
    together act as a shared secret so a stranger can't browse other customers' orders just by
    guessing an id (see the comment in the frontend's OrderConfirmation page for why order-by-id
    alone was deliberately avoided). Used for the storefront's "My Orders" / order tracking page.
    """
    db = get_db()
    cleaned_number = order_number.strip().upper()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("order_number", "==", cleaned_number))
        .limit(1)
        .get()
    )
    if not docs:
        raise HTTPException(404, "No order found with that order number and phone number.")
    doc = docs[0]
    order = doc.to_dict()
    stored_digits = "".join(ch for ch in order.get("customer", {}).get("phone", "") if ch.isdigit())
    given_digits = "".join(ch for ch in phone if ch.isdigit())
    # Compare the last 8 digits rather than requiring an exact full-string match, so trivial
    # formatting differences (+91 prefix, spaces, a leading 0) don't wrongly reject a real match.
    if len(given_digits) < 8 or stored_digits[-8:] != given_digits[-8:]:
        raise HTTPException(404, "No order found with that order number and phone number.")
    return doc_to_dict(doc)


@router.put("/orders/{order_number}/lines/{item_id}/{variant_id}/customer-choice", response_model=Order)
@limiter.limit("15/minute")
def submit_customer_choice(
    request: Request,
    order_number: str,
    item_id: str,
    variant_id: str,
    payload: CustomerChoiceIn,
):
    """
    Public, guest-safe: once the admin's physical-stock check marks a line "unavailable", the
    customer picks "Notify me" or "Suggest an alternative" here (shown on the storefront's order
    tracking / My Orders page). Same order_number + phone matching as /orders/track — no login,
    the two together act as a shared secret so a stranger can't answer on someone else's order.
    """
    db = get_db()
    cleaned_number = order_number.strip().upper()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("order_number", "==", cleaned_number))
        .limit(1)
        .get()
    )
    if not docs:
        raise HTTPException(404, "Order not found")
    doc = docs[0]
    order = doc.to_dict()
    stored_digits = "".join(ch for ch in order.get("customer", {}).get("phone", "") if ch.isdigit())
    given_digits = "".join(ch for ch in payload.phone if ch.isdigit())
    if len(given_digits) < 8 or stored_digits[-8:] != given_digits[-8:]:
        raise HTTPException(404, "Order not found")

    items = order.get("items", [])
    line = next((l for l in items if l["item_id"] == item_id and l["variant_id"] == variant_id), None)
    if line is None:
        raise HTTPException(404, "Item not found on this order")
    if line.get("availability") != "unavailable":
        raise HTTPException(409, "This item doesn't need a response")

    line["customer_choice"] = payload.choice
    doc.reference.update({"items": items, "updated_at": firestore.SERVER_TIMESTAMP})
    return doc_to_dict(doc.reference.get())


def _find_order_by_phone(db, order_number: str, phone: str):
    """Shared lookup for every guest-facing (no login) order endpoint: order_number + the phone
    given at checkout together act as a shared secret, same reasoning as /orders/track."""
    cleaned_number = order_number.strip().upper()
    docs = (
        db.collection(COLLECTION)
        .where(filter=firestore.FieldFilter("order_number", "==", cleaned_number))
        .limit(1)
        .get()
    )
    if not docs:
        raise HTTPException(404, "Order not found")
    doc = docs[0]
    order = doc.to_dict()
    stored_digits = "".join(ch for ch in order.get("customer", {}).get("phone", "") if ch.isdigit())
    given_digits = "".join(ch for ch in phone if ch.isdigit())
    if len(given_digits) < 8 or stored_digits[-8:] != given_digits[-8:]:
        raise HTTPException(404, "Order not found")
    return doc, order


@router.put("/orders/{order_number}/lines/{item_id}/{variant_id}/alternative-response", response_model=Order)
@limiter.limit("15/minute")
def respond_to_alternative(
    request: Request,
    order_number: str,
    item_id: str,
    variant_id: str,
    payload: AlternativeResponseIn,
):
    """
    Public, guest-safe: the customer accepts or declines the alternative product the admin
    suggested (see admin_suggest_alternative below). Accepting swaps this line over to the
    alternative — at the admin's one-off price for this order, never the storefront's common
    Store 8 Customer Price — and lets the normal stock-check / payment-link flow continue from
    there. Declining just records that so the admin knows to follow up another way.
    """
    db = get_db()
    doc, order = _find_order_by_phone(db, order_number, payload.phone)

    items = order.get("items", [])
    line = next((l for l in items if l["item_id"] == item_id and l["variant_id"] == variant_id), None)
    if line is None:
        raise HTTPException(404, "Item not found on this order")
    alt = line.get("alternative")
    if alt is None or alt.get("status") != "suggested":
        raise HTTPException(409, "No pending alternative suggestion for this item")

    if not payload.accept:
        alt["status"] = "customer_declined"
        doc.reference.update({"items": items, "updated_at": firestore.SERVER_TIMESTAMP})
        return doc_to_dict(doc.reference.get())

    transaction = db.transaction()
    _accept_alternative_transaction(transaction, db, alt, line["item_id"], line["variant_id"], line["qty"])

    line["item_id"] = alt["item_id"]
    line["variant_id"] = alt["variant_id"]
    line["product_name"] = alt["product_name"]
    line["brand_name"] = alt["brand_name"]
    line["variant_label"] = alt["variant_label"]
    line["price"] = alt["final_price"]
    line["subtotal"] = round(alt["final_price"] * line["qty"], 2)
    line["availability"] = "available"
    line["customer_choice"] = None
    alt["status"] = "customer_accepted"

    new_subtotal = round(sum(l["subtotal"] for l in items), 2)
    update = {
        "items": items,
        "subtotal": new_subtotal,
        "total_amount": new_subtotal,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }
    if order.get("status") in ("pending", "confirmed", "stock_issue"):
        any_unavailable = any(l.get("availability") == "unavailable" for l in items)
        update["status"] = "stock_issue" if any_unavailable else "pending"
    doc.reference.update(update)
    return doc_to_dict(doc.reference.get())


@firestore.transactional
def _accept_alternative_transaction(transaction, db, alt: dict, orig_item_id: str, orig_variant_id: str, qty: int):
    """
    Moves stock from the alternative variant to reflect the swap: reserves `qty` on the
    alternative (it's what will actually ship now) and, best-effort, returns `qty` to the
    original variant since it's no longer being fulfilled from that line.
    """
    alt_ref = db.collection("items").document(alt["item_id"])
    alt_snap = alt_ref.get(transaction=transaction)
    if not alt_snap.exists:
        raise HTTPException(409, "The suggested alternative is no longer available")
    alt_item = alt_snap.to_dict()
    alt_variants = alt_item.get("variants", [])
    alt_idx = next((i for i, v in enumerate(alt_variants) if v["id"] == alt["variant_id"]), None)
    if alt_idx is None or not alt_variants[alt_idx].get("is_active", True):
        raise HTTPException(409, "The suggested alternative is no longer available")
    if alt_variants[alt_idx]["stock_qty"] < qty:
        raise HTTPException(409, "Not enough stock left for the suggested alternative")

    same_doc = alt_ref.id == orig_item_id
    new_alt_variants = [dict(v) for v in alt_variants]
    new_alt_variants[alt_idx]["stock_qty"] -= qty

    if same_doc:
        orig_idx = next((i for i, v in enumerate(new_alt_variants) if v["id"] == orig_variant_id), None)
        if orig_idx is not None:
            new_alt_variants[orig_idx]["stock_qty"] += qty
        transaction.update(alt_ref, {"variants": new_alt_variants})
        return

    transaction.update(alt_ref, {"variants": new_alt_variants})
    orig_ref = db.collection("items").document(orig_item_id)
    orig_snap = orig_ref.get(transaction=transaction)
    if orig_snap.exists:
        orig_variants = orig_snap.to_dict().get("variants", [])
        orig_idx = next((i for i, v in enumerate(orig_variants) if v["id"] == orig_variant_id), None)
        if orig_idx is not None:
            new_orig_variants = [dict(v) for v in orig_variants]
            new_orig_variants[orig_idx]["stock_qty"] += qty
            transaction.update(orig_ref, {"variants": new_orig_variants})


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

        # Charge the offer price when the admin has set one (and it's actually lower than the
        # regular price — the schema validator already guarantees that at write time, this is
        # just a defensive re-check since we're reading raw dict data here, not a validated model).
        offer_price = variant.get("offer_price")
        effective_price = offer_price if offer_price is not None and offer_price < variant["price"] else variant["price"]

        line_subtotal = round(effective_price * line.qty, 2)
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
                "price": effective_price,
                "subtotal": line_subtotal,
                # Every line starts "available" — the website's own stock count said so. The
                # admin's physical-stock check (see routers/orders.py's admin_set_line_availability)
                # is what can flip this, since the physical shop sells from the same limited stock.
                "availability": "available",
                "customer_choice": None,
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
        "payment_link": None,
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
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Order not found")
    if payload.status == "confirmed":
        order = snap.to_dict()
        if any(line.get("availability") == "unavailable" for line in order.get("items", [])):
            raise HTTPException(409, "Resolve every unavailable item (see the Items list) before confirming this order")
    ref.update({"status": payload.status, "updated_at": firestore.SERVER_TIMESTAMP})
    return doc_to_dict(ref.get())


@router.put("/admin/orders/{order_id}/lines/{item_id}/{variant_id}/availability", response_model=Order)
def admin_set_line_availability(
    order_id: str,
    item_id: str,
    variant_id: str,
    payload: LineAvailabilityIn,
    admin=Depends(get_current_admin),
):
    """
    The admin's physical-stock check (see WHY_ADMIN_CONFIRMATION in the client brief): website
    stock and the physical shop's stock are the same limited pool, so a line that looked
    available when the order was placed can still turn out to be sold in person. Marking a line
    "unavailable" here automatically flips the order to "stock_issue" so the customer sees the
    Notify-me / Suggest-an-alternative choice on the storefront; marking it back "available"
    reverts the order to "pending" once no line is unavailable anymore.
    """
    db = get_db()
    ref = db.collection(COLLECTION).document(order_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Order not found")
    order = snap.to_dict()
    items = order.get("items", [])
    found = False
    for line in items:
        if line["item_id"] == item_id and line["variant_id"] == variant_id:
            line["availability"] = payload.availability
            if payload.availability == "available":
                line["customer_choice"] = None
            found = True
    if not found:
        raise HTTPException(404, "Order line not found")

    update = {"items": items, "updated_at": firestore.SERVER_TIMESTAMP}
    # Only auto-derive status while the order is still being worked — never override a shipment
    # already in motion (packed/shipped/delivered) or a cancelled order.
    if order.get("status") in ("pending", "confirmed", "stock_issue"):
        any_unavailable = any(line.get("availability") == "unavailable" for line in items)
        update["status"] = "stock_issue" if any_unavailable else "pending"
    ref.update(update)
    return doc_to_dict(ref.get())


@router.put("/admin/orders/{order_id}/lines/{item_id}/{variant_id}/alternative", response_model=Order)
def admin_suggest_alternative(
    order_id: str,
    item_id: str,
    variant_id: str,
    payload: AlternativeSuggestionIn,
    admin=Depends(get_current_admin),
):
    """
    The "Suggest a suitable alternative product with special offers" screen: admin picks a
    currently-available catalog item/variant to offer in place of the unavailable one, with an
    optional per-order special offer / discount price. This does NOT touch the alternative
    product's own storefront price — every customer still sees the same common Store 8
    Customer Price there; `final_price` only applies to this one order.
    """
    db = get_db()
    ref = db.collection(COLLECTION).document(order_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Order not found")
    order = snap.to_dict()
    items = order.get("items", [])
    line = next((l for l in items if l["item_id"] == item_id and l["variant_id"] == variant_id), None)
    if line is None:
        raise HTTPException(404, "Order line not found")

    alt_doc = db.collection("items").document(payload.item_id).get()
    if not alt_doc.exists:
        raise HTTPException(400, "Unknown alternative product")
    alt_item = alt_doc.to_dict()
    alt_variant = next((v for v in alt_item.get("variants", []) if v["id"] == payload.variant_id), None)
    if alt_variant is None:
        raise HTTPException(400, "Unknown alternative size")

    offer_price = alt_variant.get("offer_price")
    base_price = offer_price if offer_price is not None and offer_price < alt_variant["price"] else alt_variant["price"]
    final_price = payload.final_price if payload.final_price is not None else base_price

    line["alternative"] = {
        "item_id": payload.item_id,
        "variant_id": payload.variant_id,
        "product_name": alt_item.get("product_name", ""),
        "brand_name": alt_item.get("brand_name", ""),
        "variant_label": format_variant_label(alt_variant["unit"], alt_variant["value"]),
        "price": base_price,
        "special_offer": payload.special_offer.strip(),
        "final_price": final_price,
        "status": "suggested",
    }
    ref.update({"items": items, "updated_at": firestore.SERVER_TIMESTAMP})
    return doc_to_dict(ref.get())


@router.put("/admin/orders/{order_id}/payment-link", response_model=Order)
def admin_set_payment_link(order_id: str, payload: PaymentLinkIn, admin=Depends(get_current_admin)):
    """
    Only reachable once every line is available — no payment link goes out until the admin has
    actually confirmed physical stock, matching the client's required flow: Website Order →
    Admin Actual Physical Stock Check → Availability Confirm → Final Amount → Payment Link. The
    link itself is shared with the customer over WhatsApp by the admin, outside this system —
    this just records it against the order and marks the order confirmed.
    """
    db = get_db()
    ref = db.collection(COLLECTION).document(order_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Order not found")
    order = snap.to_dict()
    if any(line.get("availability") == "unavailable" for line in order.get("items", [])):
        raise HTTPException(409, "Resolve every unavailable item before sharing a payment link")
    ref.update(
        {
            "payment_link": payload.payment_link,
            "payment_status": "link_shared",
            "status": "confirmed",
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
    )
    return doc_to_dict(ref.get())
