import type { ReactNode } from 'react'
import type { AuthSession } from '../../types'

export type PartnerTab = 'storefront' | 'menu' | 'partnerships' | 'admin'

interface AppShellProps {
  session: AuthSession | null
  activeTab: PartnerTab
  kioskName?: string | null
  onSelectTab: (tab: PartnerTab) => void
  onSignOut: () => void
  children: ReactNode
}

export function AppShell({
  session,
  activeTab,
  kioskName,
  onSelectTab,
  onSignOut,
  children,
}: AppShellProps) {
  return (
    <div className="app-shell">
      <header className="topbar">
        <a
          className="brand"
          href="#"
          onClick={(e) => {
            e.preventDefault()
            if (session?.role === 'ADMIN') onSelectTab('admin')
            else onSelectTab('storefront')
          }}
        >
          <span className="brand-mark" aria-hidden="true">
            🏖️
          </span>
          <span>
            Pé na Areia <small>Portal do Parceiro · Quiosques &amp; Restaurantes</small>
          </span>
        </a>

        {session ? (
          <>
            <nav className="nav-tabs" aria-label="Áreas do Portal do Parceiro">
              {(session.role === 'KIOSK_OPERATOR' || session.role === 'CLIENT') && (
                <>
                  <button
                    type="button"
                    className={activeTab === 'storefront' ? 'active' : ''}
                    onClick={() => onSelectTab('storefront')}
                  >
                    🏪 Estabelecimento &amp; Endereço
                  </button>
                  <button
                    type="button"
                    className={activeTab === 'menu' ? 'active' : ''}
                    onClick={() => onSelectTab('menu')}
                  >
                    🍽️ Produtos &amp; Categorias
                  </button>
                  <button
                    type="button"
                    className={activeTab === 'partnerships' ? 'active' : ''}
                    onClick={() => onSelectTab('partnerships')}
                  >
                    🤝 Canais &amp; Repasse
                  </button>
                </>
              )}
              {session.role === 'ADMIN' && (
                <button
                  type="button"
                  className={activeTab === 'admin' ? 'active' : ''}
                  onClick={() => onSelectTab('admin')}
                >
                  ⚙️ Administração Global
                </button>
              )}
            </nav>

            <div className="session-box">
              <div className="user-chip">
                <strong>{kioskName || session.name}</strong>
                <span>{session.role === 'ADMIN' ? 'Administrador' : 'Parceiro / Quiosque'}</span>
              </div>
              <button type="button" className="ghost" onClick={onSignOut}>
                Sair
              </button>
            </div>
          </>
        ) : (
          <div className="session-box">
            <span className="badge">Exclusivo para Quiosques &amp; Restaurantes da Orla</span>
          </div>
        )}
      </header>

      <main className="partner-main-container">{children}</main>
    </div>
  )
}

