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
  fotoUrl?: string | null
  destaque?: boolean
}

export interface MenuItemPayload {
  nome: string
  descricao?: string
  preco: number
  disponivel?: boolean
  category?: string
  returnablePackaging?: boolean
  fotoUrl?: string | null
  destaque?: boolean
}

export interface KioskStorefrontPayload {
  nome?: string
  descricaoCurta?: string
  fotoCapaUrl?: string | null
  logoUrl?: string | null
  aceitaEmbalagemSustentavel?: boolean
  destaquePopular?: boolean
  cnpj?: string | null
  cep?: string | null
  logradouro?: string | null
  numero?: string | null
  complemento?: string | null
  bairro?: string | null
  cidade?: string | null
  uf?: string | null
  pontoReferenciaId?: string | null
}

export interface PartnerOnboardingPayload extends KioskStorefrontPayload {
  nome: string
}

export interface PartnerOnboardingResponse {
  token: string
  userId: string
  name: string
  role: Role
  kiosk: Kiosk
}

export interface Kiosk {
  id: string
  nome: string
  pontoReferenciaId?: string
  ativo: boolean
  aceitaEmbalagemSustentavel: boolean
  fotoCapaUrl?: string | null
  logoUrl?: string | null
  descricaoCurta?: string | null
  avaliacaoMedia?: number
  destaquePopular?: boolean
  cnpj?: string | null
  cep?: string | null
  logradouro?: string | null
  numero?: string | null
  complemento?: string | null
  bairro?: string | null
  cidade?: string | null
  uf?: string | null
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

export type OrderStatus =
  | 'CRIADO'
  | 'PAGO'
  | 'EM_PREPARO'
  | 'A_CAMINHO'
  | 'CHEGOU_NO_LOCAL'
  | 'ENTREGUE'
  | 'CANCELADO'
  | 'NAO_ENCONTRADO'

export interface KioskOrderItem {
  menuItemId: string
  nome: string
  quantidade: number
  precoUnitario: number
  category?: string
  returnablePackaging?: boolean
}

export interface KioskOrder {
  id: string
  userId: string
  kioskId: string
  status: OrderStatus
  pago: boolean
  formaPagamento: string
  valorTotal: number
  itens: KioskOrderItem[]
  pinCliente?: {
    type: 'Point'
    coordinates: [number, number]
  }
  pontoReferenciaId?: string
  descricaoLocal?: string
  fotoLocalUrl?: string | null
  referenciaBarraca?: string
  complementoLocal?: string
  fotoVisaoPostoUrl?: string | null
  fotoOutroReferencialUrl?: string | null
  contatoNome?: string
  contatoTelefone?: string
  etiquetaLocal?: string
  courierId?: string | null
  courierNome?: string | null
  courierTelefone?: string | null
  courierVeiculo?: 'A_PE' | 'BICICLETA' | null
  motivoCancelamento?: string | null
  timeline: {
    criadoEm: string
    pagoEm?: string
    emPreparoEm?: string
    aCaminhoEm?: string
    chegouNoLocalEm?: string
    entregueEm?: string
    canceladoEm?: string
    naoEncontradoEm?: string
  }
}

