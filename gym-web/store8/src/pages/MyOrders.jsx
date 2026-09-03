import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { respondToAlternative, submitLineChoice, trackOrder } from '../api/orders'
import { formatInr } from '../utils/format'
import { forgetOrder, getRememberedOrders, rememberOrder } from '../utils/myOrdersStorage'
import { useAuth } from '../context/AuthContext'

// The client asked for a more descriptive status list (Order Received → Stock Checking →
// Admin Confirmation Pending → Confirmed → Payment Pending → Payment Received → Processing →
// Shipped → Delivered) than the backend actually tracks as distinct statuses. Rather than
// adding real new order-status values (a bigger, riskier change touching the backend, both
// apps, and every status-driven code path), this only relabels what's already tracked — the
// existing `status` value plus the existing `payment_status` field — to read the way the
// client asked for. No new state is introduced; see the Flutter app's status_badge.dart for
// the same relabeling on the admin side.
export function statusLabel(status, paymentStatus) {
  switch (status) {
    case 'pending':
      return 'Order Received'
    case 'confirmed':
      return paymentStatus === 'link_shared' ? 'Confirmed — Payment Pending' : 'Confirmed'
    case 'packed':
      return 'Processing'
    case 'shipped':
      return 'Shipped / Ready for Delivery'
    case 'delivered':
      return 'Delivered'
    case 'cancelled':
      return 'Cancelled'
    case 'stock_issue':
      return 'Out of Stock — Action Needed'
    default:
      return status
  }
}

export const STATUS_COLOR = {
  pending: 'var(--text-muted)',
  confirmed: 'var(--gold-light)',
  packed: 'var(--gold-light)',
  shipped: 'var(--gold-light)',
  delivered: 'var(--success)',
  cancelled: 'var(--danger)',
  stock_issue: 'var(--danger)',
}

const CHOICE_CONFIRMATION = {
  notify_me: "Got it — we'll message you on WhatsApp as soon as it's back in stock.",
  suggest_alternative: "Got it — our team will suggest an alternative on WhatsApp shortly.",
}

export function AlternativeSuggestionCard({ orderNumber, phone, line, onResolved }) {
  const [submitting, setSubmitting] = useState(false)
  const [localError, setLocalError] = useState('')
  const alt = line.alternative

  if (alt.status === 'customer_declined') {
    return (
      <p style={{ color: 'var(--text-muted)', fontSize: '0.82rem', margin: '4px 0 0' }}>
        You declined this alternative — our team will follow up with you on WhatsApp.
      </p>
    )
  }

  async function respond(accept) {
    setSubmitting(true)
    setLocalError('')
    try {
      const updated = await respondToAlternative(orderNumber, line.item_id, line.variant_id, phone, accept)
      onResolved(updated)
    } catch (err) {
      setLocalError(err.message || 'Could not save your response. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div
      style={{
        background: 'rgba(212, 175, 55, 0.1)',
        border: '1px solid rgba(212, 175, 55, 0.35)',
        borderRadius: 10,
        padding: '10px 12px',
        marginTop: 6,
      }}
    >
      <p style={{ margin: 0, fontSize: '0.78rem', color: 'var(--text-muted)' }}>Suggested alternative</p>
      <p style={{ margin: '2px 0 0', fontSize: '0.9rem', fontWeight: 700, color: 'var(--text)' }}>
        {alt.brand_name} {alt.product_name} ({alt.variant_label})
      </p>
      {alt.special_offer && (
        <p style={{ margin: '4px 0 0', fontSize: '0.82rem', color: 'var(--gold-light)' }}>🎁 {alt.special_offer}</p>
      )}
      <p style={{ margin: '4px 0 0', fontSize: '0.95rem', fontWeight: 700 }}>
        {formatInr(alt.final_price)}
        {alt.final_price < alt.price && (
          <span className="mrp" style={{ marginLeft: 6 }}>
            {formatInr(alt.price)}
          </span>
        )}
      </p>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 8 }}>
        <button type="button" className="btn btn-sm btn-gold" disabled={submitting} onClick={() => respond(true)}>
          Confirm this alternative
        </button>
        <button type="button" className="btn btn-sm btn-outline" disabled={submitting} onClick={() => respond(false)}>
          No, thanks
        </button>
      </div>
      {localError && <p className="field-error" style={{ marginTop: 6 }}>{localError}</p>}
    </div>
  )
}

export function UnavailableLineBanner({ orderNumber, phone, line, onResolved }) {
  const [submitting, setSubmitting] = useState(false)
  const [localError, setLocalError] = useState('')

  if (line.customer_choice === 'suggest_alternative' && line.alternative) {
    return <AlternativeSuggestionCard orderNumber={orderNumber} phone={phone} line={line} onResolved={onResolved} />
  }

  if (line.customer_choice) {
    return (
      <p style={{ color: 'var(--gold-light)', fontSize: '0.82rem', margin: '4px 0 0' }}>
        {CHOICE_CONFIRMATION[line.customer_choice] || 'Thanks — we have your response.'}
      </p>
    )
  }

  async function choose(choice) {
    setSubmitting(true)
    setLocalError('')
    try {
      const updated = await submitLineChoice(orderNumber, line.item_id, line.variant_id, phone, choice)
      onResolved(updated)
    } catch (err) {
      setLocalError(err.message || 'Could not save your response. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div
      style={{
        background: 'rgba(224, 82, 82, 0.1)',
        border: '1px solid rgba(224, 82, 82, 0.35)',
        borderRadius: 10,
        padding: '10px 12px',
        marginTop: 6,
      }}
    >
      <p style={{ margin: 0, fontSize: '0.82rem', color: 'var(--text)' }}>
        This product is currently unavailable / in transit. It is expected to be available in
        approximately one week. Would you like us to notify you on WhatsApp when it becomes
        available?
      </p>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 8 }}>
        <button
          type="button"
          className="btn btn-sm btn-gold"
          disabled={submitting}
          onClick={() => choose('notify_me')}
        >
          Notify me
        </button>
        <button
          type="button"
          className="btn btn-sm btn-outline"
          disabled={submitting}
          onClick={() => choose('suggest_alternative')}
        >
          Suggest an alternative
        </button>
      </div>
      {localError && <p className="field-error" style={{ marginTop: 6 }}>{localError}</p>}
    </div>
  )
}

export function StatusPill({ status, paymentStatus }) {
  return (
    <span
      style={{
        color: STATUS_COLOR[status] || 'var(--text-muted)',
        border: `1px solid ${STATUS_COLOR[status] || 'var(--text-muted)'}`,
        borderRadius: 999,
        padding: '2px 12px',
        fontSize: '0.78rem',
        fontWeight: 600,
        whiteSpace: 'nowrap',
      }}
    >
      {statusLabel(status, paymentStatus)}
    </span>
  )
}

function OrderRow({ orderNumber, phone, onGone }) {
  const [order, setOrder] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    trackOrder(orderNumber, phone)
      .then((data) => {
        if (!cancelled) setOrder(data)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || 'Could not load this order.')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [orderNumber, phone])

  if (loading) {
    return (
      <div className="cart-summary" style={{ marginBottom: 16 }}>
        <p style={{ color: 'var(--text-muted)', margin: 0 }}>Loading {orderNumber}…</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="cart-summary" style={{ marginBottom: 16 }}>
        <div className="summary-row">
          <span>{orderNumber}</span>
          <span className="field-error">{error}</span>
        </div>
        <button
          className="btn btn-outline btn-sm"
          style={{ marginTop: 8 }}
          onClick={() => {
            forgetOrder(orderNumber)
            onGone(orderNumber)
          }}
        >
          Remove from this list
        </button>
      </div>
    )
  }

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
            <UnavailableLineBanner
              orderNumber={order.order_number}
              phone={phone}
              line={l}
              onResolved={setOrder}
            />
          )}
        </div>
      ))}
      <div className="summary-row total">
        <span>Total</span>
        <span>{formatInr(order.total_amount)}</span>
      </div>

      {order.payment_status === 'link_shared' && order.payment_link && (
        <div
          style={{
            marginTop: 12,
            paddingTop: 12,
            borderTop: '1px solid rgba(212, 175, 55, 0.2)',
          }}
        >
          <p style={{ margin: '0 0 8px', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
            Your order is confirmed — pay using the link below.
          </p>
          <a
            href={order.payment_link}
            target="_blank"
            rel="noreferrer"
            className="btn btn-gold btn-sm"
          >
            Pay now
          </a>
        </div>
      )}
    </div>
  )
}

export default function MyOrders() {
  const { user, loading: authLoading } = useAuth()
  const navigate = useNavigate()
  const [remembered, setRemembered] = useState([])
  const [form, setForm] = useState({ orderNumber: '', phone: '' })
  const [lookupError, setLookupError] = useState('')
  const [lookingUp, setLookingUp] = useState(false)

  // Login is now required to place and view orders — a logged-in customer's order history
  // lives on the Account page (see Account.jsx). This page stays around only so someone who
  // placed an order as a guest before this change can still track it with their order number
  // + phone, the same way they always could.
  useEffect(() => {
    if (!authLoading && user) navigate('/account', { replace: true })
  }, [authLoading, user, navigate])

  useEffect(() => {
    setRemembered(getRememberedOrders())
  }, [])

  function removeFromList(orderNumber) {
    setRemembered((prev) => prev.filter((o) => o.orderNumber !== orderNumber))
  }

  async function handleTrack(ev) {
    ev.preventDefault()
    setLookupError('')
    const orderNumber = form.orderNumber.trim().toUpperCase()
    const phone = form.phone.trim()
    if (!orderNumber || phone.replace(/\D/g, '').length < 8) {
      setLookupError('Enter your order number and the phone number used at checkout.')
      return
    }
    setLookingUp(true)
    try {
      await trackOrder(orderNumber, phone)
      rememberOrder(orderNumber, phone)
      setRemembered(getRememberedOrders())
      setForm({ orderNumber: '', phone: '' })
    } catch (err) {
      setLookupError(err.message || 'No order found with that order number and phone number.')
    } finally {
      setLookingUp(false)
    }
  }

  if (authLoading || user) return null

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>My Orders</h2>
        </div>

        <div
          className="cart-summary"
          style={{ maxWidth: 420, margin: '0 auto 24px', textAlign: 'center' }}
        >
          <p style={{ margin: '0 0 10px', color: 'var(--text)' }}>
            Log in to place new orders and see your full order history under your account.
          </p>
          <Link to="/login" className="btn btn-gold btn-sm">
            Log in / Create account
          </Link>
        </div>

        <p style={{ color: 'var(--text-muted)', textAlign: 'center', fontSize: '0.82rem', marginBottom: 24 }}>
          Placed an order as a guest before? Look it up below with your order number and phone.
        </p>

        {remembered.length > 0 ? (
          <div style={{ maxWidth: 520, margin: '0 auto 32px' }}>
            {remembered.map((o) => (
              <OrderRow key={o.orderNumber} orderNumber={o.orderNumber} phone={o.phone} onGone={removeFromList} />
            ))}
          </div>
        ) : (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center', marginBottom: 32 }}>
            Orders you place on this device are remembered here automatically. On a new device, or
            if you cleared your browser data, look one up below.
          </p>
        )}

        <div className="item-detail" style={{ maxWidth: 420, margin: '0 auto' }}>
          <form className="form-grid" onSubmit={handleTrack} noValidate>
            <h4 style={{ margin: '0 0 4px', color: 'var(--gold-light)' }}>Track an order</h4>
            <div className="field">
              <label htmlFor="orderNumber">Order number</label>
              <input
                id="orderNumber"
                value={form.orderNumber}
                onChange={(e) => setForm({ ...form, orderNumber: e.target.value })}
                placeholder="S8-20260824-ABCDE"
              />
            </div>
            <div className="field">
              <label htmlFor="trackPhone">Phone number used at checkout</label>
              <input
                id="trackPhone"
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="10-digit mobile number"
                inputMode="tel"
              />
            </div>
            {lookupError && <div className="field-error">{lookupError}</div>}
            <button className="btn btn-gold btn-block" type="submit" disabled={lookingUp}>
              {lookingUp ? 'Looking up…' : 'Track order'}
            </button>
          </form>
        </div>
      </div>
    </section>
  )
}
