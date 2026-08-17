// Presentational only — falls back to a generic icon for any category slug we don't
// recognise yet, so a new category added from the admin app never breaks the UI.
const ICONS = {
  'weight-gain': '🏋️',
  'muscle-building': '💪',
  'fat-loss': '🔥',
  'strength-performance': '⚡',
  'recovery-endurance': '🔄',
  'general-health': '💊',
  'organ-digestive': '🌿',
  'beauty-bone-sleep': '✨',
  default: '🏪',
}

export function categoryIcon(key) {
  return ICONS[key] || ICONS.default
}
