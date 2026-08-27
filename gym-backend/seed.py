"""
Populates Firestore with the Store 8 catalogue: the 8 goal-based categories (with subcategories),
~44 product types, the 24 brands you deal in, and a small set of sample brand-listings (items)
with kg/g/L/ml/capsule variants so you can see the full Category -> Product -> Brand -> Variant
flow working end to end before you type in your real inventory (and real MRP/price/stock) through
the admin app.

This is SAMPLE DATA (placeholder prices/stock) — edit or delete it from the admin app once
you're adding your real catalogue. Safe to re-run: it skips anything that already exists.

Usage:
    cd gym-backend
    pip install -r requirements.txt
    # make sure .env has FIREBASE_SERVICE_ACCOUNT_FILE (or _B64) pointing at a valid key
    python seed.py                      # seed categories + brands + products + sample items
    python seed.py --catalog-only       # skip sample items, just categories/brands/products
    python seed.py --reset-catalog      # WIPES categories/brands/products/items first, then
                                         # reseeds fresh — use this once when the category names
                                         # or product list changed, so old ones don't linger
                                         # alongside the new ones. Never touches orders or admins.
    python seed.py --admin <uid> <email> <name>   # grant an existing Firebase Auth user admin access
    python seed.py --create-admin <email> <password> [name]
        # creates a NEW Firebase Auth user with that email/password (or reuses it if the email
        # already exists) and grants it admin access in one step — no need to touch the Firebase
        # Console. <email> must be a real email address format (e.g. admin@yourdomain.com);
        # Firebase Auth rejects bare usernames like "admin". <password> must be 6+ characters.
"""
import argparse
import re
import sys
from urllib.parse import quote_plus

from firebase_admin import auth

from app.firebase import init_firebase, get_db, firestore
from app.utils import short_id, slugify

# ---------------------------------------------------------------------------
# 1) Categories — the 8 goal-based categories Store 8 sells by.
# ---------------------------------------------------------------------------
CATEGORIES = [
    {"name": "Muscle Building & Protein", "tagline": "Build lean muscle & get stronger", "icon": "muscle-protein"},
    {"name": "Weight Gain", "tagline": "Gain weight the right way", "icon": "weight-gain"},
    {"name": "Performance & Workout", "tagline": "Train harder, push further", "icon": "performance-workout"},
    {"name": "Fat Loss & Weight Management", "tagline": "Burn fat & stay lean", "icon": "fat-loss"},
    {"name": "Healthy Foods & Nutrition", "tagline": "Everyday nutrition made easy", "icon": "healthy-foods"},
    {"name": "General Health & Wellness", "tagline": "Daily vitamins, minerals & herbal wellness", "icon": "general-health"},
    {"name": "Beauty, Skin & Recovery", "tagline": "Look better, sleep better, recover better", "icon": "beauty-skin-recovery"},
    {"name": "Overall Health & Support", "tagline": "Organ, digestive & everyday support", "icon": "overall-health"},
]

# ---------------------------------------------------------------------------
# 2) Brands (the 24 you deal in).
# ---------------------------------------------------------------------------
BRANDS = [
    "GXN Nutrition", "GNC", "Flex Wheeler", "Optimum Nutrition", "MuscleTech",
    "Labrada", "Pure Nutrition", "American Muscles", "Absolute Nutrition", "Rule 1",
    "One Science", "Dymatize", "Mutant", "MuscleBlaze", "WellCore",
    "WellBeing", "RC", "Alpino", "Kevin Levrone", "ISO Pure",
    "C4", "Nutrex", "Doctor's Choice", "Davisco",
]

# ---------------------------------------------------------------------------
# 3) Product types: name, unit_kind (weight -> kg/g, volume -> L/ml, count -> capsules/tablets),
#    which category slugs they belong to, and a subcategory label shown when grouping products
#    within a category page. category_ids can list more than one category — the same product
#    type is allowed to show up under more than one goal (e.g. Oats under both Weight Gain and
#    Healthy Foods & Nutrition) since that's genuinely how customers look for them.
# ---------------------------------------------------------------------------
MB = "muscle-building-protein"
WG = "weight-gain"
PW = "performance-workout"
FL = "fat-loss-weight-management"
HF = "healthy-foods-nutrition"
GH = "general-health-wellness"
BS = "beauty-skin-recovery"
OH = "overall-health-support"

PRODUCTS = [
    # -- Muscle Building & Protein --
    ("Whey Protein", "weight", [MB], "Protein Powders"),
    ("Whey Protein Isolate", "weight", [MB], "Protein Powders"),
    ("Hydrolyzed Whey Protein", "weight", [MB], "Protein Powders"),
    ("Creatine", "weight", [MB, PW], "Muscle & Strength Support"),
    ("Glutamine", "weight", [MB], "Muscle & Strength Support"),
    ("BCAA", "weight", [MB, PW], "Muscle & Strength Support"),

    # -- Weight Gain --
    ("Mass Gainer", "weight", [WG], "Gainers"),

    # -- Performance & Workout --
    ("Pre-Workout", "weight", [PW], "Pre-Workout & Pump"),
    ("Beta Alanine", "weight", [PW], "Pre-Workout & Pump"),
    ("Citrulline Malate", "weight", [PW], "Pre-Workout & Pump"),
    ("L-Arginine", "count", [PW], "Pre-Workout & Pump"),
    ("Nitric Oxide Booster", "count", [PW], "Pre-Workout & Pump"),

    # -- Fat Loss & Weight Management --
    ("Fat Burner", "count", [FL], "Fat Burners"),
    ("L-Carnitine", "volume", [FL, PW], "Fat Burners"),

    # -- Healthy Foods & Nutrition (cross-listed with Weight Gain where relevant) --
    ("Protein Oats", "weight", [HF, MB], "Everyday Foods"),
    ("Oats", "weight", [HF, WG], "Everyday Foods"),
    ("Peanut Butter", "weight", [HF, WG], "Everyday Foods"),

    # -- General Health & Wellness --
    ("Multivitamins", "count", [GH], "Vitamins"),
    ("Vitamin A", "count", [GH], "Vitamins"),
    ("Vitamin B Complex", "count", [GH], "Vitamins"),
    ("Vitamin C", "count", [GH], "Vitamins"),
    ("Vitamin D3 + K2", "count", [GH], "Vitamins"),
    ("Biotin", "count", [GH], "Vitamins"),
    ("Iron with Folic Acid", "count", [GH], "Minerals"),
    ("Zinc Citrate", "count", [GH], "Minerals"),
    ("Calcium Tablets", "count", [GH], "Minerals"),
    ("Magnesium Glycinate", "count", [GH], "Minerals"),
    ("Ashwagandha", "count", [GH], "Herbal Wellness"),
    ("Shilajit Tablets", "count", [GH], "Herbal Wellness"),
    ("Horny Goat Weed", "count", [GH], "Herbal Wellness"),

    # -- Overall Health & Support --
    ("Fish Oil & Omega", "count", [OH, HF], "Essential Fats"),
    ("Veg Omega 3-6-9", "count", [OH, HF], "Essential Fats"),
    ("CoQ10", "count", [OH], "Organ & Detox Support"),
    ("Glutathione", "count", [OH, BS], "Organ & Detox Support"),
    ("Milk Thistle", "count", [OH], "Organ & Detox Support"),
    ("Kidney Detox", "count", [OH], "Organ & Detox Support"),
    ("Liver Support", "count", [OH], "Organ & Detox Support"),
    ("Lung Detox (NAC)", "count", [OH], "Organ & Detox Support"),
    ("Probiotics", "count", [OH], "Digestive Support"),
    ("Psyllium Husk", "weight", [OH], "Digestive Support"),
    ("Bone Support", "count", [OH], "Structural Support"),

    # -- Beauty, Skin & Recovery --
    ("Beauty Collagen", "weight", [BS], "Beauty & Skin"),
    ("Glow Collagen", "weight", [BS], "Beauty & Skin"),
    ("Melatonin", "count", [BS], "Sleep & Recovery"),
]

# ---------------------------------------------------------------------------
# 4) Sample items: (product name, brand name, title, flavor, [(unit, value, price, mrp, stock), ...])
#    Placeholder prices in INR — replace with real MRP/Store 8 price/offer price/stock from the
#    admin app once you have the real list. Kept deliberately small so the site isn't empty while
#    you're setting things up, without pretending this is your real inventory.
# ---------------------------------------------------------------------------
# A handful of sample listings flagged for the homepage's "Featured products" strip — purely
# a demo default so the section isn't empty before real data is entered; freely re-toggle
# is_featured per item from the admin app once real inventory is in.
FEATURED_ITEMS = {
    ("Whey Protein", "Optimum Nutrition"),
    ("Mass Gainer", "MuscleBlaze"),
    ("Creatine", "MuscleBlaze"),
    ("Fat Burner", "Nutrex"),
    ("Multivitamins", "WellBeing"),
}

SAMPLE_ITEMS = [
    ("Whey Protein", "Optimum Nutrition", "Gold Standard 100% Whey", "Double Rich Chocolate",
     [("kg", 1, 3499, 3999, 20), ("kg", 2, 6499, 7499, 10)]),
    ("Whey Protein", "MuscleTech", "Nitro-Tech Whey Peptides", "Chocolate",
     [("kg", 1, 3299, 3799, 15), ("kg", 2.2, 6999, 7999, 8)]),
    ("Hydrolyzed Whey Protein", "Dymatize", "ISO100 Hydrolyzed", "Gourmet Chocolate",
     [("g", 900, 3199, 3599, 12)]),
    ("Mass Gainer", "MuscleBlaze", "Mass Gainer XXL", "Rich Chocolate",
     [("kg", 1, 999, 1199, 25), ("kg", 3, 2699, 2999, 15)]),
    ("Mass Gainer", "GNC", "Pro Performance Weight Gainer", "Chocolate",
     [("kg", 2, 1899, 2199, 10)]),
    ("Creatine", "MuscleBlaze", "Micronized Creatine Monohydrate", "Unflavoured",
     [("g", 100, 499, 599, 40), ("g", 250, 999, 1199, 20)]),
    ("Creatine", "Optimum Nutrition", "Micronized Creatine Powder", "Unflavoured",
     [("g", 250, 1299, 1499, 15)]),
    ("BCAA", "MuscleTech", "Amino Build BCAA", "Fruit Punch",
     [("g", 250, 1199, 1399, 18)]),
    ("BCAA", "GXN Nutrition", "BCAA 2:1:1", "Watermelon",
     [("g", 300, 999, 1199, 12)]),
    ("Fish Oil & Omega", "Doctor's Choice", "Omega-3 Fish Oil", "Unflavoured",
     [("capsules", 60, 599, 699, 30), ("capsules", 100, 899, 999, 20)]),
    ("Multivitamins", "WellBeing", "Daily Multivitamin", "Unflavoured",
     [("tablets", 60, 499, 599, 40)]),
    ("Fat Burner", "Nutrex", "Lipo-6 Black", "Unflavoured",
     [("capsules", 60, 1499, 1699, 15)]),
    ("Pre-Workout", "C4", "C4 Original", "Icy Blue Razz",
     [("g", 300, 2199, 2499, 10)]),
    ("Beauty Collagen", "WellBeing", "Beauty Collagen", "Berry",
     [("g", 200, 899, 999, 20)]),
]

CATALOG_COLLECTIONS = ("categories", "brands", "products", "items")


def clear_catalog(db):
    """Deletes every doc in categories/brands/products/items — never touches orders or admins.
    Used for --reset-catalog when the category names or product list have genuinely changed, so
    old renamed/removed entries don't linger alongside the new ones under different doc ids."""
    for col in CATALOG_COLLECTIONS:
        docs = list(db.collection(col).stream())
        for doc in docs:
            doc.reference.delete()
        print(f"  cleared {len(docs)} existing doc(s) from {col}")


def seed_categories(db):
    created = 0
    for i, cat in enumerate(CATEGORIES, start=1):
        doc_id = slugify(cat["name"])
        ref = db.collection("categories").document(doc_id)
        if ref.get().exists:
            continue
        ref.set(
            {
                "name": cat["name"],
                "tagline": cat["tagline"],
                "description": cat["tagline"],
                "icon": cat["icon"],
                "order": i,
                "is_active": True,
                "created_at": firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )
        created += 1
    print(f"categories: {created} created, {len(CATEGORIES) - created} already existed")


def seed_brands(db):
    created = 0
    for name in BRANDS:
        doc_id = slugify(name)
        ref = db.collection("brands").document(doc_id)
        if ref.get().exists:
            continue
        ref.set(
            {
                "name": name,
                "logo": "",
                "is_active": True,
                "created_at": firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )
        created += 1
    print(f"brands: {created} created, {len(BRANDS) - created} already existed")


def seed_products(db):
    created = 0
    for name, unit_kind, category_slugs, subcategory in PRODUCTS:
        doc_id = slugify(name)
        ref = db.collection("products").document(doc_id)
        if ref.get().exists:
            continue
        ref.set(
            {
                "name": name,
                "category_ids": category_slugs,
                "subcategory": subcategory,
                "description": "",
                "unit_kind": unit_kind,
                "is_active": True,
                "created_at": firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )
        created += 1
    print(f"products: {created} created, {len(PRODUCTS) - created} already existed")


def _variant_label(unit: str, value: float) -> str:
    labels = {"kg": "kg", "g": "g", "l": "L", "ml": "ml", "capsules": "capsules", "tablets": "tablets"}
    v = int(value) if float(value).is_integer() else value
    return f"{v} {labels.get(unit, unit)}"


# placehold.co needs no API key/signup and never rate-limits — good enough to make the sample
# catalog look like real cards (colored tile + product name) instead of a bare icon, until real
# product photos are uploaded per-item from the admin app (Item form -> Images -> upload).
def _placeholder_image(title: str) -> str:
    return f"https://placehold.co/600x600/e8f5e9/1b5e20.png?font=roboto&text={quote_plus(title)}"


def seed_items(db):
    created, skipped = 0, 0
    for product_name, brand_name, title, flavor, variants in SAMPLE_ITEMS:
        product_id = slugify(product_name)
        brand_id = slugify(brand_name)
        product_doc = db.collection("products").document(product_id).get()
        brand_doc = db.collection("brands").document(brand_id).get()
        if not product_doc.exists or not brand_doc.exists:
            print(f"  ! skipping item '{title}' — missing product/brand ({product_id}/{brand_id})")
            continue

        existing = (
            db.collection("items")
            .where(filter=firestore.FieldFilter("product_id", "==", product_id))
            .where(filter=firestore.FieldFilter("brand_id", "==", brand_id))
            .limit(1)
            .get()
        )
        if existing:
            skipped += 1
            continue

        product = product_doc.to_dict()
        brand = brand_doc.to_dict()
        variant_docs = [
            {
                "id": short_id(),
                "unit": unit,
                "value": value,
                "label": _variant_label(unit, value),
                "mrp": mrp,
                "price": price,
                "offer_price": None,
                "stock_qty": stock,
                "sku": f"{brand_id}-{product_id}-{unit}{value}".replace(".", ""),
                "is_active": True,
            }
            for unit, value, price, mrp, stock in variants
        ]
        db.collection("items").document().set(
            {
                "product_id": product_id,
                "brand_id": brand_id,
                "title": title,
                "flavor": flavor,
                "description": f"{title} by {brand_name}.",
                "ingredients": "",
                "benefits": "",
                "usage": "",
                "images": [_placeholder_image(title or f"{brand_name} {product_name}")],
                "variants": variant_docs,
                "is_active": True,
                "is_featured": (product_name, brand_name) in FEATURED_ITEMS,
                "product_name": product["name"],
                "brand_name": brand["name"],
                "unit_kind": product["unit_kind"],
                "created_at": firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )
        created += 1
    print(f"sample items: {created} created, {skipped} already existed")


def grant_admin(db, uid: str, email: str, name: str):
    db.collection("admins").document(uid).set(
        {
            "email": email,
            "name": name,
            "role": "owner",
            "is_active": True,
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    print(f"admins: granted admin access to {email} (uid={uid})")


def create_admin(db, email: str, password: str, name: str):
    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        print(
            f"'{email}' doesn't look like a real email address — Firebase Auth requires a "
            "proper email format (e.g. admin@yourdomain.com), not a bare username like 'admin'.",
            file=sys.stderr,
        )
        sys.exit(1)
    if len(password) < 6:
        print("Password must be at least 6 characters (Firebase Auth's minimum).", file=sys.stderr)
        sys.exit(1)

    try:
        user = auth.get_user_by_email(email)
        auth.update_user(user.uid, password=password, display_name=name)
        print(f"auth: user {email} already existed (uid={user.uid}) — password/name updated")
    except auth.UserNotFoundError:
        user = auth.create_user(email=email, password=password, display_name=name)
        print(f"auth: created new user {email} (uid={user.uid})")

    grant_admin(db, user.uid, email, name)
    print(f"\nYou can now log into the admin app with:\n  email:    {email}\n  password: {password}")


def main():
    parser = argparse.ArgumentParser(description="Seed / inspect Store 8 Firestore data")
    parser.add_argument("--catalog-only", action="store_true", help="Skip sample brand-items")
    parser.add_argument(
        "--reset-catalog", action="store_true",
        help="Delete all categories/brands/products/items first, then reseed fresh (never touches orders/admins)",
    )
    parser.add_argument("--admin", nargs=3, metavar=("UID", "EMAIL", "NAME"), help="Grant admin access to a Firebase Auth uid")
    parser.add_argument(
        "--create-admin",
        nargs="+",
        metavar=("EMAIL", "PASSWORD"),
        help="Create (or update) a Firebase Auth user with EMAIL/PASSWORD and grant it admin access. "
        "Optional third value is the display name (defaults to 'Admin').",
    )
    args = parser.parse_args()

    init_firebase()
    db = get_db()

    if args.admin:
        grant_admin(db, *args.admin)
        return

    if args.create_admin:
        if len(args.create_admin) not in (2, 3):
            parser.error("--create-admin takes EMAIL PASSWORD [NAME]")
        email, password = args.create_admin[0], args.create_admin[1]
        name = args.create_admin[2] if len(args.create_admin) == 3 else "Admin"
        create_admin(db, email, password, name)
        return

    if args.reset_catalog:
        print("Resetting catalog (categories/brands/products/items)...")
        clear_catalog(db)

    seed_categories(db)
    seed_brands(db)
    seed_products(db)
    if not args.catalog_only:
        seed_items(db)

    print("\nDone. Counts in Firestore now:")
    for col in ("categories", "brands", "products", "items"):
        count = len(list(db.collection(col).stream()))
        print(f"  {col}: {count}")


if __name__ == "__main__":
    try:
        main()
    except FileNotFoundError as e:
        print(f"\nCould not find your Firebase service account file: {e}", file=sys.stderr)
        print("Set FIREBASE_SERVICE_ACCOUNT_FILE in .env to the JSON key you downloaded from", file=sys.stderr)
        print("Firebase Console -> Project settings -> Service accounts -> Generate new private key.", file=sys.stderr)
        sys.exit(1)
