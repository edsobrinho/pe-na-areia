import { useState, type FormEvent } from 'react'
import { api, storeSession } from '../../api'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { InputField } from '../../components/ui/InputField'
import { SelectField } from '../../components/ui/SelectField'
import { WizardStepper, type WizardStepItem } from '../../components/ui/WizardStepper'
import { maskCEP, maskCNPJ, maskPhone, unmask } from '../../utils/masks'
import { isValidEmail, isValidPhoneBR } from '../../utils/validators'
import type { AuthSession, Kiosk, ReferencePoint } from '../../types'

interface PartnerAuthPanelProps {
  referencePoints: ReferencePoint[]
  onAuthenticated: (session: AuthSession, kiosk?: Kiosk) => void
  onError: (message: string) => void
}

type RegisterWizardStep = 'step-account' | 'step-kiosk' | 'step-address'

export function PartnerAuthPanel({
  referencePoints,
  onAuthenticated,
  onError,
}: PartnerAuthPanelProps) {
  const [mode, setMode] = useState<'login' | 'register'>('register')
  const [wizardStep, setWizardStep] = useState<RegisterWizardStep>('step-account')
  const [submitting, setSubmitting] = useState(false)

  // Passo 1 — Conta e Responsável
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')

  // Passo 2 — Identidade do Quiosque / Restaurante
  const [kioskName, setKioskName] = useState('')
  const [cnpj, setCnpj] = useState('')
  const [descricaoCurta, setDescricaoCurta] = useState('')
  const [pontoReferenciaId, setPontoReferenciaId] = useState(
    referencePoints[0]?.id ?? '6acfd917f737c71df923a343',
  )

  // Passo 3 — Endereço Tradicional (Sem Mapa)
  const [cep, setCep] = useState('')
  const [logradouro, setLogradouro] = useState('')
  const [numero, setNumero] = useState('')
  const [complemento, setComplemento] = useState('')
  const [bairro, setBairro] = useState('')
  const [cidade, setCidade] = useState('Santos')
  const [uf, setUf] = useState('SP')

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

  const validateStep1 = (): boolean => {
    const next: Record<string, string> = {}
    if (name.trim().length < 3) {
      next.name = 'Informe o nome completo do responsável.'
    }
    if (!isValidPhoneBR(phone)) {
      next.phone = 'Informe um WhatsApp válido com DDD: (13) 99999-9999.'
    }
    if (!isValidEmail(email)) {
      next.email = 'Informe um e-mail válido (ex.: contato@quiosque.com.br).'
    }
    if (password.trim().length < 6) {
      next.password = 'A senha deve ter pelo menos 6 caracteres.'
    }
    setErrors(next)
    return Object.keys(next).length === 0
  }

  const validateStep2 = (): boolean => {
    const next: Record<string, string> = {}
    if (kioskName.trim().length < 2) {
      next.kioskName = 'Informe o nome fantasia do seu Quiosque ou Restaurante.'
    }
    setErrors(next)
    return Object.keys(next).length === 0
  }

  const validateStep3 = (): boolean => {
    const next: Record<string, string> = {}
    if (logradouro.trim().length < 3) {
      next.logradouro = 'Informe a avenida ou rua do estabelecimento.'
    }
    if (!numero.trim()) {
      next.numero = 'Informe o número ou identificação do quiosque.'
    }
    if (bairro.trim().length < 2) {
      next.bairro = 'Informe o bairro.'
    }
    setErrors(next)
    return Object.keys(next).length === 0
  }

  const validateLogin = (): boolean => {
    const next: Record<string, string> = {}
    if (!isValidEmail(email)) {
      next.email = 'Informe um e-mail válido.'
    }
    if (password.trim().length < 6) {
      next.password = 'A senha deve ter pelo menos 6 caracteres.'
    }
    setErrors(next)
    return Object.keys(next).length === 0
  }

  const handleNextRegisterStep = () => {
    if (wizardStep === 'step-account' && validateStep1()) {
      setWizardStep('step-kiosk')
    } else if (wizardStep === 'step-kiosk' && validateStep2()) {
      setWizardStep('step-address')
    }
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()

    if (mode === 'login') {
      if (!validateLogin()) return
      setSubmitting(true)
      try {
        const session = await api.login(email.trim(), password)
        storeSession(session)
        onAuthenticated(session)
      } catch (reason) {
        onError(reason instanceof Error ? reason.message : 'Falha na autenticação.')
      } finally {
        setSubmitting(false)
      }
      return
    }

    if (wizardStep !== 'step-address') {
      handleNextRegisterStep()
      return
    }

    if (!validateStep1() || !validateStep2() || !validateStep3()) return

    setSubmitting(true)
    try {
      const initialSession = await api.registerUser(
        name.trim(),
        email.trim(),
        unmask(phone),
        password,
      )
      storeSession(initialSession)

      const onboarding = await api.onboardPartner({
        nome: kioskName.trim(),
        cnpj: cnpj.trim() || undefined,
        descricaoCurta: descricaoCurta.trim() || undefined,
        cep: cep.trim() || undefined,
        logradouro: logradouro.trim(),
        numero: numero.trim(),
        complemento: complemento.trim() || undefined,
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
      onError(reason instanceof Error ? reason.message : 'Falha no cadastro do parceiro.')
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

  const registerSteps: WizardStepItem[] = [
    {
      id: 'step-account',
      number: 1,
      icon: '👤',
      title: 'Responsável & Acesso',
      subtitle: 'Nome, WhatsApp e credenciais',
      completed: Boolean(name.trim() && email.trim() && password.length >= 6),
    },
    {
      id: 'step-kiosk',
      number: 2,
      icon: '🏖️',
      title: 'Quiosque / Restaurante',
      subtitle: 'Nome fantasia, CNPJ e Posto da Orla',
      completed: Boolean(kioskName.trim()),
    },
    {
      id: 'step-address',
      number: 3,
      icon: '📍',
      title: 'Endereço Tradicional',
      subtitle: 'CEP, Avenida, Número e Bairro (sem mapa)',
      completed: Boolean(logradouro.trim() && numero.trim() && bairro.trim()),
    },
  ]

  return (
    <div style={{ maxWidth: 880, margin: '1rem auto' }}>
      <SectionCard
        eyebrow="Portal B2B · Identidade Visual Tropical Atlântico"
        title={
          mode === 'register'
            ? 'Wizard de Credenciamento do Parceiro'
            : 'Entrar no Painel do Quiosque / Restaurante'
        }
        description={
          mode === 'register'
            ? 'Complete as 3 etapas rápidas abaixo para cadastrar seu estabelecimento na orla de Santos e liberar o envio da sua logomarca e cardápio.'
            : 'Acesse o painel do seu estabelecimento para gerenciar logomarca, endereço, produtos e parcerias.'
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
              Novo Parceiro (Wizard)
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
        {mode === 'register' && (
          <WizardStepper
            steps={registerSteps}
            activeStepId={wizardStep}
            onSelectStep={(stepId) => {
              if (stepId === 'step-account') setWizardStep('step-account')
              else if (stepId === 'step-kiosk' && validateStep1()) setWizardStep('step-kiosk')
              else if (stepId === 'step-address' && validateStep1() && validateStep2()) {
                setWizardStep('step-address')
              }
            }}
          />
        )}

        <form onSubmit={handleSubmit} className="stack" noValidate>
          {mode === 'login' && (
            <>
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
              <div className="wizard-footer">
                <Button type="submit" variant="primary" fullWidth disabled={submitting}>
                  {submitting ? 'Autenticando...' : 'Entrar no Painel do Parceiro →'}
                </Button>
              </div>
            </>
          )}

          {mode === 'register' && wizardStep === 'step-account' && (
            <div className="wizard-stage-card">
              <div className="wizard-stage-head">
                <span className="eyebrow">Etapa 1 de 3</span>
                <h3>Dados do Responsável e Credenciais de Acesso</h3>
                <p className="muted">
                  Informe quem será o administrador da conta do restaurante ou quiosque.
                </p>
              </div>
              <div className="two-col">
                <InputField
                  label="Nome Completo do Responsável *"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Ex.: Ednilson da Silva Sobrinho"
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
              <div className="two-col">
                <InputField
                  label="E-mail Corporativo *"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="contato@quiosque.com.br"
                  error={errors.email}
                  required
                />
                <InputField
                  label="Senha de Acesso *"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Mínimo de 6 caracteres"
                  error={errors.password}
                  required
                />
              </div>
              <div className="wizard-footer">
                <span className="muted" style={{ fontSize: '0.85rem' }}>
                  Passo 1 de 3 · Próximo: Dados do Quiosque/Restaurante
                </span>
                <Button type="button" variant="primary" onClick={handleNextRegisterStep}>
                  Avançar para Dados do Quiosque →
                </Button>
              </div>
            </div>
          )}

          {mode === 'register' && wizardStep === 'step-kiosk' && (
            <div className="wizard-stage-card">
              <div className="wizard-stage-head">
                <span className="eyebrow">Etapa 2 de 3</span>
                <h3>Identificação do Quiosque / Restaurante e Posto na Orla</h3>
                <p className="muted">
                  Defina como o seu estabelecimento será apresentado para os clientes na praia.
                </p>
              </div>
              <div className="two-col">
                <InputField
                  label="Nome Fantasia do Quiosque ou Restaurante *"
                  value={kioskName}
                  onChange={(e) => setKioskName(e.target.value)}
                  placeholder="Ex.: Quiosque Burgman Posto 5"
                  error={errors.kioskName}
                  required
                />
                <InputField
                  label="CNPJ (Opcional)"
                  value={cnpj}
                  onChange={(e) => setCnpj(maskCNPJ(e.target.value))}
                  placeholder="00.000.000/0001-00"
                />
              </div>

              <SelectField
                label="Posto de Salvamento de Referência na Orla *"
                value={pontoReferenciaId}
                onChange={(e) => setPontoReferenciaId(e.target.value)}
                options={referenceOptions}
                hint="Posiciona automaticamente seu estabelecimento na faixa de areia de Santos sem precisar de mapa."
              />

              <InputField
                label="Especialidade / Descrição Curta da Vitrine (até 160 caracteres)"
                value={descricaoCurta}
                maxLength={160}
                onChange={(e) => setDescricaoCurta(e.target.value)}
                placeholder="Ex.: Chopp artesanal gelado, porções de frutos do mar e entrega no guarda-sol"
              />

              <div className="wizard-footer">
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => setWizardStep('step-account')}
                >
                  ← Voltar para Responsável
                </Button>
                <Button type="button" variant="primary" onClick={handleNextRegisterStep}>
                  Avançar para Endereço Tradicional →
                </Button>
              </div>
            </div>
          )}

          {mode === 'register' && wizardStep === 'step-address' && (
            <div className="wizard-stage-card">
              <div className="wizard-stage-head">
                <span className="eyebrow">Etapa 3 de 3</span>
                <h3>Endereço Tradicional do Estabelecimento (Sem Mapa)</h3>
                <p className="muted">
                  Digite o CEP para preenchimento automático ou informe a rua/avenida e número do seu quiosque/restaurante.
                </p>
              </div>

              <div className="three-col">
                <InputField
                  label="CEP"
                  value={cep}
                  onChange={(e) => {
                    const masked = maskCEP(e.target.value)
                    setCep(masked)
                    if (unmask(masked).length === 8) void handleLookupCep(masked)
                  }}
                  placeholder="11025-031"
                  hint="Autocompleta rua e bairro"
                />
                <InputField
                  label="Logradouro / Avenida *"
                  value={logradouro}
                  onChange={(e) => setLogradouro(e.target.value)}
                  placeholder="Ex.: Av. Bartolomeu de Gusmão"
                  error={errors.logradouro}
                  required
                />
                <InputField
                  label="Número / Nº do Quiosque *"
                  value={numero}
                  onChange={(e) => setNumero(e.target.value)}
                  placeholder="Ex.: Quiosque 42 ou 444"
                  error={errors.numero}
                  required
                />
              </div>

              <div className="three-col">
                <InputField
                  label="Complemento / Ponto Visual"
                  value={complemento}
                  onChange={(e) => setComplemento(e.target.value)}
                  placeholder="Ex.: Calçadão em frente ao Canal 4"
                />
                <InputField
                  label="Bairro *"
                  value={bairro}
                  onChange={(e) => setBairro(e.target.value)}
                  placeholder="Ex.: Embaré"
                  error={errors.bairro}
                  required
                />
                <div className="two-col">
                  <InputField
                    label="Cidade *"
                    value={cidade}
                    onChange={(e) => setCidade(e.target.value)}
                    placeholder="Santos"
                    required
                  />
                  <InputField
                    label="UF *"
                    value={uf}
                    maxLength={2}
                    onChange={(e) => setUf(e.target.value.toUpperCase())}
                    placeholder="SP"
                    required
                  />
                </div>
              </div>

              <div className="wizard-footer">
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => setWizardStep('step-kiosk')}
                >
                  ← Voltar para Quiosque
                </Button>
                <Button type="submit" variant="primary" disabled={submitting}>
                  {submitting
                    ? 'Criando Estabelecimento...'
                    : '🚀 Concluir Cadastro e Enviar Logomarca & Produtos'}
                </Button>
              </div>
            </div>
          )}
        </form>
      </SectionCard>
    </div>
  )
}
