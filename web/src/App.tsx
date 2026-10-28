import { useCallback, useEffect, useState } from 'react'
import { api, ApiError, clearSession, readSession, storeSession } from './api'
import { AppShell, type PartnerTab } from './components/layout/AppShell'
import { PageHeader } from './components/layout/PageHeader'
import { MenuManager } from './components/MenuManager'
import { AlertBanner } from './components/ui/AlertBanner'
import { Badge } from './components/ui/Badge'
import { Button } from './components/ui/Button'
import { AdminPanel } from './features/admin/AdminPanel'
import { PartnerAuthPanel } from './features/auth/PartnerAuthPanel'
import { PartnershipConfigPanel } from './features/partnerships/PartnershipConfigPanel'
import { StorefrontIdentityForm } from './features/storefront/StorefrontIdentityForm'
import { TraditionalAddressForm } from './features/storefront/TraditionalAddressForm'
import type {
  AuthSession,
  Kiosk,
  KioskStorefrontPayload,
  MenuItem,
  Partnership,
  ReferencePoint,
} from './types'
import './App.css'

function messageOf(reason: unknown): string {
  if (reason instanceof ApiError) return reason.message
  if (reason instanceof Error) return reason.message
  return 'Ocorreu um erro inesperado.'
}

function App() {
  const [session, setSession] = useState<AuthSession | null>(() => readSession())
  const [activeTab, setActiveTab] = useState<PartnerTab>(() =>
    readSession()?.role === 'ADMIN' ? 'admin' : 'storefront',
  )
  const [kiosk, setKiosk] = useState<Kiosk | null>(null)
  const [menuItems, setMenuItems] = useState<MenuItem[]>([])
  const [menuLoading, setMenuLoading] = useState(false)
  const [menuError, setMenuError] = useState<string | null>(null)
  const [menuRefreshTrigger, setMenuRefreshTrigger] = useState(0)
  const [referencePoints, setReferencePoints] = useState<ReferencePoint[]>([])
  const [partnerships, setPartnerships] = useState<Partnership[]>([])
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  useEffect(() => {
    void api
      .listReferencePoints()
      .then(setReferencePoints)
      .catch(() => {
        // Fallback padrão se ainda carregando
      })
    void api
      .listPartnerships()
      .then(setPartnerships)
      .catch(() => {
        // Ignora erro inicial público
      })
  }, [])

  const loadPartnerData = useCallback(async () => {
    if (!session || session.role === 'ADMIN') return
    setMenuLoading(true)
    setMenuError(null)
    try {
      const [loadedKiosk, loadedItems] = await Promise.all([
        api.getOperatorStorefront(),
        api.listOperatorMenuItems(),
      ])
      setKiosk(loadedKiosk)
      setMenuItems(loadedItems)
      setMenuRefreshTrigger((prev) => prev + 1)
    } catch (reason) {
      // Se o usuário acabou de logar como CLIENT e ainda não criou quiosque, permite criá-lo na tela
      if (reason instanceof ApiError && reason.status === 403) {
        setKiosk(null)
      } else {
        setMenuError(messageOf(reason))
      }
    } finally {
      setMenuLoading(false)
    }
  }, [session])

  useEffect(() => {
    if (session && session.role !== 'ADMIN') {
      void loadPartnerData()
    }
  }, [session, loadPartnerData])

  const handleAuthenticated = (nextSession: AuthSession, initialKiosk?: Kiosk) => {
    setSession(nextSession)
    setError(null)
    if (initialKiosk) {
      setKiosk(initialKiosk)
      setMenuItems(initialKiosk.cardapio ?? [])
      setSuccess(
        `Parabéns, ${nextSession.name}! Seu estabelecimento "${initialKiosk.nome}" foi cadastrado. Agora envie sua logomarca e cadastre seus produtos nas categorias abaixo.`,
      )
      setActiveTab('storefront')
    } else if (nextSession.role === 'ADMIN') {
      setSuccess(`Bem-vindo à Administração Global, ${nextSession.name}.`)
      setActiveTab('admin')
    } else {
      setSuccess(`Bem-vindo de volta, ${nextSession.name}.`)
      setActiveTab('storefront')
    }
  }

  const handleSignOut = () => {
    clearSession()
    setSession(null)
    setKiosk(null)
    setMenuItems([])
    setSuccess('Sessão encerrada com sucesso.')
  }

  const handleSaveStorefront = async (payload: KioskStorefrontPayload) => {
    setError(null)
    setSuccess(null)
    try {
      if (!kiosk || session?.role !== 'KIOSK_OPERATOR') {
        const onboarded = await api.onboardPartner({
          ...payload,
          nome: payload.nome || kiosk?.nome || `Estabelecimento de ${session?.name ?? 'Parceiro'}`,
        })
        const updatedSession: AuthSession = {
          token: onboarded.token || session?.token || '',
          userId: onboarded.userId,
          name: onboarded.name,
          role: onboarded.role,
        }
        storeSession(updatedSession)
        setSession(updatedSession)
        setKiosk(onboarded.kiosk)
        setSuccess('Estabelecimento vinculado e dados salvos com sucesso!')
        return
      }

      const updated = await api.updateOperatorStorefront(payload)
      setKiosk(updated)
      setSuccess('Dados do estabelecimento e endereço atualizados com sucesso!')
    } catch (reason) {
      setError(messageOf(reason))
    }
  }

  const defaultKioskTemplate: Kiosk = kiosk ?? {
    id: 'novo-quiosque',
    nome: session ? `Restaurante / Quiosque de ${session.name}` : 'Meu Estabelecimento',
    ativo: true,
    aceitaEmbalagemSustentavel: true,
    destaquePopular: true,
    cidade: 'Santos',
    uf: 'SP',
    pontoReferenciaId: referencePoints[0]?.id ?? '6acfd917f737c71df923a343',
    cardapio: [],
  }

  return (
    <AppShell
      session={session}
      activeTab={activeTab}
      kioskName={kiosk?.nome}
      onSelectTab={setActiveTab}
      onSignOut={handleSignOut}
    >
      <AlertBanner type="error" message={error} onDismiss={() => setError(null)} />
      <AlertBanner type="success" message={success} onDismiss={() => setSuccess(null)} />

      {!session ? (
        <PartnerAuthPanel
          referencePoints={referencePoints}
          onAuthenticated={handleAuthenticated}
          onError={setError}
        />
      ) : session.role === 'ADMIN' || activeTab === 'admin' ? (
        <>
          <PageHeader
            eyebrow="Governança da Plataforma"
            title="Administração de Canais e Operadores"
            subtitle="Gerencie canais de parceria globais e associe operadores aos quiosques da orla."
          />
          <AdminPanel
            partnerships={partnerships}
            onPartnershipCreated={(created) =>
              setPartnerships((current) => [...current, created])
            }
            onSuccess={setSuccess}
            onError={setError}
          />
        </>
      ) : (
        <>
          <PageHeader
            eyebrow="Gestão do Parceiro · Orla de Santos/SP"
            title={defaultKioskTemplate.nome}
            subtitle={
              defaultKioskTemplate.logradouro
                ? `${defaultKioskTemplate.logradouro}, ${defaultKioskTemplate.numero ?? 'S/N'} · ${defaultKioskTemplate.bairro ?? ''} (${defaultKioskTemplate.cidade ?? 'Santos'}/${defaultKioskTemplate.uf ?? 'SP'})`
                : 'Configure a logomarca, o endereço tradicional e os produtos por categoria do seu estabelecimento.'
            }
            actions={
              <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
                <Badge tone="eco">
                  {menuItems.length} {menuItems.length === 1 ? 'produto' : 'produtos'} no cardápio
                </Badge>
                {activeTab === 'storefront' ? (
                  <Button
                    type="button"
                    variant="primary"
                    onClick={() => setActiveTab('menu')}
                  >
                    Ir para Produtos &amp; Categorias →
                  </Button>
                ) : (
                  <Button
                    type="button"
                    variant="secondary"
                    onClick={() => setActiveTab('storefront')}
                  >
                    🏪 Editar Logomarca &amp; Endereço
                  </Button>
                )}
              </div>
            }
          />

          {activeTab === 'storefront' && (
            <>
              <StorefrontIdentityForm
                key={`identity-${defaultKioskTemplate.id}-${defaultKioskTemplate.logoUrl ?? ''}-${defaultKioskTemplate.fotoCapaUrl ?? ''}`}
                kiosk={defaultKioskTemplate}
                onSave={handleSaveStorefront}
              />
              <TraditionalAddressForm
                key={`address-${defaultKioskTemplate.id}-${defaultKioskTemplate.cep ?? ''}-${defaultKioskTemplate.pontoReferenciaId ?? ''}`}
                kiosk={defaultKioskTemplate}
                referencePoints={referencePoints}
                onSave={handleSaveStorefront}
              />
            </>
          )}

          {activeTab === 'menu' && (
            <MenuManager
              menuItems={menuItems}
              loading={menuLoading}
              error={menuError}
              onRefresh={() => void loadPartnerData()}
            />
          )}

          {activeTab === 'partnerships' && (
            <PartnershipConfigPanel
              menuRefreshTrigger={menuRefreshTrigger}
              onSuccess={setSuccess}
              onError={setError}
            />
          )}
        </>
      )}
    </AppShell>
  )
}

export default App
