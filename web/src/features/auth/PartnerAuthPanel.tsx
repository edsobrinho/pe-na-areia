import { useState, type FormEvent } from 'react'
import { api, storeSession } from '../../api'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { InputField } from '../../components/ui/InputField'
import { SelectField } from '../../components/ui/SelectField'
import { maskCEP, maskPhone, unmask } from '../../utils/masks'
import { isValidEmail, isValidPhoneBR } from '../../utils/validators'
import type { AuthSession, Kiosk, ReferencePoint } from '../../types'

interface PartnerAuthPanelProps {
  referencePoints: ReferencePoint[]
  onAuthenticated: (session: AuthSession, kiosk?: Kiosk) => void
  onError: (message: string) => void
}

export function PartnerAuthPanel({
  referencePoints,
  onAuthenticated,
  onError,
}: PartnerAuthPanelProps) {
  const [mode, setMode] = useState<'login' | 'register'>('register')
  const [submitting, setSubmitting] = useState(false)

  // Campos de usuário
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')

  // Campos iniciais do Quiosque/Restaurante no Auto-Cadastro
  const [kioskName, setKioskName] = useState('')
  const [descricaoCurta, setDescricaoCurta] = useState('')
  const [cep, setCep] = useState('')
  const [logradouro, setLogradouro] = useState('')
  const [numero, setNumero] = useState('')
  const [bairro, setBairro] = useState('')
  const [cidade, setCidade] = useState('Santos')
  const [uf, setUf] = useState('SP')
  const [pontoReferenciaId, setPontoReferenciaId] = useState(
    referencePoints[0]?.id ?? '6acfd917f737c71df923a343',
  )

  const [errors, setErrors] = useState<Record<string, string>>({})

  const handleLookupCep = async (rawCep: string) => {
    const digits = unmask(rawCep)
    if (digits.length !== 8) return
    try {
      const res = await fetch(`https://viacep.com.br/ws/${digits}/json/`)
      if (!res.ok) return
      const data = (await res.json()) as {
        erro?: boolean
        logradouro?: string
        bairro?: string
        localidade?: string
        uf?: string
      }
      if (!data.erro) {
        if (data.logradouro) setLogradouro(data.logradouro)
        if (data.bairro) setBairro(data.bairro)
        if (data.localidade) setCidade(data.localidade)
        if (data.uf) setUf(data.uf)
      }
    } catch {
      // Ignora caso offline; o parceiro preenche manualmente.
    }
  }

  const validate = (): boolean => {
    const next: Record<string, string> = {}
    if (!isValidEmail(email)) {
      next.email = 'Informe um e-mail válido (ex.: contato@quiosque.com.br).'
    }
    if (password.trim().length < 6) {
      next.password = 'A senha deve ter pelo menos 6 caracteres.'
    }
    if (mode === 'register') {
      if (name.trim().length < 3) {
        next.name = 'Informe o nome completo do responsável.'
      }
      if (!isValidPhoneBR(phone)) {
        next.phone = 'Informe um telefone/WhatsApp válido com DDD: (13) 99999-9999.'
      }
      if (kioskName.trim().length < 2) {
        next.kioskName = 'Informe o nome fantasia do seu Quiosque ou Restaurante.'
      }
      if (logradouro.trim().length < 3) {
        next.logradouro = 'Informe a avenida/rua do estabelecimento.'
      }
      if (!numero.trim()) {
        next.numero = 'Informe o número ou identificação do quiosque.'
      }
      if (bairro.trim().length < 2) {
        next.bairro = 'Informe o bairro.'
      }
    }
    setErrors(next)
    return Object.keys(next).length === 0
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    if (!validate()) return
    setSubmitting(true)
    try {
      if (mode === 'login') {
        const session = await api.login(email.trim(), password)
        storeSession(session)
        onAuthenticated(session)
        return
      }

      // 1. Cria a conta de acesso
      const initialSession = await api.registerUser(
        name.trim(),
        email.trim(),
        unmask(phone),
        password,
      )
      storeSession(initialSession)

      // 2. Cria/vincula imediatamente o Quiosque/Restaurante com endereço tradicional (sem mapa)
      const onboarding = await api.onboardPartner({
        nome: kioskName.trim(),
        descricaoCurta: descricaoCurta.trim() || undefined,
        cep: cep.trim() || undefined,
        logradouro: logradouro.trim(),
        numero: numero.trim(),
        bairro: bairro.trim(),
        cidade: cidade.trim() || 'Santos',
        uf: uf.trim().toUpperCase() || 'SP',
        pontoReferenciaId: pontoReferenciaId || referencePoints[0]?.id,
        aceitaEmbalagemSustentavel: true,
        destaquePopular: true,
      })

      const partnerSession: AuthSession = {
        token: onboarding.token || initialSession.token,
        userId: onboarding.userId,
        name: onboarding.name,
        role: onboarding.role,
      }
      storeSession(partnerSession)
      onAuthenticated(partnerSession, onboarding.kiosk)
    } catch (reason) {
      onError(reason instanceof Error ? reason.message : 'Falha na autenticação do parceiro.')
    } finally {
      setSubmitting(false)
    }
  }

  const referenceOptions =
    referencePoints.length > 0
      ? referencePoints.map((rp) => ({
          value: rp.id,
          label: `Posto ${rp.numero} · ${rp.nome} (${rp.trecho})`,
        }))
      : [{ value: '6acfd917f737c71df923a343', label: 'Posto 5 · Boqueirão (Santos/SP)' }]

  return (
    <div style={{ maxWidth: 820, margin: '1.5rem auto' }}>
      <SectionCard
        eyebrow="Portal B2B · Quiosques e Restaurantes da Orla"
        title={
          mode === 'register'
            ? 'Cadastre seu Quiosque ou Restaurante Parceiro'
            : 'Acesse o Painel do seu Estabelecimento'
        }
        description={
          mode === 'register'
            ? 'Cadastre sua conta, informe o endereço tradicional do seu estabelecimento (sem necessidade de mapa) e já envie sua logomarca e produtos por categoria.'
            : 'Entre com suas credenciais de Parceiro (KIOSK_OPERATOR) ou Administrador (ADMIN).'
        }
        headerAction={
          <div className="segmented">
            <button
              type="button"
              className={mode === 'register' ? 'active' : ''}
              onClick={() => {
                setMode('register')
                setErrors({})
              }}
            >
              Cadastrar Parceiro
            </button>
            <button
              type="button"
              className={mode === 'login' ? 'active' : ''}
              onClick={() => {
                setMode('login')
                setErrors({})
              }}
            >
              Já sou Parceiro (Entrar)
            </button>
          </div>
        }
      >
        <form onSubmit={handleSubmit} className="stack" noValidate>
          {mode === 'register' && (
            <>
              <div className="two-col">
                <InputField
                  label="Nome do Responsável *"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Ex.: Roberto Almeida"
                  error={errors.name}
                  required
                />
                <InputField
                  label="Telefone / WhatsApp Comercial *"
                  type="tel"
                  inputMode="numeric"
                  value={phone}
                  onChange={(e) => setPhone(maskPhone(e.target.value))}
                  placeholder="(13) 99999-9999"
                  error={errors.phone}
                  required
                />
              </div>
            </>
          )}

          <div className="two-col">
            <InputField
              label="E-mail de Acesso *"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="parceiro@quiosque.com.br"
              error={errors.email}
              required
            />
            <InputField
              label="Senha *"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Mínimo de 6 caracteres"
              error={errors.password}
              required
            />
          </div>

          {mode === 'register' && (
            <>
              <hr style={{ border: 'none', borderTop: '1px solid #e2e8f0', margin: '0.5rem 0' }} />
              <p className="eyebrow" style={{ margin: 0 }}>
                Dados do Quiosque / Restaurante &amp; Endereço Tradicional (Sem Mapa)
              </p>

              <div className="two-col">
                <InputField
                  label="Nome do Quiosque ou Restaurante *"
                  value={kioskName}
                  onChange={(e) => setKioskName(e.target.value)}
                  placeholder="Ex.: Quiosque Sol do Boqueirão"
                  error={errors.kioskName}
                  required
                />
                <SelectField
                  label="Posto de Salvamento de Referência na Orla *"
                  value={pontoReferenciaId}
                  onChange={(e) => setPontoReferenciaId(e.target.value)}
                  options={referenceOptions}
                  hint="Vincula automaticamente a localização costeira sem precisar marcar no mapa."
                />
              </div>

              <InputField
                label="Especialidade / Descrição Curta da Vitrine"
                value={descricaoCurta}
                onChange={(e) => setDescricaoCurta(e.target.value)}
                maxLength={160}
                placeholder="Ex.: Porções de frutos do mar, pastéis artesanais e água de coco trincando"
              />

              <div className="three-col">
                <InputField
                  label="CEP"
                  value={cep}
                  onChange={(e) => {
                    const masked = maskCEP(e.target.value)
                    setCep(masked)
                    if (unmask(masked).length === 8) void handleLookupCep(masked)
                  }}
                  placeholder="11045-500"
                  hint="Preenche rua e bairro automaticamente"
                />
                <InputField
                  label="Logradouro / Avenida *"
                  value={logradouro}
                  onChange={(e) => setLogradouro(e.target.value)}
                  placeholder="Ex.: Av. Vicente de Carvalho"
                  error={errors.logradouro}
                  required
                />
                <InputField
                  label="Número / Nº do Quiosque *"
                  value={numero}
                  onChange={(e) => setNumero(e.target.value)}
                  placeholder="Ex.: Quiosque 42"
                  error={errors.numero}
                  required
                />
              </div>

              <div className="three-col">
                <InputField
                  label="Bairro *"
                  value={bairro}
                  onChange={(e) => setBairro(e.target.value)}
                  placeholder="Ex.: Boqueirão"
                  error={errors.bairro}
                  required
                />
                <InputField
                  label="Cidade"
                  value={cidade}
                  onChange={(e) => setCidade(e.target.value)}
                  placeholder="Santos"
                />
                <InputField
                  label="UF"
                  value={uf}
                  maxLength={2}
                  onChange={(e) => setUf(e.target.value.toUpperCase())}
                  placeholder="SP"
                />
              </div>
            </>
          )}

          <div style={{ marginTop: '0.5rem' }}>
            <Button type="submit" variant="primary" fullWidth disabled={submitting}>
              {submitting
                ? 'Processando...'
                : mode === 'register'
                  ? '🚀 Concluir Cadastro e Configurar Logomarca & Cardápio'
                  : 'Entrar no Painel do Parceiro'}
            </Button>
          </div>
        </form>
      </SectionCard>
    </div>
  )
}

