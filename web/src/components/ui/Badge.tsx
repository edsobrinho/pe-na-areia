import type { ReactNode } from 'react'

export type BadgeTone = 'default' | 'eco' | 'warning' | 'highlight' | 'danger' | 'info'

interface BadgeProps {
  tone?: BadgeTone
  children: ReactNode
}

export function Badge({ tone = 'default', children }: BadgeProps) {
  const toneClass =
    tone === 'eco'
      ? 'badge eco'
      : tone === 'warning'
        ? 'badge warning'
        : tone === 'highlight'
          ? 'badge highlight'
          : tone === 'danger'
            ? 'badge danger'
            : tone === 'info'
              ? 'badge info'
              : 'badge'

  return <span className={toneClass}>{children}</span>
}

