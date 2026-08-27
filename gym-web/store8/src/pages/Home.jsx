import { Link } from 'react-router-dom'
import { getBrands, getCategories, getFeaturedItems } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import CategoryCard from '../components/CategoryCard'
import BrandCard from '../components/BrandCard'
import ItemCard from '../components/ItemCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'
import logoMark from '../assets/brand/logo-mark.png'

const MAPS_URL =
  'https://www.google.com/maps/search/?api=1&query=' +
  encodeURIComponent(
    'Store 8 Supplement Shop, Door No: 1836, LPL Park Campus, Illayarasanendal Road, GVN College Post, Kovilpatti - 628502',
  )

export default function Home() {
  const { data: categories, loading, error, reload } = useApi(() => getCategories(), [])
  const { data: featured, loading: featuredLoading } = useApi(() => getFeaturedItems(), [])
  const { data: brands, loading: brandsLoading } = useApi(() => getBrands(), [])

  return (
    <>
      <section className="hero">
        <div className="container">
          <img src={logoMark} alt="Store 8" className="hero-logo" />
          <h1>Fuel Your Body. Build Strength. Live Healthy.</h1>
          <p>
            Store 8 Supplement Shop, Kovilpatti — the second branch of Team Beast Sports Nutrition Shop, Madurai.
            Genuine supplements picked for your goal, from weight gain to beauty &amp; recovery.
          </p>
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

      {!featuredLoading && featured?.length > 0 && (
        <section className="section">
          <div className="container">
            <div className="section-title">
              <h2>Featured products</h2>
            </div>
            <div className="grid">
              {featured.map((item) => (
                <ItemCard key={item.id} item={item} />
              ))}
            </div>
          </div>
        </section>
      )}

      {!brandsLoading && brands?.length > 0 && (
        <section className="section">
          <div className="container">
            <div className="section-title">
              <h2>Shop by brand</h2>
              <Link to="/brands" className="btn btn-outline btn-sm">
                View all brands
              </Link>
            </div>
            <div className="grid">
              {brands.slice(0, 8).map((b) => (
                <BrandCard key={b.id} brand={b} />
              ))}
            </div>
          </div>
        </section>
      )}

      <section className="section">
        <div className="container">
          <div className="section-title">
            <h2>Visit us</h2>
          </div>
          <div className="contact-card">
            <p>Door No: 1836, LPL Park Campus, Illayarasanendal Road, GVN College Post, Kovilpatti - 628502</p>
            <div className="contact-actions">
              <a href="tel:+916374358678" className="btn btn-gold btn-sm">
                Call us
              </a>
              <a
                href="https://wa.me/916374358678?text=Hi%20Store%208%2C%20I%27d%20like%20to%20ask%20about%20a%20product."
                target="_blank"
                rel="noreferrer"
                className="btn btn-outline btn-sm"
              >
                WhatsApp
              </a>
              <a href={MAPS_URL} target="_blank" rel="noreferrer" className="btn btn-outline btn-sm">
                Get directions
              </a>
            </div>
          </div>
        </div>
      </section>
    </>
  )
}
