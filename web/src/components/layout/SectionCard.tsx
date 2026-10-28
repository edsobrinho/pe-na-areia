import type { ReactNode } from 'react'

interface SectionCardProps {
  eyebrow?: string
  title: string
  description?: string
  headerAction?: ReactNode
  children: ReactNode
  className?: string
}

export function SectionCard({
  eyebrow,
  title,
  description,
  headerAction,
  children,
  className = '',
}: SectionCardProps) {
  return (
    <section className={`panel ${className}`.trim()} style={{ marginBottom: '1.25rem' }}>
      <div className="section-head" style={{ marginBottom: '1rem' }}>
        <div>
          {eyebrow && <p className="eyebrow">{eyebrow}</p>}
          <h2 style={{ margin: '0.15rem 0' }}>{title}</h2>
          {description && <p className="muted" style={{ margin: 0 }}>{description}</p>}
        </div>
        {headerAction && <div>{headerAction}</div>}
      </div>
      {children}
    </section>
  )
}

