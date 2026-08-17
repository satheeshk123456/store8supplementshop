import { getCategories } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import CategoryCard from '../components/CategoryCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'
import logoMark from '../assets/brand/logo-mark.png'

export default function Home() {
  const { data: categories, loading, error, reload } = useApi(() => getCategories(), [])

  return (
    <>
      <section className="hero">
        <div className="container">
          <img src={logoMark} alt="Store 8" className="hero-logo" />
          <h1>Fuel Your Body. Build Strength. Live Healthy.</h1>
          <p>Shop genuine supplements picked for your goal — from weight gain to beauty &amp; sleep.</p>
          <span className="tagline">One Store · One Journey · Your Complete Health Hub</span>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <div className="section-title">
            <h2>Shop by goal</h2>
          </div>

          {loading && <Loading label="Loading categories…" />}
          {error && <ErrorState message={error.message} onRetry={reload} />}
          {!loading && !error && categories?.length === 0 && (
            <EmptyState message="No categories yet — check back soon." />
          )}
          {!loading && !error && categories?.length > 0 && (
            <div className="grid">
              {categories.map((c) => (
                <CategoryCard key={c.id} category={c} />
              ))}
            </div>
          )}
        </div>
      </section>
    </>
  )
}
