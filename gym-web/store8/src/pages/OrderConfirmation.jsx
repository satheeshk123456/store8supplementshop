import { Link, useLocation, useParams } from 'react-router-dom'
import { formatInr } from '../utils/format'

export default function OrderConfirmation() {
  const { orderId } = useParams()
  const { state } = useLocation()
  const order = state?.order

  // Order details only ever come from the just-placed response (never fetched by id later —
  // that would let anyone who guesses an order id read another customer's name/phone/address).
  if (!order) {
    return (
      <section className="section">
        <div className="container center">
          <h2>Thanks — your order was placed</h2>
          <p style={{ color: 'var(--text-muted)' }}>
            Order reference: <strong>{orderId}</strong>
          </p>
          <p style={{ color: 'var(--text-muted)' }}>
            Save this page or a screenshot of your confirmation — refreshing clears the detailed
            summary for your privacy. The shop has been notified and will contact you shortly.
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
        <p style={{ color: 'var(--text-muted)' }}>
          The shop has been notified and will confirm your order shortly. No payment was collected —
          pay on delivery / at pickup.
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

        <Link to="/" className="btn btn-gold">
          Continue shopping
        </Link>
      </div>
    </section>
  )
}
