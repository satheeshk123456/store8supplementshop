import { Route, Routes } from 'react-router-dom'
import Header from './components/Header'
import Footer from './components/Footer'
import WhatsAppButton from './components/WhatsAppButton'
import OffersBanner from './components/OffersBanner'
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

export default function App() {
  return (
    <AuthProvider>
      <CartProvider>
        <OffersBanner />
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
