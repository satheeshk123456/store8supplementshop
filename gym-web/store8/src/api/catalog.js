import { api } from './client'

export const getCategories = () => api.get('/categories')
export const getCategory = (categoryId) => api.get(`/categories/${categoryId}`)
export const getProductsByCategory = (categoryId) => api.get(`/categories/${categoryId}/products`)
export const getProduct = (productId) => api.get(`/products/${productId}`)
export const getItemsForProduct = (productId) => api.get(`/products/${productId}/items`)
export const getItem = (itemId) => api.get(`/items/${itemId}`)
export const getBrands = () => api.get('/brands')
