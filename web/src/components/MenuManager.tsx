import { useMemo, useState } from 'react'
import { api, ApiError } from '../api'
import { CategoryTabs } from '../features/menu/CategoryTabs'
import type { MenuItem, MenuItemPayload } from '../types'
import { SectionCard } from './layout/SectionCard'
import { MenuItemFormDialog } from './MenuItemFormDialog'
import { AlertBanner } from './ui/AlertBanner'
import { Button } from './ui/Button'
import { EmptyState } from './ui/EmptyState'

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
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null)
  const [busy, setBusy] = useState(false)
  const [localError, setLocalError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)

  const filteredItems = useMemo(() => {
    if (selectedCategory === 'ALL') return menuItems
    return menuItems.filter((item) => (item.category || 'Outros') === selectedCategory)
  }, [menuItems, selectedCategory])

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
        setNotice(`Produto "${finalPayload.nome}" atualizado na categoria "${finalPayload.category}".`)
      } else {
        await api.createMenuItem(finalPayload)
        setNotice(`Produto "${finalPayload.nome}" cadastrado na categoria "${finalPayload.category}".`)
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
    <SectionCard
      eyebrow="Catálogo de Produtos por Categoria"
      title={`Produtos Cadastrados (${menuItems.length})`}
      description="Organize os pratos, porções e bebidas do seu restaurante/quiosque nas devidas categorias com fotos reais e selo de destaque."
      headerAction={
        <Button type="button" variant="primary" onClick={handleOpenCreate} disabled={busy}>
          {selectedCategory === 'ALL'
            ? '+ Novo Produto'
            : `+ Novo em "${selectedCategory}"`}
        </Button>
      }
    >
      <CategoryTabs
        items={menuItems}
        selectedCategory={selectedCategory}
        onSelectCategory={setSelectedCategory}
      />

      <AlertBanner type="error" message={localError ?? error} onDismiss={() => setLocalError(null)} />
      <AlertBanner type="success" message={notice} onDismiss={() => setNotice(null)} />

      {loading ? (
        <div className="loading-panel">Carregando cardápio…</div>
      ) : filteredItems.length === 0 ? (
        <EmptyState
          icon="🍽️"
          title={
            selectedCategory === 'ALL'
              ? 'Nenhum produto cadastrado no cardápio'
              : `Nenhum produto na categoria "${selectedCategory}"`
          }
          description="Clique no botão abaixo para cadastrar seu primeiro produto com foto nesta categoria."
          action={
            <Button type="button" variant="primary" onClick={handleOpenCreate}>
              + Cadastrar Produto Agora
            </Button>
          }
        />
      ) : (
        <div className="menu-grid">
          {filteredItems.map((item) => (
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
                {item.descricao && (
                  <p className="muted" style={{ fontSize: 12, margin: '4px 0' }}>
                    {item.descricao}
                  </p>
                )}
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
          defaultCategory={selectedCategory}
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
    </SectionCard>
  )
}
