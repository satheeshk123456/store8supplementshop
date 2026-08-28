// Floating click-to-chat button, visible on every page. Plain wa.me link — no paid API,
// no SDK, just opens WhatsApp (app on mobile, web on desktop) with a pre-filled message.
const WHATSAPP_NUMBER = '916374358678'
const PREFILL = encodeURIComponent("Hi Store 8, I'd like to ask about a product.")

export default function WhatsAppButton() {
  return (
    <a
      href={`https://wa.me/${WHATSAPP_NUMBER}?text=${PREFILL}`}
      target="_blank"
      rel="noreferrer"
      className="whatsapp-fab"
      aria-label="Chat with us on WhatsApp"
    >
      💬
    </a>
  )
}
