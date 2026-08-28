import { Link } from 'react-router-dom'
import { formatInr } from '../utils/format'

// Store 8 Customer Price: the one common selling price shown to every visitor, logged in
// or not — there is no member/login-based pricing anywhere in this store.
function effectivePrice(v) {
  return v.offer_price != null && v.offer_price < v.price ? v.offer_price : v.price
}

export default function ItemCard({ item }) {
  const activeVariants = item.variants.filter((v) => v.is_active)
  const cheapest = activeVariants.length
    ? activeVariants.reduce((a, b) => (effectivePrice(b) < effectivePrice(a) ? b : a))
    : null
  const inStock = activeVariants.some((v) => v.stock_qty > 0)
  const customerPrice = cheapest ? effectivePrice(cheapest) : null
  // MRP is only shown when it's actually set and higher than the selling price — otherwise
  // there's nothing meaningful to strike through.
  const mrp = cheapest?.mrp != null && cheapest.mrp > customerPrice ? cheapest.mrp : null

  return (
    <Link to={`/item/${item.id}`} className="card">
      <div className="card-media">
        {item.images?.[0] ? (
          <img src={item.images[0]} alt={item.title || item.product_name} loading="lazy" />
        ) : (
          <span className="icon-fallback">🧴</span>
        )}
      </div>
      <div className="card-body">
        <span className="card-tag">{item.brand_name}</span>
        <span className="card-title">{item.title || item.product_name}</span>
        {item.flavor && <span className="card-sub">{item.flavor}</span>}
        <div className="card-price">
          {cheapest ? (
            <>
              {mrp && (
                <span className="mrp-wrap">
                  MRP <span className="mrp">{formatInr(mrp)}</span>
                </span>
              )}
              <span className="price-now">From {formatInr(customerPrice)}</span>
            </>
          ) : (
            'Price unavailable'
          )}
        </div>
        {!inStock && <span className="badge-danger">Out of stock</span>}
      </div>
    </Link>
  )
}
