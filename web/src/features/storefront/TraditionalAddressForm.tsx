import { useState, type FormEvent } from 'react'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { InputField } from '../../components/ui/InputField'
import { SelectField } from '../../components/ui/SelectField'
import { maskCEP, unmask } from '../../utils/masks'
import type { Kiosk, KioskStorefrontPayload, ReferencePoint } from '../../types'

interface TraditionalAddressFormProps {
  kiosk: Kiosk
  referencePoints: ReferencePoint[]
  onBack: () => void
  onSave: (payload: KioskStorefrontPayload, advanceToNextStep?: boolean) => Promise<void>
}

export function TraditionalAddressForm({
  kiosk,
  referencePoints,
  onBack,
  onSave,
}: TraditionalAddressFormProps) {
  const [cep, setCep] = useState(kiosk.cep ?? '')
  const [logradouro, setLogradouro] = useState(kiosk.logradouro ?? '')
  const [numero, setNumero] = useState(kiosk.numero ?? '')
  const [complemento, setComplemento] = useState(kiosk.complemento ?? '')
  const [bairro, setBairro] = useState(kiosk.bairro ?? '')
  const [cidade, setCidade] = useState(kiosk.cidade ?? 'Santos')
  const [uf, setUf] = useState(kiosk.uf ?? 'SP')
  const [pontoReferenciaId, setPontoReferenciaId] = useState(
    kiosk.pontoReferenciaId ?? referencePoints[0]?.id ?? '6acfd917f737c71df923a343',
  )
  const [saving, setSaving] = useState(false)
  const [lookingUpCep, setLookingUpCep] = useState(false)

  const handleLookupCep = async (rawCep: string) => {
    const digits = unmask(rawCep)
    if (digits.length !== 8) return
    setLookingUpCep(true)
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
      // Silencioso caso sem internet externa
    } finally {
      setLookingUpCep(false)
    }
  }

  const submitForm = async (advanceToNextStep: boolean) => {
    setSaving(true)
    try {
      await onSave(
        {
          cep: cep.trim() || null,
          logradouro: logradouro.trim() || null,
          numero: numero.trim() || null,
          complemento: complemento.trim() || null,
          bairro: bairro.trim() || null,
          cidade: cidade.trim() || 'Santos',
          uf: uf.trim().toUpperCase() || 'SP',
          pontoReferenciaId: pontoReferenciaId || null,
        },
        advanceToNextStep,
      )
    } finally {
      setSaving(false)
    }
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    await submitForm(false)
  }

  const referenceOptions =
    referencePoints.length > 0
      ? referencePoints.map((rp) => ({
          value: rp.id,
          label: `Posto ${rp.numero} · ${rp.nome} (${rp.trecho})`,
        }))
      : [{ value: '6acfd917f737c71df923a343', label: 'Posto 5 · Boqueirão (Santos/SP)' }]

  return (
    <SectionCard
      eyebrow="Etapa 2 de 4 · Endereço Tradicional & Localização Costeira (Sem Mapa)"
      title="Endereço do Estabelecimento e Posto de Referência"
      description="Informe o endereço tradicional do seu restaurante ou quiosque e escolha o Posto de Salvamento mais próximo. O sistema calcula o posicionamento na orla automaticamente sem precisar de mapa."
    >
      <form onSubmit={handleSubmit} className="stack">
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
            hint={lookingUpCep ? 'Consultando CEP...' : 'Digite 8 dígitos para autocompletar'}
          />
          <InputField
            label="Logradouro / Avenida da Orla *"
            value={logradouro}
            onChange={(e) => setLogradouro(e.target.value)}
            placeholder="Ex.: Rua Liberdade"
            required
          />
          <InputField
            label="Número / Nº do Quiosque *"
            value={numero}
            onChange={(e) => setNumero(e.target.value)}
            placeholder="Ex.: 444 ou Quiosque 42"
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

        <SelectField
          label="Posto de Salvamento de Referência na Praia *"
          value={pontoReferenciaId}
          onChange={(e) => setPontoReferenciaId(e.target.value)}
          options={referenceOptions}
          hint="Define automaticamente a região de atendimento na faixa de areia (até 500m do Posto selecionado)."
        />

        <div className="wizard-footer">
          <Button type="button" variant="ghost" onClick={onBack} disabled={saving}>
            ← Etapa 1: Logomarca &amp; Vitrine
          </Button>
          <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
            <Button type="submit" variant="secondary" disabled={saving}>
              {saving ? 'Salvando...' : '📍 Salvar Endereço'}
            </Button>
            <Button
              type="button"
              variant="primary"
              disabled={saving}
              onClick={() => void submitForm(true)}
            >
              {saving ? 'Salvando...' : 'Salvar e Avançar para Produtos (Etapa 3) →'}
            </Button>
          </div>
        </div>
      </form>
    </SectionCard>
  )
}
