# Store 8 — Storefront (React + Vite)

Customer-facing site: Category → Product → Brand → Size, cart, guest checkout (no payment yet).

## Run locally

```bash
npm install
npm run dev          # http://localhost:5173, talks to the backend at VITE_API_BASE_URL (.env)
```

Make sure `gym-backend` is running first (see `../../gym-backend/README.md`) and has been seeded
(`python seed.py`) so there's something to browse.

## Build for production

```bash
npm run build         # outputs to dist/
```

Deploy `dist/` to any static host once you have a domain, and update `.env.production` /
`VITE_API_BASE_URL` to point at your deployed backend, and add that domain to the backend's
`CORS_ORIGINS`.

## Structure
```
src/
  api/            fetch wrapper + one file per resource (catalog, orders)
  context/        CartContext — cart lives in localStorage, no customer login needed
  hooks/useApi.js  small data-fetching hook (loading/error/reload)
  components/     Header, Footer, cards, state views
  pages/          Home -> CategoryProducts -> ProductBrands -> ItemDetail -> Cart -> Checkout -> OrderConfirmation
  assets/brand/   logo extracted from the client's catalogue artwork
```

Cart prices/stock are never trusted client-side — checkout only sends `{item_id, variant_id, qty}`
and the backend looks up the real price and checks stock before creating the order.
