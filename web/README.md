# Pé na Areia · Portal do Parceiro / Quiosque / Restaurante (React 19 + TypeScript + Vite)

Portal web B2B do ecossistema **Pé na Areia**, desenvolvido em **React 19**, **TypeScript** e **Vite 8** com arquitetura de layouts e componentes reutilizáveis. A aplicação é dedicada a:
- **Parceiros, Quiosques e Restaurantes (`KIOSK_OPERATOR`)**: Auto-cadastro do estabelecimento, envio de **logomarca e foto de capa**, cadastro de **endereço tradicional e posto de referência na orla (sem necessidade de mapa)**, gestão de **produtos agrupados nas devidas categorias** com upload de fotos no Cloudinary e configuração de canais de parceria e repasse;
- **Administradores (`ADMIN`)**: Governança global dos canais de venda e vínculo de operadores aos quiosques.

*(Nota: A jornada de pedidos do banhista na areia, mapa interativo e Farol Visual vive exclusivamente no App Mobile Flutter em `frontend/`).*

---

## 📌 Sumário

- [Visão Geral e Funcionalidades](#-visão-geral-e-funcionalidades)
- [Arquitetura de Layouts e Componentes Reutilizáveis](#-arquitetura-de-layouts-e-componentes-reutilizáveis)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração de Ambiente](#-configuração-de-ambiente)
- [Como Executar e Testar](#-como-executar-e-testar)
- [Perfis de Acesso e Fluxo de Onboarding](#-perfis-de-acesso-e-fluxo-de-onboarding)
- [Integração com o Backend e Cloudinary Docker](#-integração-com-o-backend-e-cloudinary-docker)

---

## 🎯 Visão Geral e Funcionalidades

### 1. Auto-Cadastro e Onboarding do Parceiro / Quiosque / Restaurante (`PartnerAuthPanel`)
- **Cadastro Direto como Parceiro (`POST /auth/register` + `POST /kiosk/me/onboarding`)**: O parceiro cria sua conta informando responsável, WhatsApp com máscara `(13) 99999-9999`, nome do Quiosque/Restaurante, endereço tradicional e Posto de Salvamento de referência, sendo promovido automaticamente para `KIOSK_OPERATOR` com seu estabelecimento pronto para operar.
- **1. Identidade Visual & Logomarca (`StorefrontIdentityForm`)**:
  - Upload da **Logomarca Circular (`logoUrl`)** e da **Foto de Capa (`fotoCapaUrl`)** integrados ao Cloudinary (`POST /uploads/menu-item-photo`) com preview imediato.
  - Edição do nome fantasia, CNPJ (`maskCNPJ`), descrição curta da vitrine e switches de **♻️ Embalagem Sustentável** e **⭐ Destaque em "Quiosques Populares na Orla"**.
- **2. Endereço Tradicional e Localização Costeira Sem Mapa (`TraditionalAddressForm`)**:
  - Campos de **CEP** (`00000-000` com preenchimento automático via ViaCEP), **Logradouro / Avenida da Orla**, **Número / Nº do Quiosque**, **Complemento**, **Bairro** e **Cidade/UF** (`Santos/SP`).
  - Seleção do **Posto de Salvamento de Referência** (`Posto 1` ao `Posto 7` via `GET /reference-points`), que vincula automaticamente a coordenada geoespacial (`GeoJsonPoint`) no backend sem exigir Google Maps no navegador.
- **3. Produtos nas Devidas Categorias (`MenuManager` + `CategoryTabs` + `MenuItemFormDialog`)**:
  - Navegação e filtragem rápida por abas de **Categorias Costeiras** (*Água de Coco*, *Porções*, *Frutos do Mar*, *Pastéis*, *Bebidas*, *Cervejas & Drinks*, *Açaí & Gelados*, *Espetinhos*, *Lanches*, *Sobremesas*, *Combos Guarda-Sol*, *Outros*) com contador de itens por categoria.
  - Atalho contextual **`+ Novo em "<Categoria>"`** que já abre o modal pré-selecionado na categoria ativa.
  - Upload de foto do produto, preço em BRL, marcação de **"⭐ Mais Pedido na Areia (`destaque`)"**, **"🌱 Embalagem Retornável"** e chave de disponibilidade imediata.
- **4. Canais de Parceria & Simulador de Repasse (`PartnershipConfigPanel`)**:
  - Parametrização de comissão (`0%–30%`), taxa de entrega na areia, pagador (`CLIENT` ou `KIOSK`), pedido mínimo, tempo estimado de preparo e janela de funcionamento.
  - **Simulador de Repasse (`POST /kiosk/me/partnerships/{id}/preview`)**: Cálculo prévio de subtotal, comissão da plataforma, total do cliente e valor líquido do quiosque.

### 2. Área Administrativa (`AdminPanel`)
- Disponível para usuários com a role `ADMIN`.
- Criação de novos canais de parceria globais (`POST /admin/partnerships`).
- Associação manual de operadores a quiosques existentes (`PATCH /admin/kiosk-operators`).

---

## 🧩 Arquitetura de Layouts e Componentes Reutilizáveis

```text
web/src/
├── components/
│   ├── layout/
│   │   ├── AppShell.tsx                # Layout mestre com Topbar, abas contextuais e sessão
│   │   ├── PageHeader.tsx              # Cabeçalho padronizado de página (eyebrow, título, subtítulo e ações)
│   │   └── SectionCard.tsx             # Card container reutilizável para formulários e seções
│   ├── ui/
│   │   ├── AlertBanner.tsx             # Banner unificado de feedback (erro / sucesso)
│   │   ├── Badge.tsx                   # Pílula de status/indicador reutilizável
│   │   ├── Button.tsx                  # Botão padronizado (primary, secondary, danger, ghost)
│   │   ├── EmptyState.tsx              # Estado vazio com ícone, descrição e call-to-action
│   │   ├── ImageUploadField.tsx        # Upload reutilizável para Cloudinary com preview (circle, banner, square)
│   │   ├── InputField.tsx              # Input acessível com label, dica e mensagem de erro
│   │   └── SelectField.tsx             # Select fortemente tipado com opções, dica e erro
│   ├── MenuItemFormDialog.tsx          # Modal de criação/edição de produto por categoria com foto
│   └── MenuManager.tsx                 # Painel CRUD completo do catálogo filtrado por categoria
├── features/
│   ├── auth/
│   │   └── PartnerAuthPanel.tsx        # Auto-cadastro de Parceiro/Quiosque com endereço tradicional + Login
│   ├── storefront/
│   │   ├── StorefrontIdentityForm.tsx  # Cadastro de Logomarca, Foto de Capa, CNPJ e Vitrine
│   │   └── TraditionalAddressForm.tsx  # Endereço tradicional (CEP, Avenida, Nº, Bairro, Cidade/UF + Posto)
│   ├── menu/
│   │   └── CategoryTabs.tsx            # Abas reutilizáveis das 12 categorias costeiras com contadores
│   ├── partnerships/
│   │   └── PartnershipConfigPanel.tsx  # Configuração de taxas, produtos elegíveis e Simulador de Repasse
│   └── admin/
│       └── AdminPanel.tsx              # Governança global de parcerias e operadores (role ADMIN)
├── utils/
│   ├── masks.ts                        # Máscaras de CEP, CNPJ, CPF, Telefone e Moeda BRL
│   ├── validators.ts                   # Validadores brasileiros
│   └── validators.test.ts              # 26 testes unitários automatizados
├── api.ts                              # Cliente HTTP REST tipado
├── types.ts                            # Contratos TypeScript (Kiosk, PartnerOnboardingPayload, MenuItem, etc.)
└── App.tsx                             # Orquestrador principal do Portal do Parceiro
```

---

## 💻 Tecnologias Utilizadas

- **[React 19](https://react.dev/)** — Interfaces reativas baseadas em componentes reutilizáveis.
- **[TypeScript](https://www.typescriptlang.org/)** — Tipagem estática ponta a ponta.
- **[Vite 8](https://vite.dev/)** — Build otimizado e servidor de desenvolvimento com HMR.
- **Node Test Runner (`node:test`)** — Suíte de 26 testes unitários para máscaras e validadores brasileiros.

---

## ⚙️ Configuração de Ambiente

Na pasta `web`, crie o arquivo `.env.local` a partir de `.env.example` (não há necessidade de chave do Google Maps):

```powershell
Set-Location web
if (-not (Test-Path .env.local)) { Copy-Item .env.example .env.local }
```

Conteúdo do `.env.local`:

```env
# URL base da API Spring Boot do Pé na Areia
VITE_API_BASE_URL=http://localhost:8080
```

---

## 🚀 Como Executar e Testar

No diretório `web`:

```powershell
Set-Location web
npm.cmd install
npm.cmd test
npm.cmd run build
npm.cmd run dev
```

Acesse em: **[http://localhost:5173](http://localhost:5173)**
