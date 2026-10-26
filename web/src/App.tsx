import { useCallback, useEffect, useMemo, useState } from 'react'
import { api, ApiError, clearSession, readSession, storeSession } from './api'
import { MapPicker } from './MapPicker'
import type {
  AuthSession,
  BeachLocation,
  CreatedOrder,
  Kiosk,
  MenuItem,
  Partnership,
  PartnershipConfiguration,
  PartnershipOffer,
  PricingPreview,
  ReferencePoint,
} from './types'
import './App.css'

type Page = 'discover' | 'operator' | 'admin'
type CredentialsMode = 'login' | 'register'

const currency = (amount: number) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(amount)

function App() {
  const [session, setSession] = useState<AuthSession | null>(() => readSession())
  const [page, setPage] = useState<Page>('discover')
  const [partnerships, setPartnerships] = useState<Partnership[]>([])
  const [selectedPartnershipId, setSelectedPartnershipId] = useState('')
  const [kiosks, setKiosks] = useState<Kiosk[]>([])
  const [selectedKioskId, setSelectedKioskId] = useState('')
  const [offer, setOffer] = useState<PartnershipOffer | null>(null)
  const [quantities, setQuantities] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [authOpen, setAuthOpen] = useState(false)
  const [orderOpen, setOrderOpen] = useState(false)
  const [order, setOrder] = useState<CreatedOrder | null>(null)

  const selectedKiosk = kiosks.find((kiosk) => kiosk.id === selectedKioskId) ?? null
  const partnership = partnerships.find((item) => item.id === selectedPartnershipId) ?? null
  const subtotal = useMemo(() => {
    if (!selectedKiosk) return 0
    return selectedKiosk.cardapio.reduce(
      (sum, item) => sum + item.preco * (quantities[item.id] ?? 0),
      0,
    )
  }, [quantities, selectedKiosk])

  useEffect(() => {
    void api.listPartnerships()
      .then((items) => {
        setPartnerships(items)
        setSelectedPartnershipId(items[0]?.id ?? '')
        if (!items.length) setLoading(false)
      })
      .catch((reason: unknown) => {
        setError(messageOf(reason))
        setLoading(false)
      })
  }, [])

  useEffect(() => {
    if (!selectedPartnershipId) return
    let current = true
    void api.listKiosks(selectedPartnershipId)
      .then((items) => {
        if (!current) return
        setKiosks(items)
        setSelectedKioskId(items[0]?.id ?? '')
      })
      .catch((reason: unknown) => { if (current) setError(messageOf(reason)) })
      .finally(() => { if (current) setLoading(false) })
    return () => { current = false }
  }, [selectedPartnershipId])

  useEffect(() => {
    if (!selectedKioskId) return
    void api.listKioskOffers(selectedKioskId)
      .then((items) => setOffer(items.find((item) => item.partnershipId === selectedPartnershipId) ?? null))
      .catch((reason: unknown) => setError(messageOf(reason)))
  }, [selectedKioskId, selectedPartnershipId])

  const signIn = (nextSession: AuthSession) => {
    storeSession(nextSession)
    setSession(nextSession)
    setAuthOpen(false)
    setError(null)
    setSuccess(`Olá, ${nextSession.name}.`)
    if (nextSession.role === 'KIOSK_OPERATOR') setPage('operator')
    else if (nextSession.role === 'ADMIN') setPage('admin')
  }

  const signOut = () => {
    clearSession()
    setSession(null)
    setPage('discover')
    setSuccess('Sessão encerrada.')
  }

  const changeQuantity = (item: MenuItem, delta: number) => {
    setQuantities((current) => {
      const next = (current[item.id] ?? 0) + delta
      const result = { ...current }
      if (next <= 0) delete result[item.id]
      else result[item.id] = next
      return result
    })
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <a className="brand" href="#" onClick={(event) => { event.preventDefault(); setPage('discover') }}>
          <span className="brand-mark" aria-hidden="true">P</span>
          <span>Pé na Areia <small>pedidos na praia</small></span>
        </a>
        <nav className="main-nav" aria-label="Navegação principal">
          <button className={page === 'discover' ? 'nav-link active' : 'nav-link'} onClick={() => setPage('discover')}>
            Pedir
          </button>
          {session?.role === 'KIOSK_OPERATOR' && (
            <button className={page === 'operator' ? 'nav-link active' : 'nav-link'} onClick={() => setPage('operator')}>
              Meu quiosque
            </button>
          )}
          {session?.role === 'ADMIN' && (
            <button className={page === 'admin' ? 'nav-link active' : 'nav-link'} onClick={() => setPage('admin')}>
              Administração
            </button>
          )}
        </nav>
        <div className="account-actions">
          {session ? (
            <>
              <span className="account-name">{session.name}</span>
              <button className="button button-outline button-small" onClick={signOut}>Sair</button>
            </>
          ) : (
            <button className="button button-outline button-small" onClick={() => setAuthOpen(true)}>Entrar</button>
          )}
        </div>
      </header>

      <main>
        {error && <div className="notice notice-error" role="alert">{error}<button aria-label="Fechar aviso" onClick={() => setError(null)}>×</button></div>}
        {success && <div className="notice notice-success" role="status">{success}<button aria-label="Fechar aviso" onClick={() => setSuccess(null)}>×</button></div>}
        {page === 'operator' && session?.role === 'KIOSK_OPERATOR' && <OperatorDashboard />}
        {page === 'admin' && session?.role === 'ADMIN' && <AdminDashboard />}
        {page === 'discover' && (
          <>
            <section className="hero">
              <div className="hero-content">
                <span className="eyebrow">SANTOS · ENTREGA NA AREIA</span>
                <h1>Seu pedido, no seu<br /><em>cantinho de praia.</em></h1>
                <p>Escolha o canal e o quiosque. A gente encontra você pelo pin no mapa.</p>
                <div className="hero-selection">
                  <label htmlFor="partnership-select">Canal de venda</label>
                  <select
                    id="partnership-select"
                    value={selectedPartnershipId}
                    onChange={(event) => {
                      setLoading(true)
                      setError(null)
                      setKiosks([])
                      setSelectedKioskId('')
                      setQuantities({})
                      setOffer(null)
                      setOrder(null)
                      setSelectedPartnershipId(event.target.value)
                    }}
                    disabled={loading || partnerships.length === 0}
                  >
                    {partnerships.map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}
                  </select>
                </div>
              </div>
              <div className="hero-art" aria-hidden="true">
                <span className="sun" />
                <span className="wave wave-one" />
                <span className="wave wave-two" />
                <span className="beach-umbrella">☂</span>
              </div>
            </section>

            <section className="content-section">
              <div className="section-heading">
                <div>
                  <span className="eyebrow">CARDÁPIO DA ORLA</span>
                  <h2>{partnership ? `Disponível por ${partnership.name}` : 'Quiosques disponíveis'}</h2>
                </div>
                {selectedKiosk && <span className="chip chip-live"><span /> Aberto para pedidos</span>}
              </div>
              {loading ? (
                <div className="loading-panel" role="status">Carregando canais e quiosques…</div>
              ) : partnerships.length === 0 ? (
                <div className="empty-state">Nenhum canal de venda está disponível no momento.</div>
              ) : kiosks.length === 0 ? (
                <div className="empty-state">
                  <strong>Nenhum quiosque disponível neste canal.</strong>
                  <p>Escolha outro canal ou volte mais tarde.</p>
                </div>
              ) : (
                <div className="catalog-layout">
                  <aside className="kiosk-list" aria-label="Quiosques">
                    <h3>Quiosques</h3>
                    {kiosks.map((kiosk) => (
                      <button
                        className={selectedKioskId === kiosk.id ? 'kiosk-option selected' : 'kiosk-option'}
                        key={kiosk.id}
                        onClick={() => { setSelectedKioskId(kiosk.id); setQuantities({}); setOrder(null); setOffer(null) }}
                      >
                        <span className="kiosk-avatar" aria-hidden="true">{kiosk.nome.slice(0, 1)}</span>
                        <span><strong>{kiosk.nome}</strong><small>{kiosk.cardapio.length} itens no canal</small></span>
                        <span aria-hidden="true">›</span>
                      </button>
                    ))}
                  </aside>
                  <section className="menu-panel">
                    {selectedKiosk && (
                      <>
                        <div className="menu-heading">
                          <div><h3>{selectedKiosk.nome}</h3><p>Itens habilitados para este canal</p></div>
                          {offer && <span className="tag">{offer.prepMinutes} min de preparo</span>}
                        </div>
                        {offer && (
                          <div className="offer-rules">
                            <span>Pedido mínimo <strong>{currency(offer.minimumOrder)}</strong></span>
                            <span>Entrega <strong>{currency(offer.deliveryFee)}</strong> · paga pelo {offer.deliveryFeePayer === 'CLIENT' ? 'cliente' : 'quiosque'}</span>
                            <span>Pedidos <strong>{offer.acceptFrom.slice(0, 5)}–{offer.acceptUntil.slice(0, 5)}</strong></span>
                          </div>
                        )}
                        <div className="product-grid">
                          {selectedKiosk.cardapio.map((item) => (
                            <article className="product-card" key={item.id}>
                              <div className="product-icon" aria-hidden="true">🥥</div>
                              <div className="product-info">
                                <span className="product-category">{item.category || 'Outros'}</span>
                                <h4>{item.nome}</h4>
                                <p>{item.descricao}</p>
                                {item.returnablePackaging && <small className="returnable">Embalagem retornável</small>}
                                <strong>{currency(item.preco)}</strong>
                              </div>
                              <div className="quantity-control" aria-label={`Quantidade de ${item.nome}`}>
                                <button aria-label={`Remover ${item.nome}`} disabled={!quantities[item.id]} onClick={() => changeQuantity(item, -1)}>−</button>
                                <span>{quantities[item.id] ?? 0}</span>
                                <button aria-label={`Adicionar ${item.nome}`} onClick={() => changeQuantity(item, 1)}>+</button>
                              </div>
                            </article>
                          ))}
                        </div>
                        <div className="checkout-bar">
                          <div><small>Subtotal estimado</small><strong>{currency(subtotal)}</strong></div>
                          {order ? (
                            <span className="order-created">Pedido {order.id} criado · {order.status}</span>
                          ) : (
                            <button
                              className="button button-primary"
                              disabled={!Object.keys(quantities).length || !offer || subtotal < (offer?.minimumOrder ?? 0)}
                              onClick={() => {
                                if (!session || session.role !== 'CLIENT') setAuthOpen(true)
                                else setOrderOpen(true)
                              }}
                            >
                              Continuar para entrega <span aria-hidden="true">→</span>
                            </button>
                          )}
                        </div>
                        {offer && subtotal > 0 && subtotal < offer.minimumOrder && (
                          <p className="field-error">Adicione itens até atingir o mínimo de {currency(offer.minimumOrder)}.</p>
                        )}
                      </>
                    )}
                  </section>
                </div>
              )}
            </section>
          </>
        )}
      </main>

      <footer className="site-footer">
        <strong>Pé na Areia</strong>
        <span>Entrega na praia, do seu jeito.</span>
        <small>As opções PIX e cartão são registradas no pedido; não há cobrança pelo site nesta versão.</small>
      </footer>

      {authOpen && <AuthDialog onClose={() => setAuthOpen(false)} onAuthenticated={signIn} />}
      {orderOpen && selectedKiosk && partnership && session?.role === 'CLIENT' && (
        <CheckoutDialog
          kiosk={selectedKiosk}
          partnership={partnership}
          quantities={quantities}
          userId={session.userId}
          onClose={() => setOrderOpen(false)}
          onCreated={(created) => { setOrder(created); setOrderOpen(false); setQuantities({}) }}
          onError={setError}
        />
      )}
    </div>
  )
}

interface AuthDialogProps {
  onClose: () => void
  onAuthenticated: (session: AuthSession) => void
}

function AuthDialog({ onClose, onAuthenticated }: AuthDialogProps) {
  const [mode, setMode] = useState<CredentialsMode>('login')
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const session = mode === 'login'
        ? await api.login(email, password)
        : await api.registerClient(name, email, phone, password)
      onAuthenticated(session)
    } catch (reason: unknown) {
      setError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section className="dialog" role="dialog" aria-modal="true" aria-labelledby="auth-title">
        <button className="dialog-close" aria-label="Fechar" onClick={onClose}>×</button>
        <span className="eyebrow">BEM-VINDO À PRAIA</span>
        <h2 id="auth-title">{mode === 'login' ? 'Entre na sua conta' : 'Crie sua conta'}</h2>
        <p className="muted">A conta de operador é provisionada pela administração da plataforma.</p>
        <form onSubmit={(event) => void submit(event)} className="form-stack">
          {mode === 'register' && <Field label="Nome" value={name} onChange={setName} required />}
          {mode === 'register' && <Field label="Telefone" value={phone} onChange={setPhone} required />}
          <Field label="E-mail" type="email" value={email} onChange={setEmail} required />
          <Field label="Senha" type="password" value={password} onChange={setPassword} required minLength={6} />
          {error && <p className="field-error" role="alert">{error}</p>}
          <button className="button button-primary button-full" disabled={busy}>
            {busy ? 'Aguarde…' : mode === 'login' ? 'Entrar' : 'Criar conta de cliente'}
          </button>
        </form>
        <button className="text-button" onClick={() => { setMode(mode === 'login' ? 'register' : 'login'); setError(null) }}>
          {mode === 'login' ? 'Ainda não tem conta? Cadastre-se' : 'Já tem conta? Entrar'}
        </button>
      </section>
    </div>
  )
}

function OperatorDashboard() {
  const [configurations, setConfigurations] = useState<PartnershipConfiguration[]>([])
  const [selectedId, setSelectedId] = useState('')
  const [draft, setDraft] = useState<PartnershipConfiguration | null>(null)
  const [preview, setPreview] = useState<PricingPreview | null>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [notice, setNotice] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let current = true
    void api.listOperatorPartnerships()
      .then((values) => {
        if (!current) return
        setConfigurations(values)
        setSelectedId(values[0]?.partnershipId ?? '')
        setDraft(values[0] ?? null)
      })
      .catch((reason: unknown) => { if (current) setError(messageOf(reason)) })
      .finally(() => { if (current) setLoading(false) })
    return () => { current = false }
  }, [])

  const update = <K extends keyof PartnershipConfiguration>(key: K, value: PartnershipConfiguration[K]) => {
    setDraft((current) => current ? { ...current, [key]: value } : current)
  }

  const save = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!draft) return
    setBusy(true)
    setNotice(null)
    setError(null)
    try {
      const saved = await api.saveOperatorPartnership(draft.partnershipId, {
        ...draft,
        acceptFrom: toTime(draft.acceptFrom),
        acceptUntil: toTime(draft.acceptUntil),
      })
      setConfigurations((current) => current.map((item) => item.partnershipId === saved.partnershipId ? saved : item))
      setDraft(saved)
      setNotice('Configuração salva e aplicada aos próximos pedidos.')
    } catch (reason: unknown) {
      setError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  const runPreview = async () => {
    if (!draft) return
    const items = draft.productIds.slice(0, 2).map((menuItemId) => ({ menuItemId, quantity: 1 }))
    if (!items.length) {
      setError('Habilite ao menos um produto para calcular a prévia.')
      return
    }
    try {
      setError(null)
      const result = await api.preview(draft.partnershipId, items)
      setPreview(result)
    } catch (reason: unknown) {
      setError(messageOf(reason))
    }
  }

  if (loading) return <section className="dashboard"><div className="loading-panel">Carregando configurações…</div></section>
  if (error && !configurations.length) return <section className="dashboard"><div className="notice notice-error" role="alert">{error}</div></section>
  if (!configurations.length) return <section className="dashboard"><div className="empty-state">Não há canais disponíveis para configurar.</div></section>

  const categories = [...new Set(draft?.products.map((item) => item.category || 'Outros') ?? [])].sort()
  return (
    <section className="dashboard">
      <div className="dashboard-heading">
        <div><span className="eyebrow">ÁREA DO QUIOSQUE</span><h1>Parcerias e canais</h1>
          <p>Escolha onde vender e configure a oferta do seu quiosque.</p></div>
        <span className="dashboard-icon" aria-hidden="true">⚙</span>
      </div>
      {error && <div className="notice notice-error" role="alert">{error}<button onClick={() => setError(null)} aria-label="Fechar">×</button></div>}
      {notice && <div className="notice notice-success" role="status">{notice}</div>}
      <div className="settings-layout">
        <aside className="settings-nav" aria-label="Canais disponíveis">
          {configurations.map((item) => (
            <button key={item.partnershipId} className={selectedId === item.partnershipId ? 'settings-option selected' : 'settings-option'} onClick={() => {
              setSelectedId(item.partnershipId)
              setDraft(item)
              setPreview(null)
            }}>
              <span className="channel-icon" aria-hidden="true">◉</span><span><strong>{item.name}</strong><small>{item.channel}</small></span>
              <span className={item.active ? 'status-dot on' : 'status-dot'} />
            </button>
          ))}
        </aside>
        {draft && (
          <form className="settings-form" onSubmit={(event) => void save(event)}>
            <div className="form-title-row">
              <div><span className="eyebrow">{draft.channel}</span><h2>{draft.name}</h2></div>
              <label className="switch-row">
                <input type="checkbox" checked={draft.active} onChange={(event) => update('active', event.target.checked)} />
                <span className="switch" aria-hidden="true" /><span>{draft.active ? 'Ativa' : 'Pausada'}</span>
              </label>
            </div>
            {!draft.configured && <p className="notice notice-info">Configure e salve esta parceria para habilitar pedidos neste canal.</p>}

            <section className="form-section">
              <h3>Produtos e filtros</h3>
              <p className="muted">Selecione os itens que seu quiosque oferece neste canal.</p>
              <div className="product-check-list">
                {draft.products.map((item) => {
                  const checked = draft.productIds.includes(item.id)
                  const categoryExcluded = draft.filters.categories.length > 0 && !draft.filters.categories.includes(item.category || 'Outros')
                  const packagingExcluded = draft.filters.onlyReturnable && !item.returnablePackaging
                  return (
                    <label className="product-check" key={item.id}>
                      <input type="checkbox" checked={checked} onChange={() => update('productIds', checked ? draft.productIds.filter((id) => id !== item.id) : [...draft.productIds, item.id])} />
                      <span className="check-detail"><strong>{item.nome}</strong><small>{item.category || 'Outros'} · {currency(item.preco)}{item.returnablePackaging ? ' · retornável' : ''}</small>
                        {checked && (categoryExcluded || packagingExcluded) && <small className="field-error">{categoryExcluded ? 'Excluído pelo filtro de categoria.' : 'Excluído pelo filtro de embalagem retornável.'}</small>}
                      </span>
                      {!item.disponivel && <small className="muted">Indisponível no cardápio</small>}
                    </label>
                  )
                })}
              </div>
              <fieldset className="filter-box">
                <legend>Categorias deste canal</legend>
                <p className="muted">Sem categorias selecionadas, todas são aceitas.</p>
                <div className="inline-options">
                  {categories.map((category) => (
                    <label className="checkbox-line compact" key={category}>
                      <input type="checkbox" checked={draft.filters.categories.includes(category)} onChange={() => {
                        const selected = draft.filters.categories.includes(category)
                        update('filters', { ...draft.filters, categories: selected
                          ? draft.filters.categories.filter((value) => value !== category)
                          : [...draft.filters.categories, category] })
                      }} />
                      <span>{category}</span>
                    </label>
                  ))}
                  {!categories.length && <span className="muted">Sem categorias cadastradas.</span>}
                </div>
                <label className="checkbox-line">
                  <input type="checkbox" checked={draft.filters.onlyReturnable} onChange={(event) => update('filters', { ...draft.filters, onlyReturnable: event.target.checked })} />
                  <span>Somente produtos com embalagem retornável</span>
                </label>
              </fieldset>
            </section>

            <section className="form-section">
              <h3>Política de taxas</h3>
              <div className="field-grid">
                <Field label="Comissão (%)" type="number" min="0" max="30" step="0.01" value={draft.commissionPercent} onChange={(value) => update('commissionPercent', numberValue(value))} required />
                <Field label="Taxa de entrega (R$)" type="number" min="0" step="0.01" value={draft.deliveryFee} onChange={(value) => update('deliveryFee', numberValue(value))} required />
                <label className="field"><span>Quem paga a taxa?</span>
                  <select value={draft.deliveryFeePayer} onChange={(event) => update('deliveryFeePayer', event.target.value as 'CLIENT' | 'KIOSK')}>
                    <option value="CLIENT">Cliente</option><option value="KIOSK">Quiosque</option>
                  </select>
                </label>
              </div>
              <small className="muted">A comissão é calculada sobre o subtotal. Nenhuma cobrança ou repasse real é processado.</small>
            </section>

            <section className="form-section">
              <h3>Restrições de pedido</h3>
              <div className="field-grid">
                <Field label="Pedido mínimo (R$)" type="number" min="0" step="0.01" value={draft.minimumOrder} onChange={(value) => update('minimumOrder', numberValue(value))} required />
                <Field label="Máximo de unidades por pedido" type="number" min="1" step="1" value={draft.maxItemsPerOrder} onChange={(value) => update('maxItemsPerOrder', Math.floor(numberValue(value)))} required />
                <Field label="Início do atendimento" type="time" value={draft.acceptFrom.slice(0, 5)} onChange={(value) => update('acceptFrom', value)} required />
                <Field label="Fim do atendimento" type="time" value={draft.acceptUntil.slice(0, 5)} onChange={(value) => update('acceptUntil', value)} required />
                <Field label="Preparo (minutos)" type="number" min="0" step="1" value={draft.prepMinutes} onChange={(value) => update('prepMinutes', Math.floor(numberValue(value)))} required />
              </div>
              <small className="muted">Horários em America/Sao_Paulo. Se o fim for anterior ao início, o atendimento atravessa a meia-noite.</small>
            </section>

            <section className="preview-card">
              <div><span className="eyebrow">SIMULAÇÃO</span><h3>Prévia de um pedido</h3><p>Usa os preços e o cálculo atual do servidor.</p></div>
              <button type="button" className="button button-outline" onClick={() => void runPreview()}>Calcular exemplo</button>
              {preview && <div className="preview-values">
                <span>Subtotal<strong>{currency(preview.subtotal)}</strong></span>
                <span>Comissão ({preview.commissionPercent}%)<strong>− {currency(preview.commissionAmount)}</strong></span>
                <span>Entrega · {preview.deliveryFeePayer === 'CLIENT' ? 'cliente' : 'quiosque'}<strong>{currency(preview.deliveryFee)}</strong></span>
                <span>Total do cliente<strong>{currency(preview.customerTotal)}</strong></span>
                <span>Líquido estimado do quiosque<strong>{currency(preview.kioskNet)}</strong></span>
                <small>{preview.note}</small>
              </div>}
            </section>
            <div className="form-actions">
              <button className="button button-primary" disabled={busy}>{busy ? 'Salvando…' : 'Salvar configuração'}</button>
            </div>
          </form>
        )}
      </div>
    </section>
  )
}

function AdminDashboard() {
  const [kiosks, setKiosks] = useState<Kiosk[]>([])
  const [name, setName] = useState('')
  const [channel, setChannel] = useState('')
  const [email, setEmail] = useState('')
  const [kioskId, setKioskId] = useState('')
  const [notice, setNotice] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    void api.listAllKiosks()
      .then(setKiosks)
      .catch((reason: unknown) => setError(messageOf(reason)))
  }, [])

  const create = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    setNotice(null)
    try {
      const partnership = await api.createPartnership(name, channel)
      setNotice(`Canal ${partnership.name} criado.`)
      setName('')
      setChannel('')
    } catch (reason: unknown) {
      setError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  const assign = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    setNotice(null)
    try {
      const result = await api.assignOperator(email, kioskId)
      setNotice(`Operador ${result.email} associado ao quiosque ${result.kioskId}.`)
      setEmail('')
      setKioskId('')
    } catch (reason: unknown) {
      setError(messageOf(reason))
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className="dashboard admin-dashboard">
      <div className="dashboard-heading"><div><span className="eyebrow">ADMINISTRAÇÃO</span><h1>Canais e operadores</h1>
        <p>Contas de operador não podem ser criadas pelo cadastro público.</p></div></div>
      {error && <div className="notice notice-error" role="alert">{error}</div>}
      {notice && <div className="notice notice-success" role="status">{notice}</div>}
      <div className="admin-grid">
        <form className="admin-card form-stack" onSubmit={(event) => void create(event)}>
          <span className="eyebrow">CATÁLOGO GLOBAL</span><h2>Novo canal de venda</h2>
          <Field label="Nome exibido" value={name} onChange={setName} required maxLength={100} />
          <Field label="Identificador do canal" value={channel} onChange={setChannel} required maxLength={50} />
          <button className="button button-primary" disabled={busy}>Criar canal</button>
        </form>
        <form className="admin-card form-stack" onSubmit={(event) => void assign(event)}>
          <span className="eyebrow">ACESSO AO QUIOSQUE</span><h2>Atribuir operador</h2>
          <Field label="E-mail de uma conta existente" type="email" value={email} onChange={setEmail} required />
          <label className="field"><span>Quiosque</span>
            <select required value={kioskId} onChange={(event) => setKioskId(event.target.value)}>
              <option value="">Selecione um quiosque</option>
              {kiosks.map((kiosk) => <option key={kiosk.id} value={kiosk.id}>{kiosk.nome} · {kiosk.id}</option>)}
            </select>
          </label>
          <small className="muted">A conta deve ter sido criada previamente como cliente. A atribuição converte seu perfil para operador.</small>
          <button className="button button-primary" disabled={busy}>Atribuir operador</button>
        </form>
      </div>
    </section>
  )
}

interface CheckoutDialogProps {
  kiosk: Kiosk
  partnership: Partnership
  quantities: Record<string, number>
  userId: string
  onClose: () => void
  onCreated: (order: CreatedOrder) => void
  onError: (message: string) => void
}

function CheckoutDialog({ kiosk, partnership, quantities, userId, onClose, onCreated, onError }: CheckoutDialogProps) {
  const [points, setPoints] = useState<ReferencePoint[]>([])
  const [location, setLocation] = useState<BeachLocation>({
    latitude: 0,
    longitude: 0,
    pontoReferenciaId: '',
    descricaoLocal: '',
  })
  const [payment, setPayment] = useState<'PIX' | 'CARTAO'>('PIX')
  const [photo, setPhoto] = useState<File | null>(null)
  const [sustainablePackaging, setSustainablePackaging] = useState(false)
  const [hasPin, setHasPin] = useState(false)
  const [busy, setBusy] = useState(false)
  const [localError, setLocalError] = useState<string | null>(null)
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined

  useEffect(() => {
    void api.listReferencePoints().then(setPoints).catch((reason: unknown) => setLocalError(messageOf(reason)))
  }, [])

  const updateLocation = useCallback((latitude: number, longitude: number, referencePointId: string) => {
    setHasPin(true)
    setLocation((current) => ({ ...current, latitude, longitude, pontoReferenciaId: referencePointId }))
  }, [])

  const selectedPoint = points.find((point) => point.id === location.pontoReferenciaId)
  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!apiKey || !hasPin || !selectedPoint || !location.descricaoLocal.trim()) {
      setLocalError('Selecione um pin no mapa, confirme o posto de referência e descreva o local.')
      return
    }
    setBusy(true)
    setLocalError(null)
    try {
      const photoUpload = photo ? await api.uploadLocationPhoto(photo) : undefined
      const order = await api.createOrder({
        userId,
        kioskId: kiosk.id,
        partnershipId: partnership.id,
        itens: Object.entries(quantities).map(([menuItemId, quantidade]) => ({ menuItemId, quantidade })),
        formaPagamento: payment,
        embalagemSustentavel: sustainablePackaging,
        pinCliente: { latitude: location.latitude, longitude: location.longitude },
        pontoReferenciaId: location.pontoReferenciaId,
        descricaoLocal: location.descricaoLocal.trim(),
        ...(photoUpload ? { fotoLocalUrl: photoUpload.secureUrl } : {}),
      })
      onCreated(order)
    } catch (reason: unknown) {
      const message = messageOf(reason)
      setLocalError(message)
      onError(message)
    } finally {
      setBusy(false)
    }
  }

  const mapCallback = useCallback((latitude: number, longitude: number, pointId: string) => {
    updateLocation(latitude, longitude, pointId)
  }, [updateLocation])

  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section className="dialog checkout-dialog" role="dialog" aria-modal="true" aria-labelledby="checkout-title">
        <button className="dialog-close" aria-label="Fechar" onClick={onClose}>×</button>
        <span className="eyebrow">ÚLTIMO PASSO</span><h2 id="checkout-title">Onde você está?</h2>
        <p className="muted">O pin precisa estar a até 500 m do posto selecionado. A operação de entrega continua com Pé na Areia.</p>
        <form onSubmit={(event) => void submit(event)} className="form-stack">
          <MapPicker points={points} onChange={mapCallback} />
          <label className="field"><span>Posto de referência</span>
            <select required value={location.pontoReferenciaId} onChange={(event) => setLocation((current) => ({ ...current, pontoReferenciaId: event.target.value }))}>
              <option value="">Selecione o posto mais próximo</option>
              {points.map((point) => <option key={point.id} value={point.id}>{point.nome} · {point.trecho}</option>)}
            </select>
          </label>
          <label className="field"><span>Como encontrar você? <small>(até 140 caracteres)</small></span>
            <textarea value={location.descricaoLocal} maxLength={140} required placeholder="Ex.: guarda-sol azul perto da torre de salva-vidas" onChange={(event) => setLocation((current) => ({ ...current, descricaoLocal: event.target.value }))} />
          </label>
          <label className="field"><span>Foto do local <small>(opcional, até 5 MB)</small></span>
            <input type="file" accept="image/jpeg,image/png,image/webp" onChange={(event) => setPhoto(event.target.files?.[0] ?? null)} />
          </label>
          {kiosk.aceitaEmbalagemSustentavel && <label className="checkbox-line">
            <input type="checkbox" checked={sustainablePackaging} onChange={(event) => setSustainablePackaging(event.target.checked)} />
            <span>Prefiro embalagem sustentável</span>
          </label>}
          <label className="field"><span>Forma de pagamento registrada</span>
            <select value={payment} onChange={(event) => setPayment(event.target.value as 'PIX' | 'CARTAO')}>
              <option value="PIX">PIX</option><option value="CARTAO">Cartão</option>
            </select>
          </label>
          <p className="notice notice-info">A forma de pagamento é apenas registrada no pedido. Não há cobrança pelo site nesta versão.</p>
          {localError && <p className="field-error" role="alert">{localError}</p>}
          <button className="button button-primary button-full" disabled={busy || !apiKey || !hasPin || points.length === 0}>
            {busy ? 'Enviando pedido…' : 'Confirmar pedido'}
          </button>
        </form>
      </section>
    </div>
  )
}

interface FieldProps {
  label: string
  value: string | number
  onChange: (value: string) => void
  type?: string
  required?: boolean
  min?: string
  max?: string
  maxLength?: number
  minLength?: number
  step?: string
}

function Field({ label, value, onChange, type = 'text', required, min, max, maxLength, minLength, step }: FieldProps) {
  return (
    <label className="field">
      <span>{label}</span>
      <input
        type={type}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        required={required}
        min={min}
        max={max}
        maxLength={maxLength}
        minLength={minLength}
        step={step}
      />
    </label>
  )
}

function numberValue(value: string): number {
  const number = Number(value)
  return Number.isFinite(number) ? number : 0
}

function toTime(value: string): string {
  return value.length === 5 ? `${value}:00` : value
}

function messageOf(reason: unknown): string {
  if (reason instanceof ApiError) return reason.message
  if (reason instanceof Error) return reason.message
  return 'Ocorreu um erro inesperado. Tente novamente.'
}

export default App
