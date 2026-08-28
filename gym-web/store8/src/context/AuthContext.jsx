import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
} from 'firebase/auth'
import { auth } from '../firebase'
import { updateMyProfile } from '../api/customers'

// Optional customer login/registration — layered entirely on top of the existing guest
// checkout, which keeps working unchanged whether or not anyone is logged in (see Checkout.jsx
// and MyOrders.jsx). Logging in never changes MRP or Store 8 Customer Price anywhere on the
// site; it only unlocks the Account page's order history so a customer doesn't have to keep
// re-typing their order number + phone.
const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => {
      setUser(u)
      setLoading(false)
    })
    return unsub
  }, [])

  async function getToken() {
    if (!auth.currentUser) return null
    return auth.currentUser.getIdToken()
  }

  async function register({ name, email, phone, password }) {
    const cred = await createUserWithEmailAndPassword(auth, email, password)
    await updateProfile(cred.user, { displayName: name })
    const token = await cred.user.getIdToken()
    // Save name/phone to our own backend profile too (displayName alone isn't queryable /
    // shown on the admin side, and phone has nowhere to live in Firebase Auth itself).
    await updateMyProfile(token, { name, phone })
    return cred.user
  }

  async function login({ email, password }) {
    const cred = await signInWithEmailAndPassword(auth, email, password)
    return cred.user
  }

  async function logout() {
    await signOut(auth)
  }

  const value = useMemo(
    () => ({ user, loading, isLoggedIn: !!user, getToken, register, login, logout }),
    [user, loading],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
