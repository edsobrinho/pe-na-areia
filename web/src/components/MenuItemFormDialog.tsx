import { useEffect, useState } from 'react'
import { COASTAL_CATEGORIES } from '../features/menu/CategoryTabs'
import type { MenuItem, MenuItemPayload } from '../types'

interface MenuItemFormDialogProps {
  item: MenuItem | null
  defaultCategory?: string
  onClose: () => void
  onSave: (payload: MenuItemPayload, photoFile: File | null) => Promise<void>
  busy: boolean
}

export function MenuItemFormDialog({
  item,
  defaultCategory,
  onClose,
  onSave,
  busy,
}: MenuItemFormDialogProps) {
  const [nome, setNome] = useState(item?.nome ?? '')
  const [category, setCategory] = useState(
    item?.category || (defaultCategory && defaultCategory !== 'ALL' ? defaultCategory : 'Porções'),
  )
  const [preco, setPreco] = useState(item ? String(item.preco) : '')
  const [descricao, setDescricao] = useState(item?.descricao ?? '')
  const [returnablePackaging, setReturnablePackaging] = useState(item?.returnablePackaging ?? false)
  const [destaque, setDestaque] = useState(item?.destaque ?? false)
  const [disponivel, setDisponivel] = useState(item?.disponivel ?? true)
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(item?.fotoUrl ?? null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!photoFile) return
    const url = URL.createObjectURL(photoFile)
    setPhotoPreview(url)
    return () => URL.revokeObjectURL(url)
  }, [photoFile])

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)

    const trimmedNome = nome.trim()
    if (!trimmedNome) {
      setError('Informe o nome do produto.')
      return
    }

    const numericPreco = Number(preco.replace(',', '.'))
    if (!Number.isFinite(numericPreco) || numericPreco <= 0) {
      setError('Informe um preço válido maior que zero.')
      return
    }

    const payload: MenuItemPayload = {
      nome: trimmedNome,
      descricao: descricao.trim(),
      preco: numericPreco,
      disponivel,
      category,
      returnablePackaging,
      fotoUrl: item?.fotoUrl ?? null,
      destaque,
    }

    try {
      await onSave(payload, photoFile)
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : 'Erro ao salvar item.')
    }
  }

  return (
    <div
      className="modal-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !busy) onClose()
      }}
    >
      <section className="dialog" role="dialog" aria-modal="true" aria-labelledby="menu-item-dialog-title">
        <button className="dialog-close" aria-label="Fechar" onClick={onClose} disabled={busy}>
          ×
        </button>
        <span className="eyebrow">{item ? 'EDITAR PRODUTO' : 'NOVO PRODUTO POR CATEGORIA'}</span>
        <h2 id="menu-item-dialog-title">{item ? `Editar ${item.nome}` : 'Cadastrar produto no cardápio'}</h2>

        <form className="form-stack" onSubmit={(event) => void handleSubmit(event)}>
          <label className="field">
            <span>Nome do produto *</span>
            <input
              type="text"
              placeholder="Ex: Porção de Camarão Empanado"
              value={nome}
              onChange={(event) => setNome(event.target.value)}
              required
              maxLength={100}
            />
          </label>

          <div className="form-row">
            <label className="field">
              <span>Categoria do Cardápio *</span>
              <select value={category} onChange={(event) => setCategory(event.target.value)}>
                {COASTAL_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </label>

            <label className="field">
              <span>Preço (R$) *</span>
              <input
                type="number"
                step="0.01"
                min="0.01"
                placeholder="Ex: 45.00"
                value={preco}
                onChange={(event) => setPreco(event.target.value)}
                required
              />
            </label>
          </div>

          <label className="field">
            <span>Descrição do Prato / Bebida (opcional)</span>
            <textarea
              placeholder="Ex: 400g acompanhado de molho tártaro e limão"
              value={descricao}
              onChange={(event) => setDescricao(event.target.value)}
              maxLength={240}
            />
          </label>

          <div className="photo-field">
            <label className="field">
              <span>Foto do produto (JPG, PNG ou WebP até 5MB)</span>
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={(event) => setPhotoFile(event.target.files?.[0] ?? null)}
              />
            </label>
            {photoPreview ? (
              <img src={photoPreview} alt="Prévia do produto" className="photo-preview" />
            ) : (
              <div className="photo-placeholder" aria-hidden="true">
                🍽️
              </div>
            )}
          </div>

          <label className="checkbox-line">
            <input
              type="checkbox"
              checked={destaque}
              onChange={(event) => setDestaque(event.target.checked)}
            />
            <span>⭐ Destacar como "Mais Pedido na Areia" no topo da vitrine</span>
          </label>

          <label className="checkbox-line">
            <input
              type="checkbox"
              checked={returnablePackaging}
              onChange={(event) => setReturnablePackaging(event.target.checked)}
            />
            <span>🌱 Possui embalagem retornável / sustentável</span>
          </label>

          <label className="checkbox-line">
            <input
              type="checkbox"
              checked={disponivel}
              onChange={(event) => setDisponivel(event.target.checked)}
            />
            <span>Disponível para pedidos imediatos</span>
          </label>

          {error && (
            <p className="field-error" role="alert">
              {error}
            </p>
          )}

          <div className="form-actions">
            <button type="button" className="button button-outline" onClick={onClose} disabled={busy}>
              Cancelar
            </button>
            <button type="submit" className="button button-primary" disabled={busy}>
              {busy ? 'Salvando…' : item ? 'Salvar alterações' : 'Criar produto'}
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}
