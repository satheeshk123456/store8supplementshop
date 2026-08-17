import { Link } from 'react-router-dom'
import { UNIT_KIND_ICON } from '../utils/units'

export default function ProductCard({ product }) {
  return (
    <Link to={`/product/${product.id}`} className="card">
      <div className="card-media">
        <span className="icon-fallback">{UNIT_KIND_ICON[product.unit_kind] || '🧪'}</span>
      </div>
      <div className="card-body">
        <span className="card-title">{product.name}</span>
        <span className="card-sub">Choose your brand →</span>
      </div>
    </Link>
  )
}
