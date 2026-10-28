import type { ReactNode } from 'react'

interface PageHeaderProps {
  eyebrow?: string
  title: string
  subtitle?: string
  actions?: ReactNode
}

export function PageHeader({ eyebrow, title, subtitle, actions }: PageHeaderProps) {
  return (
    <div className="section-head" style={{ marginBottom: '1.25rem' }}>
      <div>
        {eyebrow && <p className="eyebrow">{eyebrow}</p>}
        <h1 style={{ margin: '0.2rem 0', fontSize: '1.6rem' }}>{title}</h1>
        {subtitle && <p className="muted" style={{ margin: 0 }}>{subtitle}</p>}
      </div>
      {actions && <div className="header-actions">{actions}</div>}
    </div>
  )
}

