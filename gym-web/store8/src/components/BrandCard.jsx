import { Link } from 'react-router-dom'

export default function BrandCard({ brand }) {
  return (
    <Link to={`/brand/${brand.id}`} className="card">
      <div className="card-media">
        {brand.logo ? (
          <img src={brand.logo} alt={brand.name} loading="lazy" />
        ) : (
          <span className="icon-fallback">🏷️</span>
        )}
      </div>
      <div className="card-body">
        <span className="card-title">{brand.name}</span>
        <span className="card-sub">Shop this brand →</span>
      </div>
    </Link>
  )
}
