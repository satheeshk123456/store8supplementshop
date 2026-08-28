import { useState } from 'react'
import { Route, Routes } from 'react-router-dom'
import Header from './components/Header'
import Footer from './components/Footer'
import WhatsAppButton from './components/WhatsAppButton'
import SplashScreen from './components/SplashScreen'
import { CartProvider } from './context/CartContext'
import { AuthProvider } from './context/AuthContext'
import Home from './pages/Home'
import CategoryProducts from './pages/CategoryProducts'
import ProductBrands from './pages/ProductBrands'
import Brands from './pages/Brands'
import BrandItems from './pages/BrandItems'
import Search from './pages/Search'
import ItemDetail from './pages/ItemDetail'
import Cart from './pages/Cart'
import Checkout from './pages/Checkout'
import OrderConfirmation from './pages/OrderConfirmation'
import MyOrders from './pages/MyOrders'
import Login from './pages/Login'
import Register from './pages/Register'
import Account from './pages/Account'
import NotFound from './pages/NotFound'

const SPLASH_SEEN_KEY = 'store8_splash_seen'

export default function App() {
  // Plays once per browser session (not every page navigation, not every visit) — sessionStorage
  // clears when the tab/browser closes, so returning visitors in a new session see it again.
  const [showSplash, setShowSplash] = useState(() => {
    try {
      return sessionStorage.getItem(SPLASH_SEEN_KEY) !== '1'
    } catch {
      return true
    }
  })

  function dismissSplash() {
    try {
      sessionStorage.setItem(SPLASH_SEEN_KEY, '1')
    } catch {
      // sessionStorage can throw in private browsing / disabled-storage contexts — non-fatal,
      // the splash just shows again next time in that case.
    }
    setShowSplash(false)
  }

  if (showSplash) {
    return <SplashScreen onFinish={dismissSplash} />
  }

  return (
    <AuthProvider>
      <CartProvider>
        <Header />
        <main style={{ flex: 1 }}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/category/:categoryId" element={<CategoryProducts />} />
            <Route path="/product/:productId" element={<ProductBrands />} />
            <Route path="/brands" element={<Brands />} />
            <Route path="/brand/:brandId" element={<BrandItems />} />
            <Route path="/search" element={<Search />} />
            <Route path="/item/:itemId" element={<ItemDetail />} />
            <Route path="/cart" element={<Cart />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/order-confirmed/:orderId" element={<OrderConfirmation />} />
            <Route path="/my-orders" element={<MyOrders />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/account" element={<Account />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </main>
        <Footer />
        <WhatsAppButton />
      </CartProvider>
    </AuthProvider>
  )
}
