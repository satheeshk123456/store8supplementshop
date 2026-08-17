export function Loading({ label = 'Loading…' }) {
  return (
    <div className="state-box">
      <div className="spinner" />
      <p>{label}</p>
    </div>
  )
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="state-box error-box">
      <p>{message || 'Something went wrong.'}</p>
      {onRetry && (
        <button className="btn btn-outline btn-sm" onClick={onRetry}>
          Try again
        </button>
      )}
    </div>
  )
}

export function EmptyState({ message }) {
  return (
    <div className="state-box">
      <p>{message}</p>
    </div>
  )
}
