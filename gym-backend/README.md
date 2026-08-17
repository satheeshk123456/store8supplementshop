# Store 8 — Backend API

FastAPI + Firestore + Firebase Storage + FCM. Firestore/Auth/FCM need no credit card; Firebase
Storage requires the Blaze (pay-as-you-go) plan to even be turned on — see `../SETUP.md` in the
repo root for exactly which Firebase values you need to get and paste into `.env`.

## Local setup

```bash
cd gym-backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# edit .env: point FIREBASE_SERVICE_ACCOUNT_FILE at the service-account JSON you downloaded
# from the Firebase console, and set FIREBASE_STORAGE_BUCKET (see ../SETUP.md)
mkdir -p secrets
# put the downloaded JSON at secrets/firebase-service-account.json (this folder is gitignored)

python seed.py                   # loads categories/brands/products + sample items
python -m uvicorn app.main:app --reload --port 8000
```

Open http://localhost:8000/docs for interactive API docs (only available when `ENV=development`).

## Creating your first admin login
1. Firebase Console → Authentication → Add user → create an email/password login for yourself.
2. Copy that user's UID from the Authentication table.
3. `python seed.py --admin <uid> <your-email> "Your Name"` — this is what actually grants admin
   access; just having a Firebase Auth account is not enough on its own (see `DATA_MODEL.md`).
4. Log into the Flutter admin app with that email/password.

## Deploying to Vercel

Vercel auto-detects the FastAPI `app` instance in `app/main.py` — no extra restructuring needed
(that's a supported entrypoint name straight out of the box), `vercel.json` just sets the max
request duration.

```bash
npm i -g vercel     # Vercel CLI (Node — this is separate from the Python app itself)
cd gym-backend
vercel login
vercel               # first deploy: link/create the project, deploys a preview
vercel --prod        # promote to your production URL
```
Or connect the `gym-s-8` GitHub repo in the Vercel dashboard and set **Root Directory** to
`gym-backend` (this is a monorepo — Vercel needs to know which subfolder to build).

Environment variables (Vercel dashboard → Project → Settings → Environment Variables — same
names as `.env`):
- `ENV=production`
- `CORS_ORIGINS` → your storefront's real domain once you have one (comma-separated if more than one)
- `FIREBASE_STORAGE_BUCKET` → exact bucket name from Firebase Console → Storage → Files
- `SECRET_KEY` → a fresh random value, not the one from local dev
- `FIREBASE_SERVICE_ACCOUNT_B64` — Vercel Functions have no persistent disk, so the JSON file
  approach doesn't work here. Instead: `base64 -w0 secrets/firebase-service-account.json` and
  paste the output as this variable's value. (`FIREBASE_SERVICE_ACCOUNT_FILE` is ignored once
  this is set — see `app/firebase.py`.)

Then deploy the Firestore + Storage rules/indexes once, from this folder, with the Firebase CLI:
`firebase deploy --only firestore:rules,firestore:indexes,storage`

**Two things worth knowing before you rely on this in production:**
- Vercel's free **Hobby** plan is genuinely free with no card — but its terms of service
  reserve it for personal/non-commercial projects; a live store taking real customer orders
  technically falls under their **Pro** plan ($20/mo). Fine to build and test on Hobby now;
  worth switching before this goes live for real customers.
- The spam-protection rate limit on `POST /orders` (`slowapi`) counts requests in memory per
  running instance. On a normal server that's one shared counter; on serverless it can reset
  across cold starts / be split across parallel instances, so it's a softer guarantee here than
  on a traditional host. Not a security hole (Firestore transactions still prevent overselling
  regardless), just weaker abuse-throttling — fine at small scale, worth revisiting if the site
  gets popular.

## Project layout
```
app/
  main.py          FastAPI app, middleware, router wiring
  config.py        .env settings
  firebase.py      Firebase Admin SDK init (Firestore + Auth + FCM + Storage)
  storage_client.py  product image resize (Pillow) + upload to Firebase Storage
  cloudinary_client.py  deprecated, unused — safe to delete (see file header)
  security.py      Firebase ID token verification + admin allow-list check
  notifications.py FCM push to admin devices on new order
  rate_limit.py     slowapi limiter (protects POST /orders from spam)
  schemas.py        all request/response models
  utils.py          slugify, order numbers, Firestore doc helpers
  routers/          one file per resource (categories, brands, products, items, orders, ...)
seed.py             sample data loader (see DATA_MODEL.md for the schema it writes)
firestore.rules     denies ALL direct client access — API is the only way in
storage.rules       same, for product image files
```

See `DATA_MODEL.md` for the full Firestore schema and the reasoning behind it.
