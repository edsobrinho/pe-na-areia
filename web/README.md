# Pé na Areia · Portal Web (React 19 + TypeScript)

Portal web do ecossistema **Pé na Areia**, desenvolvido em **React 19**, **TypeScript** e **Vite 8**. A aplicação atende:
- **Clientes (`CLIENT`)** que realizam pedidos diretamente na faixa de areia da praia de Santos, pagam com **Pix Copia e Cola** e marcam o pin no mapa;
- **Operadores de Quiosques (`KIOSK_OPERATOR`)** que gerenciam o **cardápio completo com upload de fotos (`MenuManager`)** e configuram taxas, horários e ofertas por canal de parceria;
- **Administradores (`ADMIN`)** que gerenciam os canais de venda globais e vinculam operadores aos quiosques.

---

## 📌 Sumário

- [Visão Geral e Funcionalidades](#-visão-geral-e-funcionalidades)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração de Ambiente](#-configuração-de-ambiente)
- [Como Executar e Testar](#-como-executar-e-testar)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Perfis de Acesso](#-perfis-de-acesso)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Integração com o Backend e Cloudinary Docker](#-integração-com-o-backend-e-cloudinary-docker)
- [Resolução de Problemas](#-resolução-de-problemas)

---

## 🎯 Visão Geral e Funcionalidades

### 1. Área do Cliente (`Pedir`)
- **Catálogo Visual por Canal de Parceria:** Escolha do canal de venda ativo, exibição dos quiosques parceiros e cardápio ilustrado com as **fotos reais dos produtos (`fotoUrl`)** e selo de embalagem retornável/sustentável.
- **Carrinho e Validações de Checkout:** Cálculo automático de subtotal e taxa de entrega conforme o pagador configurado no canal (`CLIENT` ou `KIOSK`), validação de pedido mínimo, limite de itens e horário de atendimento.
- **Localização Interativa via Google Maps (`MapPicker`):** Seleção do pin exato na areia com detecção automática do Posto de Salvamento mais próximo (`/reference-points/nearby`), descrição textual validada (até 140 caracteres) e upload de foto do guarda-sol (`/uploads/location-photo`).
- **Card de Pagamento Pix Antecipado ("Zero Dinheiro na Areia"):** Quando o pedido é criado com `PIX`, exibe o payload **Pix Copia e Cola** (`pixCopiaECola`) com botão de cópia rápida, imagem do QR Code Base64, identificador `pixTxId` e botão para gerar/atualizar cobrança (`POST /orders/{id}/pix-charge`).

### 2. Área do Operador (`Meu Quiosque`)
Disponível para usuários com a role `KIOSK_OPERATOR`, dividida em duas seções integradas:
- **Gestão Completa do Cardápio com Fotos (`MenuManager` + `MenuItemFormDialog`):**
  - Listagem de todos os itens do quiosque (`GET /kiosk/me/menu`) com miniatura da foto, preço formatado em BRL, categoria, status de disponibilidade e indicador de embalagem retornável.
  - Criação (`POST /kiosk/me/menu`), edição (`PUT /kiosk/me/menu/{itemId}`) e exclusão (`DELETE /kiosk/me/menu/{itemId}`) de produtos.
  - **Upload de Foto do Produto (`POST /uploads/menu-item-photo`):** Seleção de imagem JPEG, PNG ou WebP (até 5 MB) com preview imediato e armazenamento no Cloudinary (ou container `cloudinary-mock` em Docker).
- **Configuração de Canais de Parceria e Simulador de Repasse:**
  - Parametrização por canal de venda: comissão (`0%–30%`), taxa de entrega e pagador da taxa (`CLIENT` ou `KIOSK`).
  - Configuração de pedido mínimo, limite de itens, janela de abertura/fechamento e tempo estimado de preparo.
  - Ativação/desativação de itens do cardápio no canal e filtros por categoria/embalagem retornável.
  - **Simulador de Repasse:** Cálculo prévio (`POST /kiosk/me/partnerships/{partnershipId}/preview`) de subtotal, comissão da plataforma, total pago pelo cliente e valor líquido do quiosque.

### 3. Área Administrativa (`Administração`)
- Disponível para usuários com a role `ADMIN`.
- Criação e ativação/pausa de canais de parceria globais (`/admin/partnerships`).
- Associação de contas de usuários existentes como operadores responsáveis por quiosques específicos (`PATCH /admin/kiosk-operators`).

---

## 💻 Tecnologias Utilizadas

- **[React 19](https://react.dev/)** — Interfaces reativas e componentes modulares.
- **[TypeScript](https://www.typescriptlang.org/)** — Tipagem estática ponta a ponta.
- **[Vite 8](https://vite.dev/)** — Build e servidor de desenvolvimento com HMR.
- **[@googlemaps/js-api-loader](https://www.npmjs.com/package/@googlemaps/js-api-loader)** — Integração com a Google Maps JavaScript API.
- **[Oxlint](https://oxc.rs/)** — Linter rápido para TypeScript e React.
- **Node Test Runner (`node:test`)** — Suíte de testes unitários para máscaras, validações e regras de formulário.

---

## 📋 Pré-requisitos

- **Node.js**: versão `20.x` LTS ou superior.
- **Backend Pé na Areia + Cloudinary Mock** em execução via Docker Compose (`http://localhost:8080` e `http://localhost:8099`). Consulte o [README principal](../README.md).
- **Chave de API do Google Maps** *(opcional para navegação no catálogo e gestão de cardápio/quiosque; necessária para confirmar o pin no checkout web)*.

---

## ⚙️ Configuração de Ambiente

Na pasta `web`, crie o arquivo `.env.local` a partir de `.env.example`:

```powershell
Set-Location web
if (-not (Test-Path .env.local)) { Copy-Item .env.example .env.local }
```

Conteúdo do `.env.local`:

```env
# URL base da API Spring Boot do Pé na Areia
VITE_API_BASE_URL=http://localhost:8080

# Chave da Google Maps JavaScript API (necessária para marcação do pin de entrega)
VITE_GOOGLE_MAPS_API_KEY=sua_chave_google_maps_aqui
```

---

## 🚀 Como Executar e Testar

No diretório `web`:

```powershell
Set-Location web
npm.cmd install
```

### 1. Executar os testes automatizados (26 testes)
```powershell
npm.cmd test
```

### 2. Subir em modo de desenvolvimento
```powershell
npm.cmd run dev
```
Acesse em: **[http://localhost:5173](http://localhost:5173)**

### 3. Gerar build para produção
```powershell
npm.cmd run build
```

### 4. Análise estática de código (Lint)
```powershell
npm.cmd run lint
```

---

## 🔑 Variáveis de Ambiente

| Variável | Obrigatória | Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `VITE_API_BASE_URL` | Não | `http://localhost:8080` | Endpoint base da API REST do backend. |
| `VITE_GOOGLE_MAPS_API_KEY` | Sim (p/ checkout) | *(vazio)* | Chave de API da Google Cloud com a **Maps JavaScript API** ativada. |

---

## 👤 Perfis de Acesso

O fluxo de autenticação utiliza tokens JWT armazenados em `sessionStorage`:

- **Cliente (`CLIENT`)**: Criado livremente na tela inicial pelo formulário **"Cadastre-se"**.
- **Operador de Quiosque (`KIOSK_OPERATOR`)**: Associado a um quiosque por um Administrador na aba **Administração** (ou via `PATCH /admin/kiosk-operators`). Tem acesso à aba **Meu quiosque** (gerenciamento de cardápio com fotos e configuração de parcerias).
- **Administrador (`ADMIN`)**: Possui acesso à aba **Administração** para criar parcerias e atribuir operadores.

---

## 📂 Estrutura do Projeto

```text
web/
├── public/                        # Arquivos estáticos públicos
├── src/
│   ├── assets/                    # Ilustrações e vetores
│   ├── components/
│   │   ├── MenuItemFormDialog.tsx # Modal de criação/edição de item com upload de foto pro Cloudinary
│   │   └── MenuManager.tsx        # Painel CRUD completo do cardápio do quiosque
│   ├── utils/
│   │   ├── validation.ts          # Funções de validação e máscaras (telefone, moeda, e-mail, etc.)
│   │   └── validation.test.ts     # 26 testes unitários de validação e máscaras
│   ├── api.ts                     # Cliente HTTP REST (auth, catálogo, cardápio, uploads, Pix, admin)
│   ├── App.css                    # Estilização responsiva do portal
│   ├── App.tsx                    # Componente principal (Pedir, Meu Quiosque, Administração)
│   ├── MapPicker.tsx              # Seletor de pin no Google Maps + postos de referência
│   ├── main.tsx                   # Ponto de entrada React
│   └── types.ts                   # Contratos TypeScript (MenuItem, OrderResponse, PixChargeResponse, etc.)
├── .env.example                   # Modelo de variáveis de ambiente
├── package.json                   # Dependências e scripts npm
└── vite.config.ts                 # Configuração do Vite
```

---

## 🌐 Integração com o Backend e Cloudinary Docker

Quando o backend é iniciado via `docker compose -f infrastructure/docker-compose.yml up -d`, os uploads de fotos feitos no `MenuItemFormDialog` (`POST /uploads/menu-item-photo`) e no checkout do cliente (`POST /uploads/location-photo`) são enviados automaticamente para o container `cloudinary-mock` na porta `8099`, retornando URLs públicas acessíveis diretamente pelo navegador (`http://localhost:8099/pe-na-areia-local/image/upload/...`).

---

## 🛠️ Resolução de Problemas

1. **Erro `401` / `403` ou falha de conexão:**
   - Verifique se os containers `backend`, `mongodb` e `cloudinary-mock` estão rodando com `docker compose -f infrastructure/docker-compose.yml ps`.
2. **Fotos de produtos ou do local não aparecem:**
   - Certifique-se de que o container `cloudinary-mock` está ativo na porta `8099` (`http://localhost:8099/health`).
3. **A aba "Meu quiosque" não aparece:**
   - Faça login com um usuário que possua o perfil `KIOSK_OPERATOR` vinculado a um quiosque ativo.
