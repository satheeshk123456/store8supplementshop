import { useEffect, useRef, useState } from 'react'
// Filename kept exactly as supplied (spaces included) — Vite bundles it as a normal asset either way.
import splashVideo from '../assets/brand/WhatsApp Video 2026-08-28 at 12.01.58 PM.mp4'

// How long we wait before dismissing the splash on our own, in case the video fails to load
// or never fires 'ended' (slow connection, autoplay blocked, etc.) — the storefront should
// never get stuck behind a splash screen.
const MAX_SPLASH_MS = 8000

export default function SplashScreen({ onFinish }) {
  const [fading, setFading] = useState(false)
  const finishedRef = useRef(false)

  function finish() {
    if (finishedRef.current) return
    finishedRef.current = true
    setFading(true)
    // Matches the CSS fade-out transition duration below.
    setTimeout(onFinish, 350)
  }

  useEffect(() => {
    const t = setTimeout(finish, MAX_SPLASH_MS)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div className={`splash-screen ${fading ? 'splash-fade-out' : ''}`}>
      <video
        className="splash-video"
        src={splashVideo}
        autoPlay
        muted
        playsInline
        onEnded={finish}
        onError={finish}
      />
      <button type="button" className="splash-skip" onClick={finish}>
        Skip
      </button>
    </div>
  )
}
