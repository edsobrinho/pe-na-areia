import type { ReactNode } from 'react'

interface EmptyStateProps {
  icon?: string
  title: string
  description: string
  action?: ReactNode
}

export function EmptyState({ icon = '🏖️', title, description, action }: EmptyStateProps) {
  return (
    <div className="empty-box" style={{ textAlign: 'center', padding: '2rem 1.25rem' }}>
      <div style={{ fontSize: '2rem', marginBottom: '0.4rem' }} aria-hidden="true">
        {icon}
      </div>
      <strong>{title}</strong>
      <p style={{ margin: '0.35rem auto 1rem', maxWidth: 480 }}>{description}</p>
      {action && <div>{action}</div>}
    </div>
  )
}

