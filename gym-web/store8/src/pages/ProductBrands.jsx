import { Link, useParams } from 'react-router-dom'
import { getItemsForProduct, getProduct } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import ItemCard from '../components/ItemCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'

export default function ProductBrands() {
  const { productId } = useParams()
  const { data: product } = useApi(() => getProduct(productId), [productId])
  const { data: items, loading, error, reload } = useApi(() => getItemsForProduct(productId), [productId])

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          {product?.category_ids?.[0] ? (
            <Link to={`/category/${product.category_ids[0]}`}>Back</Link>
          ) : (
            'Category'
          )}
          <span>/</span>
          {product?.name || 'Product'}
        </div>
        <div className="section-title">
          <h2>{product?.name || 'Choose a brand'}</h2>
        </div>

        {loading && <Loading label="Loading brands…" />}
        {error && <ErrorState message={error.message} onRetry={reload} />}
        {!loading && !error && items?.length === 0 && (
          <EmptyState message="No brands available for this product yet." />
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
