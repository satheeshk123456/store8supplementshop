import { Link, useParams } from 'react-router-dom'
import { getCategory, getProductsByCategory } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import ProductCard from '../components/ProductCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'

export default function CategoryProducts() {
  const { categoryId } = useParams()
  const { data: category } = useApi(() => getCategory(categoryId), [categoryId])
  const { data: products, loading, error, reload } = useApi(
    () => getProductsByCategory(categoryId),
    [categoryId],
  )

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          {category?.name || 'Category'}
        </div>
        <div className="section-title">
          <h2>{category?.name || 'Products'}</h2>
        </div>

        {loading && <Loading label="Loading products…" />}
        {error && <ErrorState message={error.message} onRetry={reload} />}
        {!loading && !error && products?.length === 0 && (
          <EmptyState message="No products in this category yet." />
        )}
        {!loading && !error && products?.length > 0 && (
          <div className="grid">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
