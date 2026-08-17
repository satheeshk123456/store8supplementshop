import { Link } from 'react-router-dom'
import { formatInr } from '../utils/format'

export default function ItemCard({ item }) {
  const activeVariants = item.variants.filter((v) => v.is_active)
  const prices = activeVariants.map((v) => v.price)
  const minPrice = prices.length ? Math.min(...prices) : null
  const inStock = activeVariants.some((v) => v.stock_qty > 0)

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
          {minPrice !== null ? <>From {formatInr(minPrice)}</> : 'Price unavailable'}
        </div>
        {!inStock && <span className="badge-danger">Out of stock</span>}
      </div>
    </Link>
  )
}
