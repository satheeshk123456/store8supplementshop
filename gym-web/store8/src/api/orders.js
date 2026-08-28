import { api } from './client'

export const createOrder = (payload) => api.post('/orders', payload)

export const trackOrder = (orderNumber, phone) =>
  api.get(`/orders/track?order_number=${encodeURIComponent(orderNumber)}&phone=${encodeURIComponent(phone)}`)
