import { createContext, useContext, useEffect, useMemo, useReducer } from 'react'

// Cart lives in localStorage only — there's no customer login, so this is the simplest
// storage that survives a page refresh. The server never trusts these prices; at checkout
// we only send { item_id, variant_id, qty } and the backend looks up the real price/stock.
const STORAGE_KEY = 'store8_cart_v1'
const CartContext = createContext(null)

function loadInitial() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

function lineKey(itemId, variantId) {
  return `${itemId}::${variantId}`
}

function reducer(state, action) {
  switch (action.type) {
    case 'ADD': {
      const { line } = action
      const key = lineKey(line.itemId, line.variantId)
      const existing = state.find((l) => lineKey(l.itemId, l.variantId) === key)
      if (existing) {
        return state.map((l) =>
          lineKey(l.itemId, l.variantId) === key ? { ...l, qty: l.qty + line.qty } : l,
        )
      }
      return [...state, line]
    }
    case 'UPDATE_QTY': {
      const { itemId, variantId, qty } = action
      if (qty <= 0) {
        return state.filter((l) => lineKey(l.itemId, l.variantId) !== lineKey(itemId, variantId))
      }
      return state.map((l) =>
        lineKey(l.itemId, l.variantId) === lineKey(itemId, variantId) ? { ...l, qty } : l,
      )
    }
    case 'REMOVE':
      return state.filter((l) => lineKey(l.itemId, l.variantId) !== lineKey(action.itemId, action.variantId))
    case 'CLEAR':
      return []
    default:
      return state
  }
}

export function CartProvider({ children }) {
  const [lines, dispatch] = useReducer(reducer, undefined, loadInitial)

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(lines))
  }, [lines])

  const value = useMemo(() => {
    const count = lines.reduce((sum, l) => sum + l.qty, 0)
    const subtotal = lines.reduce((sum, l) => sum + l.qty * l.price, 0)
    return {
      lines,
      count,
      subtotal,
      addLine: (line) => dispatch({ type: 'ADD', line }),
      updateQty: (itemId, variantId, qty) => dispatch({ type: 'UPDATE_QTY', itemId, variantId, qty }),
      removeLine: (itemId, variantId) => dispatch({ type: 'REMOVE', itemId, variantId }),
      clear: () => dispatch({ type: 'CLEAR' }),
    }
  }, [lines])

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>
}

export function useCart() {
  const ctx = useContext(CartContext)
  if (!ctx) throw new Error('useCart must be used inside <CartProvider>')
  return ctx
}
