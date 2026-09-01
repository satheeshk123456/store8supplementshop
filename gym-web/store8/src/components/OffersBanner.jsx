import { useEffect, useState } from 'react'
import { getOffers } from '../api/offers'

// Strip of admin-posted offer banners at the very top of every page — see the admin app's
// "Offers" tab. Purely marketing copy (title/description/optional link), separate from the
// per-order special-offer system on individual orders. Renders nothing if there are no active
// offers, so it never leaves an empty gap on a normal day.
export default function OffersBanner() {
  const [offers, setOffers] = useState([])

  useEffect(() => {
    let cancelled = false
    getOffers()
      .then((data) => {
        if (!cancelled) setOffers(data || [])
      })
      .catch(() => {
        // Non-fatal — the site works fine with no banner if this fails.
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (offers.length === 0) return null

  return (
    <div className="offers-banner">
      {offers.map((o) => {
        const content = (
          <>
            <span className="offers-banner-title">🎁 {o.title}</span>
            {o.description && <span className="offers-banner-desc"> — {o.description}</span>}
          </>
        )
        return o.link ? (
          <a key={o.id} href={o.link} target="_blank" rel="noreferrer" className="offers-banner-item">
            {content}
          </a>
        ) : (
          <span key={o.id} className="offers-banner-item">
            {content}
          </span>
        )
      })}
    </div>
  )
}
