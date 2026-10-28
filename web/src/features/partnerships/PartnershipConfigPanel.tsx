import { useEffect, useState, type FormEvent } from 'react'
import { api } from '../../api'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import type { PartnershipConfiguration, PricingPreview } from '../../types'

interface PartnershipConfigPanelProps {
  menuRefreshTrigger: number
  onSuccess: (message: string) => void
  onError: (message: string) => void
}

const currency = (amount: number) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(amount)

export function PartnershipConfigPanel({
  menuRefreshTrigger,
  onSuccess,
  onError,
}: PartnershipConfigPanelProps) {
  const [configurations, setConfigurations] = useState<PartnershipConfiguration[]>([])
  const [selectedId, setSelectedId] = useState('')
  const [preview, setPreview] = useState<PricingPreview | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    void api
      .listOperatorPartnerships()
      .then((items) => {
        setConfigurations(items)
        setSelectedId((current) => current || (items[0]?.partnershipId ?? ''))
      })
      .catch((reason: unknown) =>
        onError(reason instanceof Error ? reason.message : 'Falha ao carregar parcerias.'),
      )
  }, [onError, menuRefreshTrigger])

  const selected = configurations.find((item) => item.partnershipId === selectedId) ?? null

  const updateSelected = (patch: Partial<PartnershipConfiguration>) => {
    setConfigurations((current) =>
      current.map((item) => (item.partnershipId === selectedId ? { ...item, ...patch } : item)),
    )
    setPreview(null)
  }

  const toggleProduct = (productId: string) => {
    if (!selected) return
    const next = selected.productIds.includes(productId)
      ? selected.productIds.filter((id) => id !== productId)
      : [...selected.productIds, productId]
    updateSelected({ productIds: next })
  }

  const toggleCategory = (category: string) => {
    if (!selected) return
    const current = selected.filters.categories
    const next = current.includes(category)
      ? current.filter((item) => item !== category)
      : [...current, category]
    updateSelected({ filters: { ...selected.filters, categories: next } })
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    if (!selected) return
    setSaving(true)
    try {
      const saved = await api.saveOperatorPartnership(selected.partnershipId, selected)
      setConfigurations((current) =>
        current.map((item) => (item.partnershipId === saved.partnershipId ? saved : item)),
      )
      onSuccess(`Configuração do canal "${saved.name}" salva com sucesso.`)
    } catch (reason) {
      onError(reason instanceof Error ? reason.message : 'Falha ao salvar canal.')
    } finally {
      setSaving(false)
    }
  }

  const simulate = async () => {
    if (!selected) return
    const sample = selected.products.find(
      (product) => product.disponivel && selected.productIds.includes(product.id),
    )
    if (!sample) {
      onError('Salve uma configuração com ao menos um produto disponível antes de simular.')
      return
    }
    try {
      const result = await api.preview(selected.partnershipId, [
        { menuItemId: sample.id, quantity: 2 },
      ])
      setPreview(result)
    } catch (reason) {
      onError(reason instanceof Error ? reason.message : 'Falha na simulação de repasse.')
    }
  }

  if (!selected) {
    return (
      <SectionCard
        eyebrow="Canais de Venda & Repasse"
        title="Configuração de Parcerias"
      >
        <EmptyState
          icon="🤝"
          title="Nenhuma parceria disponível"
          description="Verifique se o seu estabelecimento já possui canais ativos cadastrados."
        />
      </SectionCard>
    )
  }

  const categories = Array.from(
    new Set(selected.products.map((product) => product.category || 'Outros')),
  )

  return (
    <SectionCard
      eyebrow="Canais de Venda & Simulador Financeiro"
      title="Configurar Parcerias, Taxas e Repasse"
      description="Defina taxas de entrega na areia, pedido mínimo, janela de atendimento e quais produtos entram em cada canal."
      headerAction={
        <label style={{ margin: 0 }}>
          Canal ativo
          <select value={selectedId} onChange={(event) => setSelectedId(event.target.value)}>
            {configurations.map((item) => (
              <option key={item.partnershipId} value={item.partnershipId}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
      }
    >
      <form className="operator-grid" onSubmit={save}>
        <div className="stack">
          <label className="check">
            <input
              type="checkbox"
              checked={selected.active}
              onChange={(event) => updateSelected({ active: event.target.checked })}
            />
            <span>Oferta ativa para clientes no App</span>
          </label>

          <div className="two-col">
            <label>
              Comissão (%)
              <input
                type="number"
                min={0}
                max={30}
                step="0.5"
                value={selected.commissionPercent}
                onChange={(event) =>
                  updateSelected({ commissionPercent: Number(event.target.value) })
                }
              />
            </label>
            <label>
              Taxa de entrega na areia (R$)
              <input
                type="number"
                min={0}
                step="0.5"
                value={selected.deliveryFee}
                onChange={(event) => updateSelected({ deliveryFee: Number(event.target.value) })}
              />
            </label>
          </div>

          <div className="two-col">
            <label>
              Quem paga a entrega
              <select
                value={selected.deliveryFeePayer}
                onChange={(event) =>
                  updateSelected({
                    deliveryFeePayer: event.target.value as 'CLIENT' | 'KIOSK',
                  })
                }
              >
                <option value="CLIENT">Cliente</option>
                <option value="KIOSK">Quiosque / Restaurante</option>
              </select>
            </label>
            <label>
              Pedido mínimo (R$)
              <input
                type="number"
                min={0}
                step="1"
                value={selected.minimumOrder}
                onChange={(event) => updateSelected({ minimumOrder: Number(event.target.value) })}
              />
            </label>
          </div>

          <div className="three-col">
            <label>
              Máx. itens
              <input
                type="number"
                min={1}
                value={selected.maxItemsPerOrder}
                onChange={(event) =>
                  updateSelected({ maxItemsPerOrder: Number(event.target.value) })
                }
              />
            </label>
            <label>
              Abre às
              <input
                type="time"
                value={selected.acceptFrom.slice(0, 5)}
                onChange={(event) => updateSelected({ acceptFrom: `${event.target.value}:00` })}
              />
            </label>
            <label>
              Fecha às
              <input
                type="time"
                value={selected.acceptUntil.slice(0, 5)}
                onChange={(event) => updateSelected({ acceptUntil: `${event.target.value}:00` })}
              />
            </label>
          </div>

          <label>
            Preparo estimado (minutos)
            <input
              type="number"
              min={0}
              value={selected.prepMinutes}
              onChange={(event) => updateSelected({ prepMinutes: Number(event.target.value) })}
            />
          </label>

          <fieldset>
            <legend>Filtro de categorias no canal</legend>
            <div className="chip-row">
              {categories.map((category) => (
                <button
                  type="button"
                  key={category}
                  className={
                    selected.filters.categories.includes(category) ? 'chip active' : 'chip'
                  }
                  onClick={() => toggleCategory(category)}
                >
                  {category}
                </button>
              ))}
            </div>
            <label className="check">
              <input
                type="checkbox"
                checked={selected.filters.onlyReturnable}
                onChange={(event) =>
                  updateSelected({
                    filters: {
                      ...selected.filters,
                      onlyReturnable: event.target.checked,
                    },
                  })
                }
              />
              <span>Somente produtos com embalagem retornável</span>
            </label>
          </fieldset>
        </div>

        <div className="stack">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ margin: 0 }}>Produtos habilitados na parceria</h3>
            {selected.products.length > 0 && (
              <button
                type="button"
                className="ghost"
                style={{ fontSize: '0.8rem', padding: '0.3rem 0.6rem' }}
                onClick={() =>
                  updateSelected({
                    productIds: selected.products.map((p) => p.id),
                  })
                }
              >
                Selecionar todos ({selected.products.length})
              </button>
            )}
          </div>
          <div className="product-checks">
            {selected.products.map((product) => (
              <label key={product.id} className="product-check">
                <input
                  type="checkbox"
                  checked={selected.productIds.includes(product.id)}
                  onChange={() => toggleProduct(product.id)}
                />
                <span>
                  <strong>{product.nome}</strong>
                  <small>
                    {product.category || 'Outros'} · {currency(product.preco)}
                  </small>
                </span>
              </label>
            ))}
          </div>

          <div className="button-row">
            <Button type="submit" variant="primary" disabled={saving}>
              {saving ? 'Salvando...' : 'Salvar Configuração do Canal'}
            </Button>
            <Button type="button" variant="secondary" onClick={simulate}>
              Simular Repasse
            </Button>
          </div>

          {preview && (
            <div className="preview-box" aria-live="polite">
              <h4>Simulador de Repasse (2 unidades de amostra)</h4>
              <p>
                <span>Subtotal</span>
                <strong>{currency(preview.subtotal)}</strong>
              </p>
              <p>
                <span>Comissão ({preview.commissionPercent}%)</span>
                <strong>{currency(preview.commissionAmount)}</strong>
              </p>
              <p>
                <span>Entrega ({preview.deliveryFeePayer})</span>
                <strong>{currency(preview.deliveryFee)}</strong>
              </p>
              <p>
                <span>Total pago pelo cliente</span>
                <strong>{currency(preview.customerTotal)}</strong>
              </p>
              <p>
                <span>Líquido do Quiosque/Restaurante</span>
                <strong>{currency(preview.kioskNet)}</strong>
              </p>
              <small>{preview.note}</small>
            </div>
          )}
        </div>
      </form>
    </SectionCard>
  )
}

