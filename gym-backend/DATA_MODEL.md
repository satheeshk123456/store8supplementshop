# Store 8 — Firestore Data Model

Everything is stored in **Cloud Firestore**. The backend (FastAPI + `firebase-admin`) is the
**only** thing allowed to talk to Firestore — the React storefront and the Flutter admin app never
call Firestore directly for catalog/order data (see `firestore.rules`, which denies all client
reads/writes). This keeps the whole system's security surface to one place: the API.

Firebase Auth is the one exception — the Flutter admin app signs in directly against Firebase Auth
(email/password) because that's what Firebase Auth is designed for. The backend then verifies the
ID token on every admin request.

## Collections

### `categories`
The 8 goal-based categories shown on the storefront home page.
```
id            string (doc id, slug e.g. "weight-gain")
name          string   "Weight Gain"
tagline       string   "Gain weight the right way"
description   string   "Gain weight the right way"
icon          string   name of a bundled icon (e.g. "weight-gain") — not an uploaded image,
                        keeps the storefront fast; falls back to a default icon if missing
order         number   display order (1-8)
is_active     bool
created_at / updated_at   timestamp
```

### `products`
A **product type** (e.g. "Whey Protein", "Creatine Monohydrate"). Independent of brand.
One product type can belong to more than one category (Whey Protein appears under both
"Weight Gain" and "Muscle Building"), so `category_ids` is an array.
```
id            string (doc id, slug e.g. "whey-protein")
name          string
category_ids  array<string>   references categories.id
description   string
unit_kind     string   "weight" | "volume" | "count"
              -> tells the storefront/admin which unit selector to render
              ("kg/g" for weight, "L/ml" for liquids, "capsules/tablets" for count)
is_active     bool
created_at / updated_at
```

### `items`
The sellable thing: a specific **brand's version of a product**, with one or more purchasable
variants (sizes). This is what actually has a price/stock and is what gets added to the cart.
```
id            string (doc id, auto)
product_id    string   references products.id
brand_id      string   references brands.id
title         string   optional override, e.g. "Gold Standard 100% Whey"
flavor        string   optional, e.g. "Chocolate"
description   string
images        array<string>   Firebase Storage public URLs
variants      array<Variant>
is_active     bool
is_featured   bool
created_at / updated_at

Variant (subobject, no separate collection — variants always belong to one item):
  id          string (short random id, generated on create)
  unit        string   "kg" | "g" | "l" | "ml" | "capsules" | "tablets"
  value       number   e.g. 1, 2.2, 5, 500  (the "how much" — 1kg, 500ml, 60 capsules)
  label       string   derived, e.g. "1 kg" / "500 ml" / "60 capsules" (computed by API, not stored)
  mrp         number   optional strike-through price
  price       number   selling price (INR)
  stock_qty   number   >=0
  sku         string   optional
  is_active   bool
```

### `brands`
The 24 brands from the brand catalogue.
```
id            string (doc id, slug e.g. "optimum-nutrition")
name          string
logo          string   Firebase Storage public URL (optional)
is_active     bool
created_at / updated_at
```

### `orders`
Created by the public storefront (guest checkout, no login, no payment).
```
id                string (doc id, auto)
order_number      string   human-friendly, e.g. "S8-20260815-0001"
customer          { name, phone, address, city, pincode, note }
items             array<OrderLine>
  OrderLine: { item_id, product_name, brand_name, variant_label, unit, qty, price, subtotal }
subtotal          number
total_amount      number   (subtotal; no payment/shipping calc yet)
status            string   "pending" | "confirmed" | "packed" | "shipped" | "delivered" | "cancelled"
payment_status    string   "not_required" (placeholder for when payment is added later)
notified          bool     whether the FCM push to the admin app succeeded
created_at / updated_at
```

### `admins`
Authorization allow-list. A Firebase Auth account can log in to the Flutter app, but the backend
only treats it as an admin if its `uid` also has a doc here (defense in depth — Firebase Auth
alone isn't used as the authorization source of truth).
```
id (doc id)   = Firebase Auth uid
email         string
name          string
role          string   "owner" | "staff"
is_active     bool
created_at
```

### `device_tokens`
FCM registration tokens for admin devices, so a push can be sent the moment an order is placed —
this is what makes the "app closed" / "network was off, now on" notification requirement work:
FCM queues the message against the token and Google's push infra delivers it as soon as the
device is reachable again, with zero code needed on our side for the offline case.
```
id (doc id)   = the FCM token itself
admin_uid     string
platform      string   "android" | "ios" | "web"
created_at
last_seen_at
```

## Why this shape
- **Category → Product → Brand-item → Variant** matches exactly how the storefront browsing flow
  and the admin "add product" flow both need to work (same 4-step structure the client asked for).
- Keeping `variants` embedded in the `item` doc (instead of a 4th collection) means adding a new
  size is a single-document update — simpler for a beginner backend and still well within
  Firestore's 1 MiB document limit for a supplement catalog.
- `unit_kind` on the product (not hardcoded per item) is what lets the UI automatically show
  **kg/g for solids** (protein, creatine, oats...) and **L/ml for liquids** (fish oil, MCT, etc.)
  without any per-product `if` statements — it's fully data-driven, nothing hardcoded.
