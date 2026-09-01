import { api } from './client'

// Public — active offer banners for the strip at the top of the storefront, posted by the
// admin (see gym-app/store8's Offers tab). Marketing copy only; never changes any product's
// MRP or Store 8 Customer Price.
export const getOffers = () => api.get('/offers')
