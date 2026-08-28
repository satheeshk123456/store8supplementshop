import { api } from './client'

// All three require a Firebase ID token (see context/AuthContext.jsx) — logged-out visitors
// never call these; guest checkout and guest order tracking don't touch this file at all.
export const getMyProfile = (token) => api.get('/customers/me', { token })

export const updateMyProfile = (token, { name, phone }) =>
  api.put('/customers/me', { name, phone }, { token })

export const getMyOrders = (token) => api.get('/customers/me/orders', { token })
