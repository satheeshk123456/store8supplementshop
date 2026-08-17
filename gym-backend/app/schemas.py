"""Pydantic request/response models, grouped by domain."""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field, field_validator

UnitKind = Literal["weight", "volume", "count"]
Unit = Literal["kg", "g", "l", "ml", "capsules", "tablets"]
OrderStatus = Literal["pending", "confirmed", "packed", "shipped", "delivered", "cancelled"]

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
    price: float = Field(ge=0)
    stock_qty: int = Field(default=0, ge=0)
    sku: str = Field(default="", max_length=60)
    is_active: bool = True


class Variant(VariantIn):
    id: str
    label: str


class ItemIn(BaseModel):
    product_id: str
    brand_id: str
    title: str = Field(default="", max_length=150)
    flavor: str = Field(default="", max_length=60)
    description: str = Field(default="", max_length=1000)
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


class Order(BaseModel):
    id: str
    order_number: str
    customer: CustomerIn
    items: list[OrderLine]
    subtotal: float
    total_amount: float
    status: OrderStatus
    payment_status: str = "not_required"
    notified: bool = False
    created_at: str | None = None
    updated_at: str | None = None


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


# ---------- Device tokens ----------
class DeviceTokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: Literal["android", "ios", "web"] = "android"


# ---------- Uploads ----------
class UploadResponse(BaseModel):
    url: str
    public_id: str
