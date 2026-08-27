import { useEffect, useState } from 'react'
import { trackOrder } from '../api/orders'
import { formatInr } from '../utils/format'
import { forgetOrder, getRememberedOrders, rememberOrder } from '../utils/myOrdersStorage'

const STATUS_LABEL = {
  pending: 'Order received',
  confirmed: 'Confirmed',
  packed: 'Packed',
  shipped: 'Shipped',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
}

const STATUS_COLOR = {
  pending: 'var(--text-muted)',
  confirmed: 'var(--gold-light)',
  packed: 'var(--gold-light)',
  shipped: 'var(--gold-light)',
  delivered: 'var(--success)',
  cancelled: 'var(--danger)',
}

function StatusPill({ status }) {
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
      {STATUS_LABEL[status] || status}
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
        <StatusPill status={order.status} />
      </div>
      {order.created_at && (
        <p style={{ color: 'var(--text-muted)', fontSize: '0.8rem', margin: '4px 0 12px' }}>
          Placed {new Date(order.created_at).toLocaleString()}
        </p>
      )}
      {order.items.map((l) => (
        <div className="summary-row" key={`${l.item_id}-${l.variant_id}`}>
          <span>
            {l.brand_name} {l.product_name} ({l.variant_label}) × {l.qty}
          </span>
          <span>{formatInr(l.subtotal)}</span>
        </div>
      ))}
      <div className="summary-row total">
        <span>Total</span>
        <span>{formatInr(order.total_amount)}</span>
      </div>
    </div>
  )
}

export default function MyOrders() {
  const [remembered, setRemembered] = useState([])
  const [form, setForm] = useState({ orderNumber: '', phone: '' })
  const [lookupError, setLookupError] = useState('')
  const [lookingUp, setLookingUp] = useState(false)

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

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>My Orders</h2>
        </div>

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
