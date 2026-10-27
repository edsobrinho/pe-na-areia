import React, { useId, useState } from 'react'

export interface FormFieldProps {
  label: string
  name?: string
  value: string
  onChange: (value: string) => void
  onBlur?: () => void
  type?: 'text' | 'email' | 'password' | 'tel' | 'number'
  placeholder?: string
  maskFn?: (raw: string) => string
  error?: string | null
  required?: boolean
  disabled?: boolean
  autoComplete?: string
  inputMode?: 'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search'
  helperText?: string
}

export const FormField: React.FC<FormFieldProps> = ({
  label,
  name,
  value,
  onChange,
  onBlur,
  type = 'text',
  placeholder,
  maskFn,
  error,
  required,
  disabled,
  autoComplete = 'off',
  inputMode,
  helperText,
}) => {
  const generatedId = useId()
  const inputId = name ? `field-${name}` : generatedId
  const errorId = `${inputId}-error`
  const helperId = `${inputId}-helper`
  const [touched, setTouched] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value
    const formatted = maskFn ? maskFn(rawValue) : rawValue
    onChange(formatted)
  }

  const handleBlur = () => {
    setTouched(true)
    onBlur?.()
  }

  const showError = touched && Boolean(error)
  const ariaDescribedBy = showError ? errorId : helperText ? helperId : undefined

  return (
    <div className="form-field-wrapper" style={{ marginBottom: '1rem', display: 'flex', flexDirection: 'column' }}>
      <label
        htmlFor={inputId}
        style={{
          fontSize: '0.875rem',
          fontWeight: 600,
          marginBottom: '0.375rem',
          color: '#1e293b',
        }}
      >
        {label}
        {required && <span style={{ color: '#ef4444', marginLeft: '0.25rem' }} aria-hidden="true">*</span>}
      </label>

      <input
        id={inputId}
        name={name}
        type={type}
        value={value}
        onChange={handleChange}
        onBlur={handleBlur}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        autoComplete={autoComplete}
        inputMode={inputMode}
        aria-invalid={showError ? 'true' : 'false'}
        aria-describedby={ariaDescribedBy}
        style={{
          minHeight: '44px',
          padding: '0.625rem 0.875rem',
          borderRadius: '6px',
          border: `1.5px solid ${showError ? '#ef4444' : '#cbd5e1'}`,
          fontSize: '1rem',
          outline: 'none',
          backgroundColor: disabled ? '#f1f5f9' : '#ffffff',
          color: '#0f172a',
          transition: 'border-color 0.15s ease-in-out',
        }}
      />

      {showError ? (
        <span
          id={errorId}
          role="alert"
          style={{
            fontSize: '0.75rem',
            color: '#ef4444',
            marginTop: '0.25rem',
            fontWeight: 500,
          }}
        >
          {error}
        </span>
      ) : helperText ? (
        <span
          id={helperId}
          style={{
            fontSize: '0.75rem',
            color: '#64748b',
            marginTop: '0.25rem',
          }}
        >
          {helperText}
        </span>
      ) : null}
    </div>
  )
}

