"""Pydantic request/response models, grouped by domain."""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field, field_validator

UnitKind = Literal["weight", "volume", "count"]
Unit = Literal["kg", "g", "l", "ml", "capsules", "tablets"]
# "stock_issue" is never set directly by an admin action — it's derived automatically whenever
# any line on the order is marked "unavailable" during the physical-stock check (see
# admin_set_line_availability in routers/orders.py), and cleared back to "pending" once every
# line is available again.
OrderStatus = Literal["pending", "confirmed", "packed", "shipped", "delivered", "cancelled", "stock_issue"]
# Set by the admin app during the physical-stock check that happens before an order can be
# confirmed — see WHY_ADMIN_CONFIRMATION in the client brief: website stock and physical-shop
# stock are the same limited pool, so what showed as available online can still turn out to be
# sold in person by the time the shop checks.
LineAvailability = Literal["available", "unavailable"]
# What the customer picks when a line they ordered is unavailable — see OrderConfirmation /
# MyOrders on the storefront, which is the only place a guest customer can respond (no login).
CustomerChoice = Literal["notify_me", "suggest_alternative"]

UNIT_LABELS = {
    "kg": "kg", "g": "g", "l": "L", "ml": "ml", "capsules": "capsules", "tablets": "tablets",
}

UNITS_BY_KIND = {
    "weight": ["kg", "g"],
    "volume": ["l", "ml"],
    "count": ["capsules", "tablets"],
}


def format_variant_label(unit: str, value: float) -> str:
    v = int(value) if float(value).is_integer() else value
    return f"{v} {UNIT_LABELS.get(unit, unit)}"


# ---------- Category ----------
class CategoryIn(BaseModel):
    name: str = Field(min_length=2, max_length=60)
    tagline: str = Field(default="", max_length=120)
    description: str = Field(default="", max_length=300)
    icon: str = Field(default="default", max_length=60)
    order: int = Field(default=0, ge=0, le=999)
    is_active: bool = True


class Category(CategoryIn):
    id: str
    created_at: str | None = None
    updated_at: str | None = None


# ---------- Brand ----------
class BrandIn(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    logo: str = Field(default="", max_length=500)
    is_active: bool = True


class Brand(BrandIn):
    id: str
    created_at: str | None = None
    updated_at: str | None = None


# ---------- Product (type) ----------
class ProductIn(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    category_ids: list[str] = Field(default_factory=list)
    # Free-text grouping shown within a category page (e.g. "Protein Powders" inside "Muscle
    # Building & Protein") — optional and unstructured on purpose, so the shop can introduce
    # subcategories gradually without needing a whole separate admin screen for them.
    subcategory: str = Field(default="", max_length=80)
    description: str = Field(default="", max_length=1000)
    unit_kind: UnitKind = "weight"
    is_active: bool = True

    @field_validator("category_ids")
    @classmethod
    def at_least_one_category(cls, v):
        if not v:
            raise ValueError("Select at least one category")
        return v


class Product(ProductIn):
    id: str
    created_at: str | None = None
    updated_at: str | None = None


# ---------- Item (brand + product + variants) ----------
class VariantIn(BaseModel):
    unit: Unit
    value: float = Field(gt=0)
    mrp: float | None = Field(default=None, ge=0)
    price: float = Field(ge=0)  # Store 8's regular selling price
    # Optional promotional price, shown struck-through against `price` when set and lower than
    # it — left unset (None) until the shop actually runs an offer on a given size.
    offer_price: float | None = Field(default=None, ge=0)
    stock_qty: int = Field(default=0, ge=0)
    sku: str = Field(default="", max_length=60)
    is_active: bool = True

    @field_validator("offer_price")
    @classmethod
    def offer_must_beat_price(cls, v, info):
        if v is not None and "price" in info.data and v > info.data["price"]:
            raise ValueError("Offer price can't be higher than the regular price")
        return v


class Variant(VariantIn):
    id: str
    label: str


class ItemIn(BaseModel):
    product_id: str
    brand_id: str
    title: str = Field(default="", max_length=150)
    flavor: str = Field(default="", max_length=60)
    description: str = Field(default="", max_length=1000)
    # All optional and free-text on purpose — filled in gradually per product, not required to
    # create a listing (label/price/stock matter far more for launch than these).
    ingredients: str = Field(default="", max_length=2000)
    benefits: str = Field(default="", max_length=2000)
    usage: str = Field(default="", max_length=1000)
    # e.g. "Sealed & sourced directly from Optimum Nutrition India" — shown on the storefront
    # to reassure customers this isn't a grey-market import, a common supplement-shopping worry.
    authenticity_info: str = Field(default="", max_length=1000)
    # e.g. "Consult a physician before use if pregnant" — shown on the storefront alongside
    # usage instructions.
    warnings: str = Field(default="", max_length=1000)
    images: list[str] = Field(default_factory=list)
    variants: list[VariantIn] = Field(default_factory=list)
    is_active: bool = True
    is_featured: bool = False

    @field_validator("variants")
    @classmethod
    def at_least_one_variant(cls, v):
        if not v:
            raise ValueError("Add at least one size/variant")
        return v


class Item(BaseModel):
    id: str
    product_id: str
    brand_id: str
    title: str = ""
    flavor: str = ""
    description: str = ""
    ingredients: str = ""
    benefits: str = ""
    usage: str = ""
    authenticity_info: str = ""
    warnings: str = ""
    images: list[str] = Field(default_factory=list)
    variants: list[Variant] = Field(default_factory=list)
    is_active: bool = True
    is_featured: bool = False
    # denormalized for convenient storefront rendering
    product_name: str | None = None
    brand_name: str | None = None
    unit_kind: UnitKind | None = None
    created_at: str | None = None
    updated_at: str | None = None


# ---------- Orders ----------
class OrderLineIn(BaseModel):
    item_id: str
    variant_id: str
    qty: int = Field(gt=0, le=50)


class CustomerIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    phone: str = Field(min_length=8, max_length=15)
    address: str = Field(min_length=5, max_length=300)
    city: str = Field(default="", max_length=80)
    pincode: str = Field(default="", max_length=10)
    note: str = Field(default="", max_length=300)

    @field_validator("phone")
    @classmethod
    def digits_only(cls, v: str):
        cleaned = "".join(ch for ch in v if ch.isdigit() or ch == "+")
        if len(cleaned) < 8:
            raise ValueError("Enter a valid phone number")
        return cleaned


class OrderCreate(BaseModel):
    customer: CustomerIn
    lines: list[OrderLineIn] = Field(min_length=1, max_length=50)
    # Set only when the customer is logged in (optional account system — see customers.py).
    # Guest checkout never sends this, and the endpoint works exactly the same either way; it
    # just lets a logged-in customer's orders show up under "My Account" later without them
    # having to re-enter the order number + phone every time.
    customer_uid: str | None = None


class OrderLineAlternative(BaseModel):
    """
    What the admin fills in on the "Suggest a suitable alternative product with special
    offers" screen once a customer picks "Suggest an Alternative" for an unavailable line.
    IMPORTANT (per the client brief): `final_price` is a one-off override for this particular
    order/customer only — it never changes the common Store 8 Customer Price every visitor sees
    on the storefront, which lives entirely on the catalog item's own `price`/`mrp` fields.
    """
    item_id: str
    variant_id: str
    product_name: str
    brand_name: str
    variant_label: str
    # The alternative's own normal Store 8 Customer Price, for reference/display.
    price: float
    # Free text describing the discount / combo / gift, if any — admin's call, per order.
    special_offer: str = ""
    # What this customer actually pays for the alternative if they accept. Defaults to `price`
    # when the admin doesn't type an override.
    final_price: float
    status: Literal["suggested", "customer_accepted", "customer_declined"] = "suggested"


class OrderLine(BaseModel):
    item_id: str
    variant_id: str
    product_name: str
    brand_name: str
    variant_label: str
    unit: str
    qty: int
    price: float
    subtotal: float
    availability: LineAvailability = "available"
    customer_choice: CustomerChoice | None = None
    alternative: OrderLineAlternative | None = None


class Order(BaseModel):
    id: str
    order_number: str
    customer: CustomerIn
    items: list[OrderLine]
    subtotal: float
    total_amount: float
    status: OrderStatus
    # "not_required" until the admin has confirmed physical stock and shared a payment link;
    # "link_shared" once payment_link is set. No online payment gateway exists — the link itself
    # is shared with the customer over WhatsApp by the admin, outside this system.
    payment_status: str = "not_required"
    payment_link: str | None = None
    notified: bool = False
    customer_uid: str | None = None
    created_at: str | None = None
    updated_at: str | None = None


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class LineAvailabilityIn(BaseModel):
    availability: LineAvailability


class PaymentLinkIn(BaseModel):
    payment_link: str = Field(min_length=4, max_length=500)


class CustomerChoiceIn(BaseModel):
    phone: str = Field(min_length=8, max_length=15)
    choice: CustomerChoice


class AlternativeSuggestionIn(BaseModel):
    """Admin picks a currently-available replacement item/variant from the catalog."""
    item_id: str
    variant_id: str
    special_offer: str = Field(default="", max_length=300)
    # Leave unset to just charge the alternative's own normal price with no special deal.
    final_price: float | None = Field(default=None, ge=0)


class AlternativeResponseIn(BaseModel):
    phone: str = Field(min_length=8, max_length=15)
    accept: bool


# ---------- Customers (optional login) ----------
# Pricing note: a customer account changes NOTHING about price. Every visitor — logged in or
# not — sees the same MRP + common Store 8 Customer Price on every product. Logging in only
# unlocks an order-history view; it is never looked at when computing what an order costs.
class CustomerProfileIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    phone: str = Field(default="", max_length=15)

    @field_validator("phone")
    @classmethod
    def digits_only(cls, v: str):
        if not v:
            return v
        cleaned = "".join(ch for ch in v if ch.isdigit() or ch == "+")
        if len(cleaned) < 8:
            raise ValueError("Enter a valid phone number")
        return cleaned


class CustomerProfile(BaseModel):
    uid: str
    name: str = ""
    phone: str = ""
    email: str = ""
    created_at: str | None = None
    updated_at: str | None = None


# ---------- Device tokens ----------
class DeviceTokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: Literal["android", "ios", "web"] = "android"


# ---------- Uploads ----------
class UploadResponse(BaseModel):
    url: str
    public_id: str
