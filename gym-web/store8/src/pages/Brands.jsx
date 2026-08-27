import { Link } from 'react-router-dom'
import { getBrands } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import BrandCard from '../components/BrandCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'

export default function Brands() {
  const { data: brands, loading, error, reload } = useApi(() => getBrands(), [])

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          Brands
        </div>
        <div className="section-title">
          <h2>Shop by brand</h2>
        </div>

        {loading && <Loading label="Loading brands…" />}
        {error && <ErrorState message={error.message} onRetry={reload} />}
        {!loading && !error && brands?.length === 0 && (
          <EmptyState message="No brands available yet — check back soon." />
        )}
        {!loading && !error && brands?.length > 0 && (
          <div className="grid">
            {brands.map((b) => (
              <BrandCard key={b.id} brand={b} />
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
