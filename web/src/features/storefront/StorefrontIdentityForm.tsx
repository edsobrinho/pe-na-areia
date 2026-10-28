import { useState, type FormEvent } from 'react'
import { SectionCard } from '../../components/layout/SectionCard'
import { Button } from '../../components/ui/Button'
import { ImageUploadField } from '../../components/ui/ImageUploadField'
import { InputField } from '../../components/ui/InputField'
import { maskCNPJ } from '../../utils/masks'
import type { Kiosk, KioskStorefrontPayload } from '../../types'

interface StorefrontIdentityFormProps {
  kiosk: Kiosk
  onSave: (payload: KioskStorefrontPayload) => Promise<void>
}

export function StorefrontIdentityForm({ kiosk, onSave }: StorefrontIdentityFormProps) {
  const [nome, setNome] = useState(kiosk.nome ?? '')
  const [cnpj, setCnpj] = useState(kiosk.cnpj ?? '')
  const [descricaoCurta, setDescricaoCurta] = useState(kiosk.descricaoCurta ?? '')
  const [logoUrl, setLogoUrl] = useState(kiosk.logoUrl ?? '')
  const [fotoCapaUrl, setFotoCapaUrl] = useState(kiosk.fotoCapaUrl ?? '')
  const [aceitaEmbalagemSustentavel, setAceitaEmbalagemSustentavel] = useState(
    kiosk.aceitaEmbalagemSustentavel ?? true,
  )
  const [destaquePopular, setDestaquePopular] = useState(kiosk.destaquePopular ?? true)
  const [saving, setSaving] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    try {
      await onSave({
        nome: nome.trim() || kiosk.nome,
        cnpj: cnpj.trim() || null,
        descricaoCurta: descricaoCurta.trim(),
        logoUrl: logoUrl.trim() || null,
        fotoCapaUrl: fotoCapaUrl.trim() || null,
        aceitaEmbalagemSustentavel,
        destaquePopular,
      })
    } finally {
      setSaving(false)
    }
  }

  return (
    <SectionCard
      eyebrow="1. Identidade Visual & Logomarca"
      title="Logomarca, Capa e Vitrine do Estabelecimento"
      description="Envie a logomarca oficial e a foto de capa do seu quiosque ou restaurante. Elas aparecem imediatamente na vitrine do App do Cliente."
    >
      <form onSubmit={handleSubmit} className="stack">
        <div className="two-col">
          <InputField
            label="Nome do Quiosque / Restaurante *"
            value={nome}
            onChange={(e) => setNome(e.target.value)}
            placeholder="Ex.: Quiosque Pé na Areia"
            required
          />
          <InputField
            label="CNPJ (Opcional)"
            value={cnpj}
            onChange={(e) => setCnpj(maskCNPJ(e.target.value))}
            placeholder="00.000.000/0001-00"
          />
        </div>

        <InputField
          label="Descrição Curta da Vitrine (até 160 caracteres)"
          value={descricaoCurta}
          maxLength={160}
          onChange={(e) => setDescricaoCurta(e.target.value)}
          placeholder="Ex.: Porções de frutos do mar, água de coco gelada e entrega rápida no guarda-sol"
        />

        <div className="two-col" style={{ alignItems: 'flex-start' }}>
          <ImageUploadField
            label="Logomarca do Restaurante / Quiosque (Logo Circular)"
            value={logoUrl}
            onChange={setLogoUrl}
            shape="circle"
            helperText="JPG, PNG ou WebP até 5 MB (armazenado no Cloudinary)"
          />
          <ImageUploadField
            label="Foto de Capa da Vitrine (Proporção 16:9)"
            value={fotoCapaUrl}
            onChange={setFotoCapaUrl}
            shape="banner"
            helperText="Destaca a fachada ou prato principal na lista da orla"
          />
        </div>

        <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
          <label className="check" style={{ margin: 0 }}>
            <input
              type="checkbox"
              checked={aceitaEmbalagemSustentavel}
              onChange={(e) => setAceitaEmbalagemSustentavel(e.target.checked)}
            />
            <span>♻️ Trabalha com Embalagem Sustentável / Retornável</span>
          </label>
          <label className="check" style={{ margin: 0 }}>
            <input
              type="checkbox"
              checked={destaquePopular}
              onChange={(e) => setDestaquePopular(e.target.checked)}
            />
            <span>⭐ Exibir na vitrine "Quiosques Populares na Orla"</span>
          </label>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <Button type="submit" variant="primary" disabled={saving}>
            {saving ? 'Salvando Identidade...' : '💾 Salvar Logomarca e Vitrine'}
          </Button>
        </div>
      </form>
    </SectionCard>
  )
}

