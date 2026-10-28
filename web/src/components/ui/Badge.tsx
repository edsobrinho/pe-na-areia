import type { ReactNode } from 'react'

export type BadgeTone = 'default' | 'eco' | 'warning' | 'highlight'

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
          : 'badge'

  return <span className={toneClass}>{children}</span>
}

