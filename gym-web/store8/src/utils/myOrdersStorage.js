// Remembers which orders belong to this browser so "My Orders" can show them automatically,
// without needing customer accounts/login. Nothing sensitive is stored beyond what the customer
// already typed at checkout (order number + phone) — the backend still requires both together
// to actually fetch order details (see app/routers/orders.py's /orders/track).
const STORAGE_KEY = 'store8_my_orders'

export function rememberOrder(orderNumber, phone) {
  try {
    const existing = getRememberedOrders()
    const withoutDupe = existing.filter((o) => o.orderNumber !== orderNumber)
    const updated = [{ orderNumber, phone }, ...withoutDupe].slice(0, 25)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
  } catch {
    // localStorage can throw in private browsing / disabled-storage contexts — non-fatal,
    // the customer can still track the order manually by entering it on the My Orders page.
  }
}

export function getRememberedOrders() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    const parsed = raw ? JSON.parse(raw) : []
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

export function forgetOrder(orderNumber) {
  try {
    const updated = getRememberedOrders().filter((o) => o.orderNumber !== orderNumber)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
  } catch {
    // ignore
  }
}
