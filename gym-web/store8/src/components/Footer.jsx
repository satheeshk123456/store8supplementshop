const ADDRESS = 'Door No: 1836, LPL Park Campus, Illayarasanendal Road, GVN College Post, Kovilpatti - 628502'
const MAPS_URL = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
  'Store 8 Supplement Shop, ' + ADDRESS,
)}`
const WHATSAPP_URL = `https://wa.me/916374358678?text=${encodeURIComponent(
  "Hi Store 8, I'd like to ask about a product.",
)}`

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div>
          <h4>Store 8 Supplement Shop</h4>
          <p>{ADDRESS}</p>
          <p>Second branch of Team Beast Sports Nutrition Shop, Madurai</p>
          <a href={MAPS_URL} target="_blank" rel="noreferrer">
            Get directions →
          </a>
        </div>
        <div>
          <h4>Contact us</h4>
          <a href="tel:+916374358678">Call: 6374358678</a>
          <a href="tel:+917397396527">Call: 7397396527</a>
          <a href={WHATSAPP_URL} target="_blank" rel="noreferrer">
            WhatsApp us
          </a>
          <a href="mailto:store8supplementsp@gmail.com">store8supplementsp@gmail.com</a>
        </div>
        <div>
          <h4>Follow</h4>
          <a href="https://instagram.com/Store8SupplementShop" target="_blank" rel="noreferrer">
            @Store8SupplementShop
          </a>
        </div>
      </div>
      <div className="container footer-bottom">One Store · One Journey · Your Complete Health Hub</div>
    </footer>
  )
}
