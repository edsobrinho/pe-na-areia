import { useState, type ChangeEvent } from 'react'
import { api } from '../../api'

interface ImageUploadFieldProps {
  label: string
  value: string
  onChange: (url: string) => void
  placeholder?: string
  shape?: 'circle' | 'banner' | 'square'
  helperText?: string
}

export function ImageUploadField({
  label,
  value,
  onChange,
  placeholder = 'https://...',
  shape = 'square',
  helperText,
}: ImageUploadFieldProps) {
  const [uploading, setUploading] = useState(false)
  const [uploadError, setUploadError] = useState<string | null>(null)

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return
    setUploading(true)
    setUploadError(null)
    try {
      const { secureUrl } = await api.uploadMenuItemPhoto(file)
      onChange(secureUrl)
    } catch (reason) {
      setUploadError(reason instanceof Error ? reason.message : 'Falha ao enviar imagem.')
    } finally {
      setUploading(false)
      event.target.value = ''
    }
  }

  const previewStyle =
    shape === 'circle'
      ? { width: 72, height: 72, borderRadius: '50%', objectFit: 'cover' as const, border: '2px solid #0284c7' }
      : shape === 'banner'
        ? { width: 140, height: 72, borderRadius: 10, objectFit: 'cover' as const, border: '1px solid #cbd5e1' }
        : { width: 72, height: 72, borderRadius: 10, objectFit: 'cover' as const, border: '1px solid #cbd5e1' }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
      <span style={{ fontWeight: 600, fontSize: '0.92rem' }}>{label}</span>
      <div style={{ display: 'flex', gap: '0.85rem', alignItems: 'center', flexWrap: 'wrap' }}>
        {value ? (
          <img src={value} alt={label} style={previewStyle} />
        ) : (
          <div
            style={{
              ...previewStyle,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: '#f1f5f9',
              color: '#64748b',
              fontSize: '0.75rem',
              textAlign: 'center',
              padding: 4,
            }}
          >
            Sem imagem
          </div>
        )}

        <div style={{ flex: 1, minWidth: 220, display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <label
              className="secondary"
              style={{
                cursor: uploading ? 'wait' : 'pointer',
                padding: '0.45rem 0.85rem',
                borderRadius: 8,
                fontSize: '0.85rem',
                margin: 0,
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.35rem',
              }}
            >
              {uploading ? '⏳ Enviando...' : '📤 Enviar Imagem'}
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                disabled={uploading}
                onChange={handleFileChange}
                style={{ display: 'none' }}
              />
            </label>
            {value && (
              <button
                type="button"
                className="ghost"
                onClick={() => onChange('')}
                style={{ fontSize: '0.8rem', padding: '0.35rem 0.6rem' }}
              >
                Remover
              </button>
            )}
          </div>
          <input
            type="url"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={placeholder}
            style={{ fontSize: '0.85rem', padding: '0.45rem 0.65rem' }}
          />
          {helperText && <small className="field-hint">{helperText}</small>}
          {uploadError && (
            <small className="field-error" role="alert">
              {uploadError}
            </small>
          )}
        </div>
      </div>
    </div>
  )
}

