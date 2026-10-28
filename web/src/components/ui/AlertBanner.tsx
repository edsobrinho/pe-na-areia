interface AlertBannerProps {
  type: 'error' | 'success'
  message: string | null
  onDismiss: () => void
}

export function AlertBanner({ type, message, onDismiss }: AlertBannerProps) {
  if (!message) return null
  return (
    <div
      className={`banner ${type}`}
      role={type === 'error' ? 'alert' : 'status'}
      style={{ marginBottom: '1rem' }}
    >
      <span>{message}</span>
      <button type="button" onClick={onDismiss} aria-label="Fechar aviso">
        ×
      </button>
    </div>
  )
}

