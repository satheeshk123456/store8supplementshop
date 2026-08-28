import { Link } from 'react-router-dom'
import logoMark from '../assets/brand/logo-mark.png'
import { useCart } from '../context/CartContext'
import { useAuth } from '../context/AuthContext'

export default function Header() {
  const { count } = useCart()
  const { isLoggedIn, loading } = useAuth()
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
          <Link to="/search" className="icon-btn" aria-label="Search">
            🔍
          </Link>
          <Link to="/brands" className="header-link">
            Brands
          </Link>
          <Link to="/my-orders" className="header-link">
            My Orders
          </Link>
          {!loading && (
            <Link to={isLoggedIn ? '/account' : '/login'} className="header-link">
              {isLoggedIn ? 'My Account' : 'Login'}
            </Link>
          )}
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
