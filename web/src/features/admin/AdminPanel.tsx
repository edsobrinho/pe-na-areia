import { useEffect, useState } from 'react'
import { api } from '../../api'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { InputField } from '../../components/ui/InputField'
import { SelectField } from '../../components/ui/SelectField'
import type { Kiosk, Partnership } from '../../types'

interface AdminPanelProps {
  partnerships: Partnership[]
  onPartnershipCreated: (partnership: Partnership) => void
  onSuccess: (message: string) => void
  onError: (message: string) => void
}

export function AdminPanel({
  partnerships,
  onPartnershipCreated,
  onSuccess,
  onError,
}: AdminPanelProps) {
  const [name, setName] = useState('')
  const [channel, setChannel] = useState('PARCEIRO')
  const [email, setEmail] = useState('')
  const [kiosks, setKiosks] = useState<Kiosk[]>([])
  const [kioskId, setKioskId] = useState('')

  useEffect(() => {
    void api
      .listAllKiosks()
      .then((items) => {
        setKiosks(items)
        setKioskId(items[0]?.id ?? '')
      })
      .catch((reason: unknown) =>
        onError(reason instanceof Error ? reason.message : 'Falha ao listar quiosques.'),
      )
  }, [onError])

  return (
    <div className="two-col">
      <SectionCard
        eyebrow="Administração Global"
        title="Novo Canal de Parceria"
        description="Crie canais de venda globais para os quiosques e restaurantes parceiros."
      >
        <form
          className="stack"
          onSubmit={async (event) => {
            event.preventDefault()
            try {
              const created = await api.createPartnership(name, channel)
              onPartnershipCreated(created)
              setName('')
              onSuccess(`Parceria "${created.name}" criada com sucesso.`)
            } catch (reason) {
              onError(reason instanceof Error ? reason.message : 'Falha ao criar parceria.')
            }
          }}
        >
          <InputField
            label="Nome da Parceria *"
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="Ex.: Parceria Hotéis da Orla"
            required
          />
          <SelectField
            label="Canal"
            value={channel}
            onChange={(event) => setChannel(event.target.value)}
            options={[
              { value: 'PARCEIRO', label: 'Parceiro Externo' },
              { value: 'HOTEL', label: 'Hotel / Turismo' },
              { value: 'EVENTO', label: 'Evento Esportivo' },
              { value: 'APP', label: 'Aplicativo Próprio' },
            ]}
          />
          <Button type="submit" variant="primary">
            Criar Parceria
          </Button>
        </form>

        <ul className="simple-list">
          {partnerships.map((item) => (
            <li key={item.id}>
              <strong>{item.name}</strong>
              <span>{item.channel}</span>
            </li>
          ))}
        </ul>
      </SectionCard>

      <SectionCard
        eyebrow="Operadores"
        title="Associar Operador a Quiosque Existente"
        description="Vincule manualmente uma conta de usuário existente a um quiosque da rede."
      >
        <form
          className="stack"
          onSubmit={async (event) => {
            event.preventDefault()
            try {
              const assigned = await api.assignOperator(email, kioskId)
              onSuccess(`Operador ${assigned.email} vinculado ao quiosque ${assigned.kioskId}.`)
              setEmail('')
            } catch (reason) {
              onError(reason instanceof Error ? reason.message : 'Falha ao associar operador.')
            }
          }}
        >
          <InputField
            label="E-mail do Usuário *"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="operador@quiosque.com.br"
            required
          />
          <SelectField
            label="Quiosque / Restaurante"
            value={kioskId}
            onChange={(event) => setKioskId(event.target.value)}
            options={kiosks.map((kiosk) => ({
              value: kiosk.id,
              label: `${kiosk.nome} (${kiosk.id})`,
            }))}
          />
          <Button type="submit" variant="primary">
            Vincular Operador
          </Button>
        </form>
      </SectionCard>
    </div>
  )
}

