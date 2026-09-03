import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getMyOrders, getMyProfile, updateMyProfile } from '../api/customers'
import { formatInr } from '../utils/format'
import { StatusPill, UnavailableLineBanner } from './MyOrders'

function AccountOrderCard({ order, phone, onResolved }) {
  return (
    <div className="cart-summary" style={{ marginBottom: 16, textAlign: 'left' }}>
      <div className="summary-row" style={{ alignItems: 'center' }}>
        <span style={{ fontWeight: 700, color: 'var(--gold-light)' }}>{order.order_number}</span>
        <StatusPill status={order.status} paymentStatus={order.payment_status} />
      </div>
      {order.created_at && (
        <p style={{ color: 'var(--text-muted)', fontSize: '0.8rem', margin: '4px 0 12px' }}>
          Placed {new Date(order.created_at).toLocaleString()}
        </p>
      )}
      {order.items.map((l) => (
        <div key={`${l.item_id}-${l.variant_id}`} style={{ marginBottom: 6 }}>
          <div className="summary-row">
            <span>
              {l.brand_name} {l.product_name} ({l.variant_label}) × {l.qty}
            </span>
            <span>{formatInr(l.subtotal)}</span>
          </div>
          {l.availability === 'unavailable' && (
            <UnavailableLineBanner orderNumber={order.order_number} phone={phone} line={l} onResolved={onResolved} />
          )}
        </div>
      ))}
      <div className="summary-row total">
        <span>Total</span>
        <span>{formatInr(order.total_amount)}</span>
      </div>
      {order.payment_status === 'link_shared' && order.payment_link && (
        <div style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid rgba(212, 175, 55, 0.2)' }}>
          <p style={{ margin: '0 0 8px', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
            Your order is confirmed — pay using the link below.
          </p>
          <a href={order.payment_link} target="_blank" rel="noreferrer" className="btn btn-gold btn-sm">
            Pay now
          </a>
        </div>
      )}
    </div>
  )
}

export default function Account() {
  const { user, loading, logout, getToken } = useAuth()
  const navigate = useNavigate()

  const [profile, setProfile] = useState(null)
  const [orders, setOrders] = useState([])
  const [ordersLoading, setOrdersLoading] = useState(true)
  const [error, setError] = useState('')

  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState({ name: '', phone: '' })
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')

  useEffect(() => {
    if (!loading && !user) navigate('/login', { replace: true })
  }, [loading, user, navigate])

  useEffect(() => {
    if (!user) return
    let cancelled = false
    async function load() {
      setOrdersLoading(true)
      setError('')
      try {
        const token = await getToken()
        const [p, o] = await Promise.all([getMyProfile(token), getMyOrders(token)])
        if (cancelled) return
        setProfile(p)
        setForm({ name: p.name || '', phone: p.phone || '' })
        setOrders(o)
      } catch (err) {
        if (!cancelled) setError(err.message || 'Could not load your account.')
      } finally {
        if (!cancelled) setOrdersLoading(false)
      }
    }
    load()
    return () => {
      cancelled = true
    }
  }, [user]) // eslint-disable-line react-hooks/exhaustive-deps

  function updateOrderInList(updated) {
    setOrders((prev) => prev.map((o) => (o.order_number === updated.order_number ? updated : o)))
  }

  async function handleSaveProfile(ev) {
    ev.preventDefault()
    setSaveError('')
    setSaving(true)
    try {
      const token = await getToken()
      const updated = await updateMyProfile(token, form)
      setProfile(updated)
      setEditing(false)
    } catch (err) {
      setSaveError(err.message || 'Could not save your details.')
    } finally {
      setSaving(false)
    }
  }

  async function handleLogout() {
    await logout()
    navigate('/')
  }

  if (loading || !user) return null

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>My Account</h2>
        </div>

        <div className="cart-summary" style={{ maxWidth: 420, margin: '0 auto 24px', textAlign: 'left' }}>
          {editing ? (
            <form className="form-grid" onSubmit={handleSaveProfile} noValidate>
              <div className="field">
                <label htmlFor="accName">Full name</label>
                <input id="accName" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
              </div>
              <div className="field">
                <label htmlFor="accPhone">Phone number</label>
                <input
                  id="accPhone"
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  inputMode="tel"
                />
              </div>
              {saveError && <div className="field-error">{saveError}</div>}
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-gold" type="submit" disabled={saving}>
                  {saving ? 'Saving…' : 'Save'}
                </button>
                <button className="btn btn-outline" type="button" onClick={() => setEditing(false)}>
                  Cancel
                </button>
              </div>
            </form>
          ) : (
            <>
              <p style={{ margin: 0, fontWeight: 700, color: 'var(--text)' }}>{profile?.name || user.displayName || 'Your account'}</p>
              <p style={{ margin: '4px 0 0', color: 'var(--text-muted)', fontSize: '0.85rem' }}>{profile?.email || user.email}</p>
              {profile?.phone && (
                <p style={{ margin: '2px 0 0', color: 'var(--text-muted)', fontSize: '0.85rem' }}>{profile.phone}</p>
              )}
              <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                <button className="btn btn-outline btn-sm" type="button" onClick={() => setEditing(true)}>
                  Edit details
                </button>
                <button className="btn btn-outline btn-sm" type="button" onClick={handleLogout}>
                  Log out
                </button>
              </div>
            </>
          )}
        </div>

        <h3 style={{ textAlign: 'center', color: 'var(--gold-light)', marginBottom: 16 }}>Order history</h3>

        {ordersLoading ? (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center' }}>Loading your orders…</p>
        ) : error ? (
          <p className="field-error" style={{ textAlign: 'center' }}>{error}</p>
        ) : orders.length === 0 ? (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center' }}>
            No orders placed while logged in yet. Orders you placed as a guest before logging in
            won't appear here — track those from{' '}
            <a href="/my-orders" style={{ color: 'var(--gold-light)' }}>My Orders</a> with your
            order number and phone instead.
          </p>
        ) : (
          <div style={{ maxWidth: 520, margin: '0 auto' }}>
            {orders.map((o) => (
              <AccountOrderCard key={o.order_number} order={o} phone={o.customer?.phone} onResolved={updateOrderInList} />
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
