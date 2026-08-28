import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const FRIENDLY_ERROR = {
  'auth/invalid-credential': 'Incorrect email or password.',
  'auth/invalid-email': 'Enter a valid email address.',
  'auth/user-not-found': 'No account found with that email.',
  'auth/wrong-password': 'Incorrect email or password.',
  'auth/too-many-requests': 'Too many attempts. Please wait a moment and try again.',
}

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(ev) {
    ev.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await login(form)
      navigate(location.state?.from || '/account', { replace: true })
    } catch (err) {
      setError(FRIENDLY_ERROR[err.code] || 'Could not log in. Please check your details and try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>Log in</h2>
        </div>
        <div className="item-detail" style={{ maxWidth: 420, margin: '0 auto' }}>
          <form className="form-grid" onSubmit={handleSubmit} noValidate>
            <div className="field">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="you@example.com"
                autoComplete="email"
              />
            </div>
            <div className="field">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="Your password"
                autoComplete="current-password"
              />
            </div>
            {error && <div className="field-error">{error}</div>}
            <button className="btn btn-gold btn-block" type="submit" disabled={submitting}>
              {submitting ? 'Logging in…' : 'Log in'}
            </button>
            <p style={{ textAlign: 'center', fontSize: '0.85rem', color: 'var(--text-muted)', margin: 0 }}>
              New here? <Link to="/register">Create an account</Link>
            </p>
            <p style={{ textAlign: 'center', fontSize: '0.78rem', color: 'var(--text-muted)', margin: 0 }}>
              Don't want to log in? You can still{' '}
              <Link to="/checkout">checkout as a guest</Link>.
            </p>
          </form>
        </div>
      </div>
    </section>
  )
}
