import type { ButtonHTMLAttributes, ReactNode } from 'react'

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'danger' | 'ghost'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  fullWidth?: boolean
  children: ReactNode
}

export function Button({
  variant = 'primary',
  fullWidth = false,
  className = '',
  children,
  ...props
}: ButtonProps) {
  const variantClass =
    variant === 'primary'
      ? 'primary'
      : variant === 'danger'
        ? 'danger'
        : variant === 'ghost'
          ? 'ghost'
          : 'secondary'

  return (
    <button
      className={`${variantClass} ${fullWidth ? 'wide' : ''} ${className}`.trim()}
      {...props}
    >
      {children}
    </button>
  )
}

