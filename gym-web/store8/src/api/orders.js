import { api } from './client'

// Login is required to place an order (see gym-backend's create_order) — `token` is the
// caller's current Firebase ID token, always present since Checkout.jsx gates on being logged
// in before this is ever called.
export const createOrder = (payload, token) => api.post('/orders', payload, { token })

export const trackOrder = (orderNumber, phone) =>
  api.get(`/orders/track?order_number=${encodeURIComponent(orderNumber)}&phone=${encodeURIComponent(phone)}`)

// Customer's response ("notify_me" | "suggest_alternative") to a line the shop marked
// unavailable after checking physical stock. order_number + phone prove it's their order —
// same no-login pattern as trackOrder above.
export const submitLineChoice = (orderNumber, itemId, variantId, phone, choice) =>
  api.put(
    `/orders/${encodeURIComponent(orderNumber)}/lines/${encodeURIComponent(itemId)}/${encodeURIComponent(variantId)}/customer-choice`,
    { phone, choice },
  )

// Customer accepts/declines the alternative product the admin suggested for an unavailable
// line. Accepting swaps the line over to the alternative (at the admin's one-off price for
// this order) and lets the normal stock-check / payment-link flow continue.
export const respondToAlternative = (orderNumber, itemId, variantId, phone, accept) =>
  api.put(
    `/orders/${encodeURIComponent(orderNumber)}/lines/${encodeURIComponent(itemId)}/${encodeURIComponent(variantId)}/alternative-response`,
    { phone, accept },
  )
