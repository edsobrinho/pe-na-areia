import type {
  AuthSession,
  CreatedOrder,
  Kiosk,
  MenuItem,
  MenuItemPayload,
  Partnership,
  PartnershipConfiguration,
  PartnershipOffer,
  PricingPreview,
  ReferencePoint,
} from './types'

const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 'http://localhost:8080'
const tokenKey = 'pe-na-areia-session'

export class ApiError extends Error {
  readonly status: number

  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

export function readSession(): AuthSession | null {
  const serialized = sessionStorage.getItem(tokenKey)
  if (!serialized) return null
  try {
    return JSON.parse(serialized) as AuthSession
  } catch {
    sessionStorage.removeItem(tokenKey)
    return null
  }
}

export function storeSession(session: AuthSession): void {
  sessionStorage.setItem(tokenKey, JSON.stringify(session))
}

export function clearSession(): void {
  sessionStorage.removeItem(tokenKey)
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers)
  const token = readSession()?.token
  if (token) headers.set('Authorization', `Bearer ${token}`)
  if (init.body && !(init.body instanceof FormData)) headers.set('Content-Type', 'application/json')

  const response = await fetch(`${baseUrl}${path}`, { ...init, headers })
  if (!response.ok) {
    let message = `Falha na solicitação (${response.status}).`
    try {
      const body = (await response.json()) as { mensagem?: string }
      if (body.mensagem) message = body.mensagem
    } catch {
      // Preserve the HTTP status message if the server response is not JSON.
    }
    throw new ApiError(message, response.status)
  }
  if (response.status === 204) return undefined as T
  return (await response.json()) as T
}

const json = (value: unknown) => JSON.stringify(value)

export const api = {
  login: (email: string, password: string) =>
    request<AuthSession>('/auth/login', { method: 'POST', body: json({ email, password }) }),
  registerClient: (name: string, email: string, phone: string, password: string) =>
    request<AuthSession>('/auth/register', {
      method: 'POST',
      body: json({ name, email, phone, password, role: 'CLIENT' }),
    }),
  listPartnerships: () => request<Partnership[]>('/partnerships'),
  listKiosks: (partnershipId: string) =>
    request<Kiosk[]>(`/kiosks?partnershipId=${encodeURIComponent(partnershipId)}`),
  listAllKiosks: () => request<Kiosk[]>('/kiosks'),
  listKioskOffers: (kioskId: string) =>
    request<PartnershipOffer[]>(`/kiosks/${encodeURIComponent(kioskId)}/partnerships`),
  listOperatorPartnerships: () => request<PartnershipConfiguration[]>('/kiosk/me/partnerships'),
  saveOperatorPartnership: (id: string, configuration: PartnershipConfiguration) =>
    request<PartnershipConfiguration>(`/kiosk/me/partnerships/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: json({
        active: configuration.active,
        commissionPercent: configuration.commissionPercent,
        deliveryFee: configuration.deliveryFee,
        deliveryFeePayer: configuration.deliveryFeePayer,
        minimumOrder: configuration.minimumOrder,
        maxItemsPerOrder: configuration.maxItemsPerOrder,
        acceptFrom: configuration.acceptFrom,
        acceptUntil: configuration.acceptUntil,
        prepMinutes: configuration.prepMinutes,
        filters: configuration.filters,
        productIds: configuration.productIds,
      }),
    }),
  preview: (id: string, items: Array<{ menuItemId: string; quantity: number }>) =>
    request<PricingPreview>(`/kiosk/me/partnerships/${encodeURIComponent(id)}/preview`, {
      method: 'POST',
      body: json({ items }),
    }),
  listReferencePoints: () => request<ReferencePoint[]>('/reference-points'),
  listOperatorMenuItems: () => request<MenuItem[]>('/kiosk/me/menu-items'),
  createMenuItem: (payload: MenuItemPayload) =>
    request<MenuItem>('/kiosk/me/menu-items', { method: 'POST', body: json(payload) }),
  updateMenuItem: (id: string, payload: MenuItemPayload) =>
    request<MenuItem>(`/kiosk/me/menu-items/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: json(payload),
    }),
  deleteMenuItem: (id: string) =>
    request<void>(`/kiosk/me/menu-items/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  setMenuItemAvailability: (id: string, disponivel: boolean) =>
    request<MenuItem>(`/kiosk/me/menu-items/${encodeURIComponent(id)}/availability`, {
      method: 'PATCH',
      body: json({ disponivel }),
    }),
  uploadMenuItemPhoto: async (file: File) => {
    const form = new FormData()
    form.append('file', file)
    return request<{ secureUrl: string }>('/uploads/menu-item-photo', { method: 'POST', body: form })
  },
  uploadLocationPhoto: async (file: File) => {
    const form = new FormData()
    form.append('file', file)
    return request<{ secureUrl: string }>('/uploads/location-photo', { method: 'POST', body: form })
  },
  createOrder: (input: {
    userId: string
    kioskId: string
    partnershipId: string
    itens: Array<{ menuItemId: string; quantidade: number }>
    formaPagamento: 'PIX' | 'CARTAO'
    embalagemSustentavel: boolean
    pinCliente: { latitude: number; longitude: number }
    pontoReferenciaId: string
    descricaoLocal: string
    fotoLocalUrl?: string
  }) => request<CreatedOrder>('/orders', { method: 'POST', body: json(input) }),
  getOrder: (id: string) => request<CreatedOrder>(`/orders/${encodeURIComponent(id)}`),
  createPartnership: (name: string, channel: string) =>
    request<Partnership>('/admin/partnerships', {
      method: 'POST',
      body: json({ name, channel }),
    }),
  assignOperator: (email: string, kioskId: string) =>
    request<{ userId: string; email: string; kioskId: string }>('/admin/kiosk-operators', {
      method: 'PATCH',
      body: json({ email, kioskId }),
    }),
}
