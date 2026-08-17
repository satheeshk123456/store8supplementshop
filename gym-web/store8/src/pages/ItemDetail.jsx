import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { getItem } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import { Loading, ErrorState } from '../components/StateViews'
import { formatInr } from '../utils/format'
import { useCart } from '../context/CartContext'

export default function ItemDetail() {
  const { itemId } = useParams()
  const navigate = useNavigate()
  const { addLine } = useCart()
  const { data: item, loading, error, reload } = useApi(() => getItem(itemId), [itemId])

  const [selectedVariantId, setSelectedVariantId] = useState(null)
  const [qty, setQty] = useState(1)
  const [toast, setToast] = useState('')

  useEffect(() => {
    if (item && !selectedVariantId) {
      const firstAvailable = item.variants.find((v) => v.is_active && v.stock_qty > 0) || item.variants[0]
      setSelectedVariantId(firstAvailable?.id ?? null)
    }
  }, [item, selectedVariantId])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(''), 2200)
    return () => clearTimeout(t)
  }, [toast])

  if (loading) return <Loading label="Loading product…" />
  if (error) return <ErrorState message={error.message} onRetry={reload} />
  if (!item) return null

  const variant = item.variants.find((v) => v.id === selectedVariantId)
  const maxQty = variant ? Math.min(variant.stock_qty, 20) : 0

  function handleAddToCart() {
    if (!variant || variant.stock_qty <= 0) return
    addLine({
      itemId: item.id,
      variantId: variant.id,
      productName: item.product_name,
      brandName: item.brand_name,
      variantLabel: variant.label,
      unit: variant.unit,
      price: variant.price,
      image: item.images?.[0] || '',
      qty,
    })
    setToast('Added to cart')
  }

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          <Link to={`/product/${item.product_id}`}>{item.product_name}</Link>
          <span>/</span>
          {item.brand_name}
        </div>

        <div className="item-detail">
          <div className="item-media">
            {item.images?.[0] ? (
              <img src={item.images[0]} alt={item.title || item.product_name} />
            ) : (
              <span className="icon-fallback" style={{ fontSize: '4rem' }}>
                🧴
              </span>
            )}
          </div>

          <div className="item-info">
            <div className="brand-name">{item.brand_name}</div>
            <h1>{item.title || item.product_name}</h1>
            {item.flavor && <p className="desc">Flavor: {item.flavor}</p>}
            {item.description && <p className="desc">{item.description}</p>}

            <h3 style={{ marginTop: 20, fontSize: '0.95rem' }}>Choose size</h3>
            <div className="variant-grid">
              {item.variants
                .filter((v) => v.is_active)
                .map((v) => (
                  <button
                    key={v.id}
                    type="button"
                    className={`variant-pill ${v.id === selectedVariantId ? 'selected' : ''}`}
                    disabled={v.stock_qty <= 0}
                    onClick={() => {
                      setSelectedVariantId(v.id)
                      setQty(1)
                    }}
                  >
                    {v.label}
                    <span className="v-price">{formatInr(v.price)}</span>
                    <span className="v-stock">{v.stock_qty > 0 ? `${v.stock_qty} in stock` : 'Out of stock'}</span>
                  </button>
                ))}
            </div>

            {variant && (
              <>
                <div className="qty-row">
                  <div className="qty-stepper">
                    <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))}>
                      −
                    </button>
                    <span>{qty}</span>
                    <button type="button" onClick={() => setQty((q) => Math.min(maxQty, q + 1))} disabled={qty >= maxQty}>
                      +
                    </button>
                  </div>
                  <strong>{formatInr(variant.price * qty)}</strong>
                </div>

                <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                  <button
                    className="btn btn-gold"
                    disabled={variant.stock_qty <= 0}
                    onClick={handleAddToCart}
                  >
                    {variant.stock_qty > 0 ? 'Add to cart' : 'Out of stock'}
                  </button>
                  <button
                    className="btn btn-outline"
                    disabled={variant.stock_qty <= 0}
                    onClick={() => {
                      handleAddToCart()
                      navigate('/cart')
                    }}
                  >
                    Buy now
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {toast && <div className="toast">{toast}</div>}
    </section>
  )
}
