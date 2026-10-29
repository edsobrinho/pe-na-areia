import { useEffect, useState, useCallback, useMemo } from 'react'
import { api, ApiError } from '../../api'
import type { KioskOrder, OrderStatus } from '../../types'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { AlertBanner } from '../../components/ui/AlertBanner'

interface PartnerOrdersManagerProps {
  kioskId: string
  kioskName: string
}

type OrderFilterTab = 'ALL' | 'PENDING' | 'PREPARING' | 'IN_ROUTE' | 'COMPLETED'

const CANCEL_REASONS = [
  'Item do cardápio indisponível no momento',
  'Cozinha com alta demanda / sobrecarregada',
  'Estabelecimento encerrando atendimento',
  'Ingrediente em falta no estoque',
  'Outro motivo',
]

function formatCurrency(val: number): string {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}

function formatTime(isoString?: string): string {
  if (!isoString) return ''
  try {
    const d = new Date(isoString)
    return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
  } catch {
    return ''
  }
}

function timeAgo(isoString?: string): string {
  if (!isoString) return ''
  try {
    const ms = Date.now() - new Date(isoString).getTime()
    const mins = Math.max(0, Math.floor(ms / 60000))
    if (mins < 1) return 'agora mesmo'
    if (mins === 1) return 'há 1 min'
    if (mins < 60) return `há ${mins} min`
    const hours = Math.floor(mins / 60)
    return `há ${hours}h`
  } catch {
    return ''
  }
}

export function PartnerOrdersManager({ kioskName }: PartnerOrdersManagerProps) {
  const [orders, setOrders] = useState<KioskOrder[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<OrderFilterTab>('ALL')
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [selectedPhoto, setSelectedPhoto] = useState<{ url: string; title: string } | null>(null)

  // Cancel dialog state
  const [cancelingOrder, setCancelingOrder] = useState<KioskOrder | null>(null)
  const [selectedReason, setSelectedReason] = useState(CANCEL_REASONS[0])
  const [customReason, setCustomReason] = useState('')
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null)

  const loadOrders = useCallback(async (silent = false) => {
    if (!silent) setLoading(true)
    setError(null)
    try {
      const data = await api.listOperatorOrders('ALL')
      setOrders(data)
    } catch (err) {
      if (!silent) {
        setError(err instanceof ApiError ? err.message : 'Não foi possível carregar os pedidos.')
      }
    } finally {
      if (!silent) setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadOrders(false)
  }, [loadOrders])

  useEffect(() => {
    if (!autoRefresh) return
    const interval = setInterval(() => {
      void loadOrders(true)
    }, 10000)
    return () => clearInterval(interval)
  }, [autoRefresh, loadOrders])

  // Counters
  const counts = useMemo(() => {
    const pending = orders.filter((o) => o.status === 'PAGO' || o.status === 'CRIADO').length
    const preparing = orders.filter((o) => o.status === 'EM_PREPARO').length
    const inRoute = orders.filter((o) => o.status === 'A_CAMINHO' || o.status === 'CHEGOU_NO_LOCAL').length
    const completed = orders.filter(
      (o) => o.status === 'ENTREGUE' || o.status === 'CANCELADO' || o.status === 'NAO_ENCONTRADO',
    ).length
    return { all: orders.length, pending, preparing, inRoute, completed }
  }, [orders])

  // Filtered orders
  const filteredOrders = useMemo(() => {
    return orders.filter((o) => {
      if (activeTab === 'PENDING') return o.status === 'PAGO' || o.status === 'CRIADO'
      if (activeTab === 'PREPARING') return o.status === 'EM_PREPARO'
      if (activeTab === 'IN_ROUTE') return o.status === 'A_CAMINHO' || o.status === 'CHEGOU_NO_LOCAL'
      if (activeTab === 'COMPLETED') {
        return o.status === 'ENTREGUE' || o.status === 'CANCELADO' || o.status === 'NAO_ENCONTRADO'
      }
      return true
    })
  }, [orders, activeTab])

  const handleAcceptOrder = async (orderId: string) => {
    setActionLoadingId(orderId)
    setError(null)
    setSuccess(null)
    try {
      await api.acceptOperatorOrder(orderId)
      setSuccess(`Pedido #${orderId.slice(-6).toUpperCase()} aceito! Iniciando preparo na cozinha.`)
      await loadOrders(true)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Não foi possível aceitar o pedido.')
    } finally {
      setActionLoadingId(null)
    }
  }

  const handleConfirmCancel = async () => {
    if (!cancelingOrder) return
    const reasonText =
      selectedReason === 'Outro motivo'
        ? customReason.trim() || 'Cancelado pelo quiosque'
        : selectedReason
    setActionLoadingId(cancelingOrder.id)
    setError(null)
    setSuccess(null)
    try {
      await api.cancelOperatorOrder(cancelingOrder.id, reasonText)
      setSuccess(`Pedido #${cancelingOrder.id.slice(-6).toUpperCase()} cancelado.`)
      setCancelingOrder(null)
      setSelectedReason(CANCEL_REASONS[0])
      setCustomReason('')
      await loadOrders(true)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Não foi possível cancelar o pedido.')
    } finally {
      setActionLoadingId(null)
    }
  }

  const renderStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'CRIADO':
      case 'PAGO':
        return <Badge tone="warning">🟡 Aguardando Aceite</Badge>
      case 'EM_PREPARO':
        return <Badge tone="info">🔵 Em Preparo na Cozinha</Badge>
      case 'A_CAMINHO':
        return <Badge tone="highlight">🏃 A Caminho da Areia</Badge>
      case 'CHEGOU_NO_LOCAL':
        return <Badge tone="warning">🏖️ Entregador Chegou no Ponto</Badge>
      case 'ENTREGUE':
        return <Badge tone="eco">🟢 Entregue com Sucesso</Badge>
      case 'CANCELADO':
        return <Badge tone="danger">🔴 Cancelado</Badge>
      case 'NAO_ENCONTRADO':
        return <Badge tone="danger">⚠️ Cliente Não Encontrado</Badge>
      default:
        return <Badge tone="default">{status}</Badge>
    }
  }

  return (
    <div className="orders-manager-container">
      {/* Top Banner & Control Bar */}
      <div className="orders-header-bar">
        <div>
          <h2>📦 Gestão de Pedidos em Tempo Real</h2>
          <p className="orders-subtitle">
            Comandas da cozinha, rastreamento de entregadores e confirmação na praia para{' '}
            <strong>{kioskName}</strong>.
          </p>
        </div>
        <div className="orders-header-actions">
          <label className="auto-refresh-toggle">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
            />
            <span>Auto-atualizar (10s)</span>
          </label>
          <Button
            variant="secondary"
            onClick={() => void loadOrders(false)}
            disabled={loading}
          >
            {loading ? 'Carregando...' : '🔄 Atualizar'}
          </Button>
        </div>
      </div>

      <AlertBanner type="error" message={error} onDismiss={() => setError(null)} />
      <AlertBanner type="success" message={success} onDismiss={() => setSuccess(null)} />

      {/* Filter Tabs */}
      <div className="orders-filter-tabs">
        <button
          type="button"
          className={`orders-filter-tab ${activeTab === 'ALL' ? 'active' : ''}`}
          onClick={() => setActiveTab('ALL')}
        >
          Todos <span className="tab-count">{counts.all}</span>
        </button>
        <button
          type="button"
          className={`orders-filter-tab ${activeTab === 'PENDING' ? 'active' : ''} ${
            counts.pending > 0 ? 'has-pending' : ''
          }`}
          onClick={() => setActiveTab('PENDING')}
        >
          Novos / Pendentes <span className="tab-count">{counts.pending}</span>
        </button>
        <button
          type="button"
          className={`orders-filter-tab ${activeTab === 'PREPARING' ? 'active' : ''}`}
          onClick={() => setActiveTab('PREPARING')}
        >
          Em Preparo <span className="tab-count">{counts.preparing}</span>
        </button>
        <button
          type="button"
          className={`orders-filter-tab ${activeTab === 'IN_ROUTE' ? 'active' : ''}`}
          onClick={() => setActiveTab('IN_ROUTE')}
        >
          Em Rota com Entregador <span className="tab-count">{counts.inRoute}</span>
        </button>
        <button
          type="button"
          className={`orders-filter-tab ${activeTab === 'COMPLETED' ? 'active' : ''}`}
          onClick={() => setActiveTab('COMPLETED')}
        >
          Finalizados <span className="tab-count">{counts.completed}</span>
        </button>
      </div>

      {/* Orders Grid / List */}
      {loading && orders.length === 0 ? (
        <div className="orders-loading-state">
          <div className="spinner" />
          <p>Buscando pedidos em tempo real...</p>
        </div>
      ) : filteredOrders.length === 0 ? (
        <div className="orders-empty-state">
          <span className="empty-icon">🏖️</span>
          <h3>Nenhum pedido nesta etapa</h3>
          <p>
            {activeTab === 'PENDING'
              ? 'Tudo em dia! Novos pedidos pagos aparecerão aqui para você aceitar.'
              : 'Nenhum pedido encontrado para o filtro selecionado.'}
          </p>
        </div>
      ) : (
        <div className="orders-grid">
          {filteredOrders.map((order) => {
            const isPending = order.status === 'PAGO' || order.status === 'CRIADO'
            const isPreparing = order.status === 'EM_PREPARO'
            const isInRoute = order.status === 'A_CAMINHO' || order.status === 'CHEGOU_NO_LOCAL'
            const isDelivered = order.status === 'ENTREGUE'
            const isCancelled = order.status === 'CANCELADO'
            const isNotFound = order.status === 'NAO_ENCONTRADO'
            const shortId = order.id.slice(-6).toUpperCase()

            return (
              <div
                key={order.id}
                className={`order-card ${isPending ? 'card-pending' : ''} ${
                  isDelivered ? 'card-delivered' : ''
                } ${isCancelled || isNotFound ? 'card-incident' : ''}`}
              >
                {/* Header */}
                <div className="order-card-header">
                  <div>
                    <span className="order-id-label">Pedido #{shortId}</span>
                    <span className="order-time-ago">{timeAgo(order.timeline?.criadoEm)}</span>
                  </div>
                  <div>{renderStatusBadge(order.status)}</div>
                </div>

                {/* Items & Value */}
                <div className="order-card-section order-items-box">
                  <h4 className="section-mini-title">🍳 ITENS DA COMANDA</h4>
                  <ul className="order-items-list">
                    {order.itens?.map((it, idx) => (
                      <li key={idx} className="order-item-row">
                        <span className="item-qty-badge">{it.quantidade}x</span>
                        <span className="item-name">{it.nome}</span>
                        <span className="item-price">
                          {formatCurrency(it.precoUnitario * it.quantidade)}
                        </span>
                      </li>
                    ))}
                  </ul>
                  <div className="order-total-bar">
                    <span>
                      Total · {order.formaPagamento === 'PIX' ? 'Pix' : 'Cartão'} (Pago)
                    </span>
                    <strong>{formatCurrency(order.valorTotal)}</strong>
                  </div>
                </div>

                {/* Beach Location & Customer Details */}
                <div className="order-card-section beach-location-box">
                  <h4 className="section-mini-title">📍 PONTO DE ENCONTRO NA PRAIA</h4>
                  {order.referenciaBarraca && (
                    <div className="beach-detail-row">
                      <strong>Barraca / Guarda-sol:</strong>{' '}
                      <span>{order.referenciaBarraca}</span>
                    </div>
                  )}
                  {order.descricaoLocal && (
                    <div className="beach-detail-row">
                      <strong>Referência:</strong> <span>{order.descricaoLocal}</span>
                    </div>
                  )}
                  {order.complementoLocal && (
                    <div className="beach-detail-row">
                      <strong>Complemento:</strong> <span>{order.complementoLocal}</span>
                    </div>
                  )}
                  {order.contatoNome && (
                    <div className="beach-detail-row">
                      <strong>Cliente na Areia:</strong>{' '}
                      <span>
                        {order.contatoNome}
                        {order.contatoTelefone ? ` · ${order.contatoTelefone}` : ''}
                      </span>
                    </div>
                  )}
                  {order.fotoLocalUrl && (
                    <div className="beach-photo-preview-wrap">
                      <img
                        src={order.fotoLocalUrl}
                        alt="Foto do Guarda-sol"
                        className="beach-photo-thumb"
                        onClick={() =>
                          setSelectedPhoto({
                            url: order.fotoLocalUrl!,
                            title: `Guarda-sol - Pedido #${shortId}`,
                          })
                        }
                      />
                      <button
                        type="button"
                        className="btn-view-photo"
                        onClick={() =>
                          setSelectedPhoto({
                            url: order.fotoLocalUrl!,
                            title: `Guarda-sol - Pedido #${shortId}`,
                          })
                        }
                      >
                        🔍 Ver foto ampliada
                      </button>
                    </div>
                  )}
                </div>

                {/* Courier Assigned Panel */}
                {(isInRoute || order.courierNome) && (
                  <div className="order-card-section courier-assigned-box">
                    <h4 className="section-mini-title">🚴 ENTREGADOR ALOCADO NA PRAIA</h4>
                    <div className="courier-profile-row">
                      <div className="courier-avatar">
                        {order.courierVeiculo === 'BICICLETA' ? '🚲' : '🏃'}
                      </div>
                      <div className="courier-details">
                        <strong>{order.courierNome ?? 'Runner Pé na Areia'}</strong>
                        <span className="courier-vehicle-tag">
                          {order.courierVeiculo === 'BICICLETA'
                            ? 'Bicicleta na Ciclovia'
                            : 'A pé na Faixa de Areia'}
                        </span>
                        <span className="courier-status-text">
                          {order.status === 'CHEGOU_NO_LOCAL'
                            ? '📍 Chegou no ponto de encontro · Procurando guarda-sol'
                            : '🚴 A caminho da barraca com o pedido'}
                        </span>
                      </div>
                    </div>
                    {order.courierTelefone && (
                      <div className="courier-contact-actions">
                        <a
                          href={`https://wa.me/55${order.courierTelefone.replace(/\D/g, '')}`}
                          target="_blank"
                          rel="noreferrer"
                          className="btn-whatsapp"
                        >
                          💬 WhatsApp do Entregador
                        </a>
                        <a
                          href={`tel:${order.courierTelefone.replace(/\D/g, '')}`}
                          className="btn-phone"
                        >
                          📞 Ligar ({order.courierTelefone})
                        </a>
                      </div>
                    )}
                  </div>
                )}

                {/* Final Outcome Banner */}
                {isDelivered && (
                  <div className="outcome-banner banner-delivered">
                    <span className="outcome-icon">✅</span>
                    <div>
                      <strong>Pedido Entregue com Sucesso!</strong>
                      <p>
                        Entregador confirmou a entrega dentro do raio da barraca às{' '}
                        {formatTime(order.timeline?.entregueEm)}.
                      </p>
                    </div>
                  </div>
                )}

                {isCancelled && (
                  <div className="outcome-banner banner-cancelled">
                    <span className="outcome-icon">❌</span>
                    <div>
                      <strong>Pedido Cancelado</strong>
                      <p>
                        Motivo: <em>{order.motivoCancelamento || 'Cancelado pelo quiosque ou cliente.'}</em>
                      </p>
                    </div>
                  </div>
                )}

                {isNotFound && (
                  <div className="outcome-banner banner-not-found">
                    <span className="outcome-icon">⚠️</span>
                    <div>
                      <strong>Cliente Não Encontrado na Areia</strong>
                      <p>
                        O entregador chegou ao ponto indicado, disparou sinalizadores e tentou contato,
                        mas o cliente não estava na barraca/guarda-sol informado.
                      </p>
                      {order.motivoCancelamento && (
                        <p className="incident-note">
                          Relato: <em>{order.motivoCancelamento}</em>
                        </p>
                      )}
                    </div>
                  </div>
                )}

                {/* Actions Footer */}
                <div className="order-card-actions">
                  {isPending && (
                    <>
                      <Button
                        variant="primary"
                        onClick={() => void handleAcceptOrder(order.id)}
                        disabled={actionLoadingId === order.id}
                      >
                        {actionLoadingId === order.id
                          ? 'Aceitando...'
                          : '✅ Aceitar Pedido & Iniciar Preparo'}
                      </Button>
                      <Button
                        variant="secondary"
                        onClick={() => setCancelingOrder(order)}
                        disabled={actionLoadingId === order.id}
                      >
                        ❌ Recusar Pedido
                      </Button>
                    </>
                  )}

                  {isPreparing && (
                    <div className="preparing-notice-row">
                      <span className="preparing-pulse-icon">🍳</span>
                      <span>
                        <strong>Em preparo na cozinha.</strong> Aguardando entregador disponível
                        aceitar a corrida para retirar no quiosque.
                      </span>
                      <Button
                        variant="secondary"
                        onClick={() => setCancelingOrder(order)}
                        disabled={actionLoadingId === order.id}
                      >
                        Cancelar
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Cancel Order Modal */}
      {cancelingOrder && (
        <div className="modal-overlay" onClick={() => setCancelingOrder(null)}>
          <div className="modal-dialog" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Recusar / Cancelar Pedido #{cancelingOrder.id.slice(-6).toUpperCase()}</h3>
              <button
                type="button"
                className="modal-close-btn"
                onClick={() => setCancelingOrder(null)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <p>Selecione o motivo da recusa ou cancelamento deste pedido:</p>
              <div className="reason-options-list">
                {CANCEL_REASONS.map((reason) => (
                  <label key={reason} className="reason-radio-label">
                    <input
                      type="radio"
                      name="cancelReason"
                      value={reason}
                      checked={selectedReason === reason}
                      onChange={() => setSelectedReason(reason)}
                    />
                    <span>{reason}</span>
                  </label>
                ))}
              </div>

              {selectedReason === 'Outro motivo' && (
                <div className="custom-reason-wrap">
                  <label htmlFor="custom-reason-input">Descreva o motivo:</label>
                  <textarea
                    id="custom-reason-input"
                    rows={3}
                    placeholder="Ex.: Cozinha encerrou o expediente ou falta de energia..."
                    value={customReason}
                    onChange={(e) => setCustomReason(e.target.value)}
                  />
                </div>
              )}
            </div>
            <div className="modal-footer">
              <Button variant="secondary" onClick={() => setCancelingOrder(null)}>
                Voltar
              </Button>
              <Button
                variant="primary"
                onClick={() => void handleConfirmCancel()}
                disabled={actionLoadingId === cancelingOrder.id}
              >
                {actionLoadingId === cancelingOrder.id ? 'Cancelando...' : 'Confirmar Cancelamento'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Photo Zoom Modal */}
      {selectedPhoto && (
        <div className="modal-overlay" onClick={() => setSelectedPhoto(null)}>
          <div className="modal-dialog photo-modal-dialog" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{selectedPhoto.title}</h3>
              <button
                type="button"
                className="modal-close-btn"
                onClick={() => setSelectedPhoto(null)}
              >
                ✕
              </button>
            </div>
            <div className="photo-modal-body">
              <img
                src={selectedPhoto.url}
                alt="Foto Ampliada do Guarda-Sol"
                className="photo-modal-full"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
