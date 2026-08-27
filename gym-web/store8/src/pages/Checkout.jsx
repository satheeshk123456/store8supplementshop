import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import { createOrder } from '../api/orders'
import { formatInr } from '../utils/format'
import { rememberOrder } from '../utils/myOrdersStorage'

const EMPTY_FORM = { name: '', phone: '', address: '', city: '', pincode: '', note: '' }

export default function Checkout() {
  const { lines, subtotal, clear } = useCart()
  const navigate = useNavigate()
  const [form, setForm] = useState(EMPTY_FORM)
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const [apiError, setApiError] = useState('')

  function validate() {
    const e = {}
    if (form.name.trim().length < 2) e.name = 'Enter your full name'
    if (form.phone.replace(/\D/g, '').length < 8) e.phone = 'Enter a valid phone number'
    if (form.address.trim().length < 5) e.address = 'Enter your delivery address'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(ev) {
    ev.preventDefault()
    setApiError('')
    if (!validate()) return
    setSubmitting(true)
    try {
      const order = await createOrder({
        customer: form,
        lines: lines.map((l) => ({ item_id: l.itemId, variant_id: l.variantId, qty: l.qty })),
      })
      clear()
      rememberOrder(order.order_number, form.phone.trim())
      navigate(`/order-confirmed/${order.id}`, { state: { order } })
    } catch (err) {
      setApiError(err.message || 'Could not place your order. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  if (lines.length === 0) {
    navigate('/cart')
    return null
  }

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>Checkout</h2>
        </div>

        <div className="item-detail">
          <form className="form-grid" onSubmit={handleSubmit} noValidate>
            <div className="field">
              <label htmlFor="name">Full name</label>
              <input
                id="name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Your name"
              />
              {errors.name && <span className="field-error">{errors.name}</span>}
            </div>

            <div className="field">
              <label htmlFor="phone">Phone number</label>
              <input
                id="phone"
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="10-digit mobile number"
                inputMode="tel"
              />
              {errors.phone && <span className="field-error">{errors.phone}</span>}
            </div>

            <div className="field">
              <label htmlFor="address">Delivery address</label>
              <textarea
                id="address"
                rows={3}
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                placeholder="House no, street, area"
              />
              {errors.address && <span className="field-error">{errors.address}</span>}
            </div>

            <div className="form-grid two-col">
              <div className="field">
                <label htmlFor="city">City</label>
                <input id="city" value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
              </div>
              <div className="field">
                <label htmlFor="pincode">Pincode</label>
                <input id="pincode" value={form.pincode} onChange={(e) => setForm({ ...form, pincode: e.target.value })} />
              </div>
            </div>

            <div className="field">
              <label htmlFor="note">Note for the shop (optional)</label>
              <textarea
                id="note"
                rows={2}
                value={form.note}
                onChange={(e) => setForm({ ...form, note: e.target.value })}
                placeholder="Preferred delivery time, landmark, etc."
              />
            </div>

            {apiError && <div className="field-error">{apiError}</div>}

            <button className="btn btn-gold btn-block" type="submit" disabled={submitting}>
              {submitting ? 'Placing order…' : `Place order · ${formatInr(subtotal)}`}
            </button>
          </form>

          <div>
            <div className="cart-summary">
              <h4 style={{ marginTop: 0, color: 'var(--gold-light)' }}>Order summary</h4>
              {lines.map((l) => (
                <div className="summary-row" key={`${l.itemId}-${l.variantId}`}>
                  <span>
                    {l.productName} ({l.variantLabel}) × {l.qty}
                  </span>
                  <span>{formatInr(l.price * l.qty)}</span>
                </div>
              ))}
              <div className="summary-row total">
                <span>Total</span>
                <span>{formatInr(subtotal)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
