import { Link } from 'react-router-dom'
import { formatInr } from '../utils/format'

function effectivePrice(v) {
  return v.offer_price != null && v.offer_price < v.price ? v.offer_price : v.price
}

export default function ItemCard({ item }) {
  const activeVariants = item.variants.filter((v) => v.is_active)
  const cheapest = activeVariants.length
    ? activeVariants.reduce((a, b) => (effectivePrice(b) < effectivePrice(a) ? b : a))
    : null
  const inStock = activeVariants.some((v) => v.stock_qty > 0)
  const onOffer = cheapest ? effectivePrice(cheapest) < cheapest.price : false

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
              From {formatInr(effectivePrice(cheapest))}
              {onOffer && <span className="mrp">{formatInr(cheapest.price)}</span>}
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
