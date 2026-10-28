import { useEffect, useState } from 'react'
import { api, ApiError } from '../api'
import type { Kiosk, MenuItem, MenuItemPayload } from '../types'
import { MenuItemFormDialog } from './MenuItemFormDialog'

interface MenuManagerProps {
  menuItems: MenuItem[]
  onRefresh: () => void
  loading: boolean
  error: string | null
}

const currency = (amount: number) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(amount)

function messageOf(reason: unknown): string {
  if (reason instanceof ApiError) return reason.message
  if (reason instanceof Error) return reason.message
  return 'Ocorreu um erro inesperado. Tente novamente.'
}

export function MenuManager({ menuItems, onRefresh, loading, error }: MenuManagerProps) {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null)
  const [busy, setBusy] = useState(false)
  const [localError, setLocalError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)

  // Storefront state (Vitrine do Quiosque no App do Cliente)
  const [storefrontOpen, setStorefrontOpen] = useState(false)
  const [storefront, setStorefront] = useState<Kiosk | null>(null)
  const [descricaoCurta, setDescricaoCurta] = useState('')
  const [fotoCapaUrl, setFotoCapaUrl] = useState('')
  const [logoUrl, setLogoUrl] = useState('')
  const [destaquePopular, setDestaquePopular] = useState(true)
  const [aceitaSustentavel, setAceitaSustentavel] = useState(true)

  useEffect(() => {
    void api
      .getOperatorStorefront()
      .then((kiosk) => {
        setStorefront(kiosk)
        setDescricaoCurta(kiosk.descricaoCurta ?? '')
        setFotoCapaUrl(kiosk.fotoCapaUrl ?? '')
        setLogoUrl(kiosk.logoUrl ?? '')
        setDestaquePopular(kiosk.destaquePopular ?? true)
        setAceitaSustentavel(kiosk.aceitaEmbalagemSustentavel ?? true)
      })
      .catch(() => {
        // Ignorado caso ainda não carregado
      })
  }, [])

  const handleOpenCreate = () => {
    setEditingItem(null)
    setLocalError(null)
    setDialogOpen(true)
  }

  const handleOpenEdit = (item: MenuItem) => {
    setEditingItem(item)
    setLocalError(null)
    setDialogOpen(true)
  }

  const handleSaveStorefront = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setBusy(true)
    setLocalError(null)
    setNotice(null)
    try {
      const updated = await api.updateOperatorStorefront({
        descricaoCurta: descricaoCurta.trim(),
        fotoCapaUrl: fotoCapaUrl.trim() || null,
        logoUrl: logoUrl.trim() || null,
        aceitaEmbalagemSustentavel: aceitaSustentavel,
        destaquePopular,
      })
      setStorefront(updated)
      setNotice('Vitrine do quiosque atualizada com sucesso para o App do Cliente.')
      setStorefrontOpen(false)
    } catch (reason: unknown) {
      setLocalError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  const handleUploadStorefrontImage = async (
    file: File | null,
    target: 'capa' | 'logo',
  ) => {
    if (!file) return
    setBusy(true)
    setLocalError(null)
    try {
      const uploaded = await api.uploadMenuItemPhoto(file)
      if (target === 'capa') setFotoCapaUrl(uploaded.secureUrl)
      else setLogoUrl(uploaded.secureUrl)
      setNotice('Imagem enviada para o Cloudinary com sucesso!')
    } catch (reason: unknown) {
      setLocalError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  const handleSave = async (payload: MenuItemPayload, photoFile: File | null) => {
    setBusy(true)
    setLocalError(null)
    setNotice(null)
    try {
      let fotoUrl = payload.fotoUrl ?? null
      if (photoFile) {
        const uploaded = await api.uploadMenuItemPhoto(photoFile)
        fotoUrl = uploaded.secureUrl
      }

      const finalPayload: MenuItemPayload = {
        ...payload,
        fotoUrl,
      }

      if (editingItem) {
        await api.updateMenuItem(editingItem.id, finalPayload)
        setNotice(`Produto "${finalPayload.nome}" atualizado com sucesso.`)
      } else {
        await api.createMenuItem(finalPayload)
        setNotice(`Produto "${finalPayload.nome}" adicionado ao cardápio.`)
      }

      setDialogOpen(false)
      setEditingItem(null)
      onRefresh()
    } catch (reason: unknown) {
      const msg = messageOf(reason)
      setLocalError(msg)
      throw new Error(msg)
    } finally {
      setBusy(false)
    }
  }

  const handleDelete = async (item: MenuItem) => {
    if (!window.confirm(`Deseja realmente remover "${item.nome}" do cardápio?`)) return
    setBusy(true)
    setLocalError(null)
    setNotice(null)
    try {
      await api.deleteMenuItem(item.id)
      setNotice(`Produto "${item.nome}" removido.`)
      onRefresh()
    } catch (reason: unknown) {
      setLocalError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  const handleToggleAvailability = async (item: MenuItem) => {
    setBusy(true)
    setLocalError(null)
    try {
      await api.setMenuItemAvailability(item.id, !item.disponivel)
      onRefresh()
    } catch (reason: unknown) {
      setLocalError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="menu-manager">
      <div className="menu-manager-header">
        <div>
          <h2>Itens do Cardápio ({menuItems.length})</h2>
          <p className="muted">
            Cadastre seus produtos com foto, marque os mais pedidos e personalize a vitrine do seu quiosque no app.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button
            type="button"
            className="button button-outline"
            onClick={() => setStorefrontOpen((prev) => !prev)}
            disabled={busy}
          >
            🏖️ {storefrontOpen ? 'Ocultar Vitrine do Quiosque' : 'Configurar Vitrine no App'}
          </button>
          <button type="button" className="button button-primary" onClick={handleOpenCreate} disabled={busy}>
            + Adicionar Item
          </button>
        </div>
      </div>

      {storefrontOpen && (
        <form
          className="card"
          style={{ marginBottom: 18, padding: 16, border: '1px solid #d7e3e0', borderRadius: 12 }}
          onSubmit={(event) => void handleSaveStorefront(event)}
        >
          <h3 style={{ marginTop: 0 }}>🏖️ Vitrine do Quiosque no App do Cliente ({storefront?.nome ?? 'Meu Quiosque'})</h3>
          <p className="muted" style={{ marginBottom: 12 }}>
            Essas informações aparecem na Home de Descoberta, em "Quiosques Populares na Orla" e no topo da Loja do Quiosque.
          </p>
          <label className="field">
            <span>Especialidades / Descrição curta na orla</span>
            <input
              type="text"
              maxLength={160}
              placeholder="Ex: Porções de frutos do mar, água de coco e petiscos no Posto 4"
              value={descricaoCurta}
              onChange={(e) => setDescricaoCurta(e.target.value)}
            />
          </label>
          <div className="form-row" style={{ marginTop: 10 }}>
            <label className="field">
              <span>URL da Foto de Capa (ou envie arquivo abaixo)</span>
              <input
                type="text"
                placeholder="https://..."
                value={fotoCapaUrl}
                onChange={(e) => setFotoCapaUrl(e.target.value)}
              />
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={(e) => void handleUploadStorefrontImage(e.target.files?.[0] ?? null, 'capa')}
              />
            </label>
            <label className="field">
              <span>URL do Logo / Avatar do Quiosque</span>
              <input
                type="text"
                placeholder="https://..."
                value={logoUrl}
                onChange={(e) => setLogoUrl(e.target.value)}
              />
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={(e) => void handleUploadStorefrontImage(e.target.files?.[0] ?? null, 'logo')}
              />
            </label>
          </div>
          <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap', marginTop: 10 }}>
            <label className="checkbox-line">
              <input
                type="checkbox"
                checked={destaquePopular}
                onChange={(e) => setDestaquePopular(e.target.checked)}
              />
              <span>🔥 Exibir em "Quiosques Populares na Orla" no App</span>
            </label>
            <label className="checkbox-line">
              <input
                type="checkbox"
                checked={aceitaSustentavel}
                onChange={(e) => setAceitaSustentavel(e.target.checked)}
              />
              <span>♻️ Quiosque aceita Embalagem Sustentável / Retornável</span>
            </label>
          </div>
          <div className="form-actions" style={{ marginTop: 12 }}>
            <button type="submit" className="button button-primary" disabled={busy}>
              {busy ? 'Salvando…' : 'Salvar Vitrine'}
            </button>
          </div>
        </form>
      )}

      {(error || localError) && (
        <div className="notice notice-error" role="alert">
          {localError ?? error}
          <button onClick={() => setLocalError(null)} aria-label="Fechar">
            ×
          </button>
        </div>
      )}

      {notice && (
        <div className="notice notice-success" role="status">
          {notice}
        </div>
      )}

      {loading ? (
        <div className="loading-panel">Carregando cardápio…</div>
      ) : menuItems.length === 0 ? (
        <div className="empty-state">
          Nenhum item cadastrado no cardápio ainda. Clique em "+ Adicionar Item" para começar.
        </div>
      ) : (
        <div className="menu-grid">
          {menuItems.map((item) => (
            <article className="menu-card" key={item.id}>
              <div className="menu-card-photo">
                {item.fotoUrl ? (
                  <img src={item.fotoUrl} alt={item.nome} />
                ) : (
                  <span aria-hidden="true">🍽️</span>
                )}
              </div>
              <div className="menu-card-body">
                <div className="menu-card-name" title={item.nome}>
                  {item.nome}
                </div>
                <div className="menu-card-meta">
                  <span className="category-badge">{item.category || 'Outros'}</span>
                  {item.destaque && (
                    <span className="eco-badge" title="Exibido em Mais Pedidos no App">
                      ⭐ Destaque
                    </span>
                  )}
                  {item.returnablePackaging && (
                    <span className="eco-badge" title="Embalagem sustentável">
                      🌱 Retornável
                    </span>
                  )}
                </div>
                {item.descricao && <p className="muted" style={{ fontSize: 12, margin: '4px 0' }}>{item.descricao}</p>}
                <div className="menu-card-price">{currency(item.preco)}</div>
                <div className="menu-card-actions">
                  <label className="availability-toggle">
                    <input
                      type="checkbox"
                      checked={item.disponivel}
                      disabled={busy}
                      onChange={() => void handleToggleAvailability(item)}
                    />
                    <span>{item.disponivel ? 'Disponível' : 'Indisponível'}</span>
                  </label>
                  <div style={{ marginLeft: 'auto', display: 'flex', gap: 4 }}>
                    <button
                      type="button"
                      className="icon-btn"
                      title={`Editar ${item.nome}`}
                      aria-label={`Editar ${item.nome}`}
                      disabled={busy}
                      onClick={() => handleOpenEdit(item)}
                    >
                      ✏️
                    </button>
                    <button
                      type="button"
                      className="icon-btn danger"
                      title={`Excluir ${item.nome}`}
                      aria-label={`Excluir ${item.nome}`}
                      disabled={busy}
                      onClick={() => void handleDelete(item)}
                    >
                      🗑️
                    </button>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}

      {dialogOpen && (
        <MenuItemFormDialog
          item={editingItem}
          busy={busy}
          onClose={() => {
            if (!busy) {
              setDialogOpen(false)
              setEditingItem(null)
            }
          }}
          onSave={handleSave}
        />
      )}
    </div>
  )
}
