import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { searchItems } from '../api/catalog'
import { useApi } from '../hooks/useApi'
import ItemCard from '../components/ItemCard'
import { Loading, ErrorState, EmptyState } from '../components/StateViews'

export default function Search() {
  const [params, setParams] = useSearchParams()
  const [q, setQ] = useState(params.get('q') || '')
  const trimmed = q.trim()

  // Mirror the query into the URL (debounced) so results are shareable/bookmarkable and
  // back/forward navigation works, without firing a search request on every keystroke.
  useEffect(() => {
    const t = setTimeout(() => {
      setParams(trimmed ? { q: trimmed } : {}, { replace: true })
    }, 300)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [trimmed])

  const { data: items, loading, error, reload } = useApi(
    () => (trimmed.length >= 2 ? searchItems(trimmed) : Promise.resolve([])),
    [trimmed],
  )

  return (
    <section className="section">
      <div className="container">
        <div className="breadcrumb">
          <Link to="/">Home</Link>
          <span>/</span>
          Search
        </div>
        <div className="section-title">
          <h2>Search products</h2>
        </div>

        <input
          type="search"
          className="search-input"
          placeholder="Search by product, brand or goal…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          autoFocus
        />

        {trimmed.length > 0 && trimmed.length < 2 && (
          <EmptyState message="Type at least 2 characters to search." />
        )}
        {loading && trimmed.length >= 2 && <Loading label="Searching…" />}
        {error && <ErrorState message={error.message} onRetry={reload} />}
        {!loading && !error && trimmed.length >= 2 && items?.length === 0 && (
          <EmptyState message={`No products found for "${trimmed}".`} />
        )}
        {!loading && !error && trimmed.length >= 2 && items?.length > 0 && (
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
