// Presentational only — falls back to a generic icon for any category slug we don't
// recognise yet, so a new category added from the admin app never breaks the UI.
const ICONS = {
  'muscle-protein': '💪',
  'weight-gain': '🏋️',
  'performance-workout': '⚡',
  'fat-loss': '🔥',
  'healthy-foods': '🥗',
  'general-health': '💊',
  'beauty-skin-recovery': '✨',
  'overall-health': '🌿',
  default: '🏪',
}

export function categoryIcon(key) {
  return ICONS[key] || ICONS.default
}
