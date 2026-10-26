export type Role = 'CLIENT' | 'COURIER' | 'KIOSK_OPERATOR' | 'ADMIN'

export interface AuthSession {
  token: string
  userId: string
  name: string
  role: Role
}

export interface Partnership {
  id: string
  name: string
  channel: string
  active: boolean
}

export interface MenuItem {
  id: string
  nome: string
  descricao: string
  preco: number
  disponivel: boolean
  category: string
  returnablePackaging: boolean
}

export interface Kiosk {
  id: string
  nome: string
  ativo: boolean
  aceitaEmbalagemSustentavel: boolean
  cardapio: MenuItem[]
}

export interface PartnershipConfiguration {
  partnershipId: string
  name: string
  channel: string
  configured: boolean
  active: boolean
  commissionPercent: number
  deliveryFee: number
  deliveryFeePayer: 'CLIENT' | 'KIOSK'
  minimumOrder: number
  maxItemsPerOrder: number
  acceptFrom: string
  acceptUntil: string
  prepMinutes: number
  filters: {
    categories: string[]
    onlyReturnable: boolean
  }
  productIds: string[]
  products: MenuItem[]
}

export interface PartnershipOffer {
  partnershipId: string
  name: string
  channel: string
  active: boolean
  commissionPercent: number
  deliveryFee: number
  deliveryFeePayer: 'CLIENT' | 'KIOSK'
  minimumOrder: number
  maxItemsPerOrder: number
  acceptFrom: string
  acceptUntil: string
  prepMinutes: number
  products: MenuItem[]
}

export interface ReferencePoint {
  id: string
  numero: number
  nome: string
  trecho: string
  localizacao: {
    type: 'Point'
    coordinates: [number, number]
  }
}

export interface PricingPreview {
  subtotal: number
  commissionPercent: number
  commissionAmount: number
  deliveryFee: number
  deliveryFeePayer: 'CLIENT' | 'KIOSK'
  customerTotal: number
  kioskNet: number
  note: string
}

export interface CreatedOrder {
  id: string
  valorTotal: number
  status: string
  partnershipId: string
}

export interface BeachLocation {
  latitude: number
  longitude: number
  pontoReferenciaId: string
  descricaoLocal: string
  fotoLocalUrl?: string
}
