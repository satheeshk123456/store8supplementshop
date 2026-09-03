import { Link } from 'react-router-dom'

// A common way someone lands here: they copied an order reference or a link from somewhere
// (WhatsApp, a screenshot) that isn't a real page on its own — so besides "back to home", give
// them a direct path to where an order actually lives instead of a dead end.
export default function NotFound() {
  return (
    <section className="section">
      <div className="container center">
        <h2>Page not found</h2>
        <p style={{ color: 'var(--text-muted)', maxWidth: 440, margin: '8px auto 24px' }}>
          This page doesn't exist. Looking for an order? Track it from My Orders, or check My
          Account if you're logged in.
        </p>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
          <Link to="/" className="btn btn-gold">
            Back to home
          </Link>
          <Link to="/my-orders" className="btn btn-outline">
            Track an order
          </Link>
          <Link to="/account" className="btn btn-outline">
            My Account
          </Link>
        </div>
      </div>
    </section>
  )
}
