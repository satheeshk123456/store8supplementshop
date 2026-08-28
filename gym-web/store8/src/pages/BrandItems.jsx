import { Link, useParams } from 'react-router-dom'
import { getBrands, getItemsByBrand } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import ItemCard from '../components/ItemCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'

export default function BrandItems() {
  const { brandId } = useParams()
  // No single-brand fetch endpoint exists (only the full list) — the list is short, so we
  // just fetch it and look up the one we need; falls back to the denormalized brand_name on
  // an item if the brand list hasn't loaded yet.
  const { data: brands } = useApi(() => getBrands(), [])
  const brand = brands?.find((b) => b.id === brandId)
  const { data: items, loading, error, reload } = useApi(() => getItemsByBrand(brandId), [brandId])
  const heading = brand?.name || items?.[0]?.brand_name || 'Brand'

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          <Link to="/brands">Brands</Link>
          <span>/</span>
          {heading}
        </div>
        <div className="section-title">
          <h2>{heading}</h2>
        </div>

        {loading && <Loading label="Loading products…" />}
        {error && <ErrorState message={error.message} onRetry={reload} />}
        {!loading && !error && items?.length === 0 && (
          <EmptyState message="No products listed for this brand yet." />
        )}
        {!loading && !error && items?.length > 0 && (
          <div className="grid">
            {items.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
