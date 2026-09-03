import { Link, useLocation } from 'react-router-dom'
import { formatInr } from '../utils/format'

export default function OrderConfirmation() {
  const { state } = useLocation()
  const order = state?.order

  // Order details only ever come from the just-placed response (never fetched by id later —
  // that would let anyone who guesses an order id read another customer's name/phone/address).
  // On a refresh/reopen, `state` is gone — there's no internal id worth showing here either:
  // it isn't the order number and can't be used to track anything (My Orders needs the order
  // number + phone), so showing it just gives someone a dead reference to copy around. Point
  // straight at where the order actually lives instead.
  if (!order) {
    return (
      <section className="section">
        <div className="container center">
          <h2>Thanks — your order was placed</h2>
          <p style={{ color: 'var(--text-muted)', fontWeight: 600 }}>
            Your order has been received. Our Admin team will confirm product availability and the
            final order details. Once confirmed, the payment link will be shared with you on
            WhatsApp.
          </p>
          <p style={{ color: 'var(--text-muted)' }}>
            Save this page or a screenshot of your confirmation — refreshing clears the detailed
            summary for your privacy.
          </p>
          <p style={{ color: 'var(--text-muted)' }}>
            This order is saved under{' '}
            <Link to="/account" style={{ color: 'var(--gold-light)' }}>My Account</Link>, where you
            can check its current status any time.
          </p>
          <Link to="/" className="btn btn-gold">
            Continue shopping
          </Link>
        </div>
      </section>
    )
  }

  return (
    <section className="section">
      <div className="container center">
        <h2>🎉 Order placed successfully</h2>
        <p style={{ color: 'var(--gold-light)', fontWeight: 700 }}>{order.order_number}</p>
        <p style={{ color: 'var(--text-muted)', fontWeight: 600, maxWidth: 480, margin: '0 auto' }}>
          Your order has been received. Our Admin team will confirm product availability and the
          final order details. Once confirmed, the payment link will be shared with you on
          WhatsApp.
        </p>

        <div className="cart-summary" style={{ textAlign: 'left', maxWidth: 480, margin: '24px auto' }}>
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

        <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
          You can check this order's current status any time under{' '}
          <Link to="/account" style={{ color: 'var(--gold-light)' }}>My Account</Link>.
        </p>

        <Link to="/" className="btn btn-gold">
          Continue shopping
        </Link>
      </div>
    </section>
  )
}
