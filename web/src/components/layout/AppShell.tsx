import type { ReactNode } from 'react'
import type { AuthSession } from '../../types'

export type PartnerTab = 'identity' | 'address' | 'menu' | 'partnerships' | 'admin'

interface AppShellProps {
  session: AuthSession | null
  activeTab: PartnerTab
  kioskName?: string | null
  kioskLogoUrl?: string | null
  onSelectTab: (tab: PartnerTab) => void
  onSignOut: () => void
  children: ReactNode
}

export function AppShell({
  session,
  activeTab,
  kioskName,
  kioskLogoUrl,
  onSelectTab,
  onSignOut,
  children,
}: AppShellProps) {
  return (
    <div className="app-shell">
      <header className="topbar-wrapper">
        <div className="topbar">
          <a
            className="brand"
            href="#"
            onClick={(e) => {
              e.preventDefault()
              if (session?.role === 'ADMIN') onSelectTab('admin')
              else onSelectTab('identity')
            }}
          >
            <span className="brand-mark" aria-hidden="true">
              🏖️
            </span>
            <span>
              Pé na Areia
              <small>Portal do Parceiro · Quiosques &amp; Restaurantes</small>
            </span>
          </a>

          {session ? (
            <>
              <nav className="nav-tabs" aria-label="Áreas do Portal do Parceiro">
                {(session.role === 'KIOSK_OPERATOR' || session.role === 'CLIENT') && (
                  <>
                    <button
                      type="button"
                      className={activeTab === 'identity' ? 'active' : ''}
                      onClick={() => onSelectTab('identity')}
                    >
                      1. Identidade &amp; Logo
                    </button>
                    <button
                      type="button"
                      className={activeTab === 'address' ? 'active' : ''}
                      onClick={() => onSelectTab('address')}
                    >
                      2. Endereço &amp; Posto
                    </button>
                    <button
                      type="button"
                      className={activeTab === 'menu' ? 'active' : ''}
                      onClick={() => onSelectTab('menu')}
                    >
                      3. Produtos &amp; Categorias
                    </button>
                    <button
                      type="button"
                      className={activeTab === 'partnerships' ? 'active' : ''}
                      onClick={() => onSelectTab('partnerships')}
                    >
                      4. Canais &amp; Repasse
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
                {kioskLogoUrl && (
                  <img
                    src={kioskLogoUrl}
                    alt={kioskName ?? session.name}
                    className="session-avatar"
                  />
                )}
                <div className="user-chip">
                  <strong>{kioskName || session.name}</strong>
                  <span>{session.role === 'ADMIN' ? 'Administrador' : 'Parceiro · Orla de Santos'}</span>
                </div>
                <button type="button" className="ghost" onClick={onSignOut}>
                  Sair
                </button>
              </div>
            </>
          ) : (
            <div className="session-box">
              <span className="badge eco">🌊 Identidade Visual Tropical Atlântico v2.2</span>
            </div>
          )}
        </div>
      </header>

      <main className="partner-main-container">{children}</main>
    </div>
  )
}
