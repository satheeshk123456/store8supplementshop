import { Link, useNavigate } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import { formatInr } from '../utils/format'
import { EmptyState } from '../components/StateViews'

export default function Cart() {
  const { lines, subtotal, updateQty, removeLine } = useCart()
  const navigate = useNavigate()

  if (lines.length === 0) {
    return (
      <section className="section">
        <div className="container">
          <EmptyState message="Your cart is empty." />
          <div className="center">
            <Link to="/" className="btn btn-gold">
              Start shopping
            </Link>
          </div>
        </div>
      </section>
    )
  }

  return (
    <section className="section">
      <div className="container">
        <div className="section-title">
          <h2>Your cart</h2>
        </div>

        <div className="item-detail">
          <div>
            {lines.map((l) => (
              <div className="cart-line" key={`${l.itemId}-${l.variantId}`}>
                {l.image ? <img src={l.image} alt={l.productName} /> : <div className="card-media" style={{ width: 64, height: 64 }} />}
                <div>
                  <div className="name">
                    {l.brandName} — {l.productName}
                  </div>
                  <div className="meta">
                    {l.variantLabel} · {formatInr(l.price)} each
                  </div>
                  <div className="qty-stepper mt-4" style={{ display: 'inline-flex' }}>
                    <button type="button" onClick={() => updateQty(l.itemId, l.variantId, l.qty - 1)}>
                      −
                    </button>
                    <span>{l.qty}</span>
                    <button type="button" onClick={() => updateQty(l.itemId, l.variantId, l.qty + 1)}>
                      +
                    </button>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div>{formatInr(l.price * l.qty)}</div>
                  <button
                    className="btn btn-sm btn-outline mt-4"
                    onClick={() => removeLine(l.itemId, l.variantId)}
                  >
                    Remove
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div>
            <div className="cart-summary">
              <div className="summary-row">
                <span>Subtotal</span>
                <span>{formatInr(subtotal)}</span>
              </div>
              <div className="summary-row">
                <span>Delivery</span>
                <span>Confirmed by shop</span>
              </div>
              <div className="summary-row total">
                <span>Total</span>
                <span>{formatInr(subtotal)}</span>
              </div>
              <button className="btn btn-gold btn-block mt-4" onClick={() => navigate('/checkout')}>
                Proceed to checkout
              </button>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: 10 }}>
                No online payment yet — pay on delivery / at pickup. The shop will confirm your order.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
