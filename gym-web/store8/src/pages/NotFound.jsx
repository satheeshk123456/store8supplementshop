import { Link } from 'react-router-dom'

export default function NotFound() {
  return (
    <section className="section">
      <div className="container center">
        <h2>Page not found</h2>
        <Link to="/" className="btn btn-gold">
          Back to home
        </Link>
      </div>
    </section>
  )
}
