import { Link } from 'react-router-dom'
import logoMark from '../assets/brand/logo-mark.png'
import { useCart } from '../context/CartContext'

export default function Header() {
  const { count } = useCart()
  return (
    <header className="site-header">
      <div className="container">
        <Link to="/" className="brand">
          <img src={logoMark} alt="Store 8" />
          <span>
            <span className="brand-name">STORE 8</span>
            <span className="brand-sub">Supplement Shop</span>
          </span>
        </Link>
        <div className="header-actions">
          <Link to="/cart" className="cart-link" aria-label="Cart">
            <span>🛒</span>
            <span>Cart</span>
            {count > 0 && <span className="cart-badge">{count}</span>}
          </Link>
        </div>
      </div>
    </header>
  )
}
