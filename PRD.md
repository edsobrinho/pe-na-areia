# PRD — Pé na Areia · Plataforma Completa de Pedidos e Logística Costeira 🏖️

**Versão Consolidada:** 2.1 (Unificação Oficial do PRD Principal v2.0 e PRD v1.1 de Parcerias e Cardápio)  
**Data:** 02 de novembro de 2026  
**Status do Ecossistema:** Arquitetura Multi-App Monorepo Implementada e Validada End-to-End (Backend Spring Boot 3.3 + 3 Apps Flutter + Portal Web React 19 + Docker)

---

## 📌 Sumário Executivo

- [1. Resumo do Produto e Proposta de Valor](#1-resumo-do-produto-e-proposta-de-valor)
- [2. O Problema da Entrega na Faixa de Areia e a Solução](#2-o-problema-da-entrega-na-faixa-de-areia-e-a-solução)
- [3. Perfis de Usuário (Personas & Roles)](#3-perfis-de-usuário-personas--roles)
- [4. Arquitetura do Ecossistema (Monorepo Multi-App)](#4-arquitetura-do-ecossistema-monorepo-multi-app)
- [5. Modelo de Domínio e Esquemas Geoespaciais (MongoDB)](#5-modelo-de-domínio-e-esquemas-geoespaciais-mongodb)
- [6. Requisitos Funcionais Detalhados (RF-01 a RF-18)](#6-requisitos-funcionais-detalhados-rf-01-a-rf-18)
- [7. Regras de Negócio Validadas no Servidor (RN-01 a RN-12)](#7-regras-de-negócio-validadas-no-servidor-rn-01-a-rn-12)
- [8. Especificação das Interfaces e Experiências do Usuário](#8-especificação-das-interfaces-e-experiências-do-usuário)
  - [8.1 App do Cliente (Jornada das 6 Telas Costeiras)](#81-app-do-cliente-jornada-das-6-telas-costeiras)
  - [8.2 App do Entregador (Radar Pedestre, Bússola e Telemetria)](#82-app-do-entregador-radar-pedestre-bússola-e-telemetria)
  - [8.3 Portal Web B2B (Onboarding, Vitrine, Cardápio e Gestão de Pedidos)](#83-portal-web-b2b-onboarding-vitrine-cardápio-e-gestão-de-pedidos)
  - [8.4 Protótipo Interativo & Showcase Multiplataforma](#84-protótipo-interativo--showcase-multiplataforma)
- [9. Catálogo Completo de Endpoints REST e Webhooks](#9-catálogo-completo-de-endpoints-rest-e-webhooks)
- [10. Matriz de Rastreabilidade e Status de Implementação](#10-matriz-de-rastreabilidade-e-status-de-implementação)
- [11. Próximos Passos de Evolução (Roadmap Futuro)](#11-próximos-passos-de-evolução-roadmap-futuro)

---

## 1. Resumo do Produto e Proposta de Valor

**Pé na Areia** é uma plataforma full-stack de pedidos e logística de última milha projetada sob medida para a faixa de areia de praias urbanas, operando inicialmente na orla da praia de Santos/SP (Postos 1 ao 6).

O cliente escolhe produtos com fotos reais de quiosques e restaurantes parceiros com suporte a **embalagens sustentáveis/retornáveis**, paga antecipadamente via **Pix Copia e Cola / QR Code**, marca o **pin exato do seu guarda-sol no mapa** e aciona o **Farol Visual de Tela Cheia** quando o entregador se aproxima. O entregador caminha pela areia guiado pelo **Modo Bússola / Radar Pedestre**, transmitindo telemetria contínua até a validação da entrega por **Geofencing de 60 metros**. Os donos de quiosques gerenciam seu cardápio, fotos, vitrines e canais de parceria em um portal web dedicado.

---

## 2. O Problema da Entrega na Faixa de Areia e a Solução

| Desafio Crítico na Areia | Por que Apps Tradicionais Falham | Solução Exclusiva Pé na Areia |
| :--- | :--- | :--- |
| **Ausência de ruas e CEPs** | Motores veiculares (Google Directions) traçam rotas só até o calçadão. Ao pisar na areia, o entregador fica sem rumo. | **Modo Bússola / Radar Pedestre (`BeachCompass`):** Computa distância direta em metros (Haversine), azimute e direção cardeal em português (*"A 45 m a Sudeste (135°) do Posto 4"*). |
| **Multidão de guarda-sóis idênticos** | O GPS civil tem margem de erro de 10 a 15 metros, gerando confusão entre barracas vizinhas. | **Farol Visual Inteligente (`SignalBeaconScreen`):** Tela cheia imersiva alternando cores solares de alto contraste (**Laranja Neon `#FF7A3D`** e **Amarelo Solar `#FFD600`**), visíveis sob sol forte. |
| **Dinâmica costeira rápida** | A maré sobe, o cliente entra no mar ou muda de lugar rapidamente. | **Live Tracking SSE + Alerta 60m + Canal Rápido:** Notificação imediata para sair do mar e mensagens de 1 toque (*"A maré subiu, recuei alguns metros"*). |
| **Logística de pagamento inviável** | Levar maquininha ou dinheiro vivo para a areia envolve risco de perda, roubo e notas molhadas. | **Zero Dinheiro na Areia:** Cobrança Pix 100% antecipada com QR Code dinâmico, código Copia e Cola e confirmação instantânea por webhook. |
| **Gestão descentralizada de quiosques** | Quiosques de praia não operam com computadores complexos de PDV. | **Portal Web B2B Responsivo:** Auto-onboarding com endereço tradicional, upload de fotos no Cloudinary e simulador de repasse financeiro. |

---

## 3. Perfis de Usuário (Personas & Roles)

1. **Banhista / Cliente (`CLIENT`):**
   - Utiliza o aplicativo mobile [`apps/app_cliente`](apps/app_cliente/README.md).
   - Descobre quiosques por parceria, marca o pin do guarda-sol na praia, adiciona referências visuais e fotos, paga com Pix e acompanha o entregador pelo Farol Visual e Live Tracking.
2. **Entregador Pedestre / Courier (`COURIER`):**
   - Utiliza o aplicativo mobile [`apps/app_entregador`](apps/app_entregador/README.md).
   - Consulta pedidos disponíveis prontos (`EM_PREPARO`), assume entregas, navega pela areia com o Radar Pedestre, emite telemetria em segundo plano e confirma a entrega validada por Geofencing de 60m.
3. **Operador de Quiosque / Restaurante (`KIOSK_OPERATOR`):**
   - Utiliza o Portal Web [`web`](web/README.md).
   - Realiza auto-cadastro com endereço tradicional da orla e posto de referência, personaliza a vitrine (logo e capa), cadastra itens do cardápio com fotos e organiza canais de parceria e repasses líquidos.
4. **Administrador da Plataforma (`ADMIN`):**
   - Utiliza a área administrativa do Portal Web [`web`](web/README.md).
   - Cria e supervisiona canais de venda globais (`partnerships`) e associa operadores de quiosque a estabelecimentos.

---

## 4. Arquitetura do Ecossistema (Monorepo Multi-App)

O repositório adota arquitetura monorepo com módulos e aplicações desacopladas:

```text
pe-na-areia/
├── backend/                     # Java 21, Spring Boot 3.3, MongoDB GeoJSON, SSE, Pix e Cloudinary
├── web/                         # Portal Web React 19 + TypeScript + Vite (Operador e Admin)
├── packages/
│   └── core_shared/             # Módulo Flutter compartilhado (Design System, Modelos, HTTP, Repositórios)
├── apps/
│   ├── app_cliente/             # App do Cliente / Banista (com.penaareia.cliente)
│   ├── app_entregador/          # App do Entregador / Courier (com.penaareia.entregador)
│   └── app_prototipo/           # Protótipo Interativo & Showcase Multiplataforma (Web e Android)
├── dist-mobile/                 # Instaladores Android organizados para distribuição (.apk)
├── scripts/                     # Automação multi-app (test-all, build-all, iniciar-wifi, serve-mobile)
├── infrastructure/              # Docker Compose (MongoDB rs0, Cloudinary Mock e Backend Spring Boot)
└── e2e/                         # Suíte End-to-End automatizada (44 asserções full-stack)
```

---

## 5. Modelo de Domínio e Esquemas Geoespaciais (MongoDB)

### 5.1 Coleção: `kiosks`
```javascript
{
  "_id": "kiosk-santos-1",
  "nome": "Quiosque Pé na Areia",
  "pontoReferenciaId": "posto-4",
  "localizacao": { "type": "Point", "coordinates": [-46.3325, -23.9680] },
  "ativo": true,
  "aceitaEmbalagemSustentavel": true,
  "fotoCapaUrl": "https://res.cloudinary.com/.../capa.jpg",
  "logoUrl": "https://res.cloudinary.com/.../logo.jpg",
  "descricaoCurta": "Melhores porções e água de coco fresca do Canal 4",
  "avaliacaoMedia": 4.9,
  "destaquePopular": true,
  "cnpj": "12.345.678/0001-90",
  "cep": "11055-000",
  "logradouro": "Avenida Bartolomeu de Gusmão",
  "numero": "Quiosque 42",
  "bairro": "Embaré",
  "cidade": "Santos",
  "uf": "SP",
  "cardapio": [
    {
      "id": "item-camarao-01",
      "nome": "Porção de Camarão Empanado",
      "descricao": "400g com molho tártaro especial",
      "preco": 68.90,
      "disponivel": true,
      "category": "Porções",
      "returnablePackaging": true,
      "fotoUrl": "https://res.cloudinary.com/.../camarao.jpg",
      "destaque": true
    }
  ]
}
```

### 5.2 Coleção: `partnerships` (Canais Globais)
```javascript
{
  "_id": "pe-na-areia-app",
  "name": "App Oficial Pé na Areia",
  "channel": "APP",
  "active": true
}
```

### 5.3 Coleção: `kiosk_partnerships` (Configurações por Canal)
```javascript
{
  "_id": "kiosk-santos-1_pe-na-areia-app",
  "kioskId": "kiosk-santos-1",
  "partnershipId": "pe-na-areia-app",
  "active": true,
  "commissionPercent": 10.0,
  "deliveryFee": 7.00,
  "deliveryFeePayer": "CLIENT", // "CLIENT" | "KIOSK"
  "minimumOrder": 25.00,
  "maxItemsPerOrder": 15,
  "acceptFrom": "08:00",
  "acceptUntil": "20:00",
  "prepMinutes": 25,
  "filters": {
    "categories": ["Porções", "Bebidas", "Açaí & Gelados"],
    "onlyReturnable": false
  },
  "productIds": ["item-camarao-01", "item-coco-02"]
}
```

### 5.4 Coleção: `orders` (Pedidos com Geofencing e Snapshot)
```javascript
{
  "_id": "order-6725a-981",
  "userId": "user-cliente-1",
  "kioskId": "kiosk-santos-1",
  "courierId": "user-entregador-2",
  "partnershipId": "pe-na-areia-app",
  "status": "A_CAMINHO", // CRIADO, PAGO, EM_PREPARO, A_CAMINHO, CHEGOU_NO_LOCAL, ENTREGUE, CANCELADO
  "formaPagamento": "PIX",
  "pago": true,
  "valorTotal": 75.90,
  "pricingSnapshot": {
    "commissionPercent": 10.0,
    "commissionAmount": 6.89,
    "deliveryFee": 7.00,
    "deliveryFeePayer": "CLIENT",
    "subtotal": 68.90,
    "customerTotal": 75.90,
    "kioskNet": 62.01
  },
  "pixTxId": "PNA6725A981",
  "pixCopiaECola": "00020126580014br.gov.bcb.pix...",
  "pinCliente": { "type": "Point", "coordinates": [-46.3330, -23.9685] },
  "pontoReferenciaId": "posto-4",
  "descricaoLocal": "Guarda-sol azul marinho perto da rede de futevôlei",
  "referenciaBarraca": "Guarda-sol azul marinho com 2 cadeiras",
  "complementoLocal": "Ao lado do canal 4",
  "contatoNome": "Carlos Silva",
  "contatoTelefone": "+55 (13) 99876-5432",
  "etiquetaLocal": "MEU_GUARDA_SOL",
  "fotoLocalUrl": "https://res.cloudinary.com/.../barraca.jpg",
  "localizacaoEntregador": { "type": "Point", "coordinates": [-46.3328, -23.9683] },
  "alertaProximidadeEnviado": true,
  "mensagens": [
    { "senderId": "user-cliente-1", "senderRole": "CLIENT", "texto": "A maré subiu, recuei 5m", "enviadoEm": "2026-11-02T15:30:00Z" }
  ]
}
```

---

## 6. Requisitos Funcionais Detalhados (RF-01 a RF-18)

- **RF-01 (Autenticação e Sessão RBAC):** Autenticação stateless via JWT com perfis segregados (`CLIENT`, `COURIER`, `KIOSK_OPERATOR`, `ADMIN`).
- **RF-02 (Gestão de Cardápio CRUD):** O operador do quiosque cadastra, edita, pausa/ativa e remove itens de seu cardápio com foto, preço, categoria e flag de embalagem retornável.
- **RF-03 (Upload de Imagens em Nuvem):** Upload multipart para Cloudinary em pastas dedicadas (`pe-na-areia/cardapio` e `pe-na-areia/locais`) com emulador local Docker para desenvolvimento.
- **RF-04 (Configuração de Canais e Comissões):** Parametrização de comissão (`0%–30%`), taxa de entrega, pagador (`CLIENT` ou `KIOSK`), pedido mínimo e janela de horário por parceria.
- **RF-05 (Simulador de Repasse Financeiro):** Prévia em tempo real do valor bruto, comissão da plataforma e valor líquido recebido pelo quiosque antes de salvar alterações.
- **RF-06 (Snapshot Imutável de Preços):** Gravação imutável no pedido dos preços, comissões e taxas vigentes no momento da compra.
- **RF-07 (Pin Interativo na Faixa de Areia):** Posicionamento do pin no Google Maps na areia com validação de proximidade a um Posto de Salvamento oficial (raio máximo de 500m).
- **RF-08 (Guia de Fotos e Ponto na Areia):** Captura de foto do guarda-sol, visão do posto, referências textuais de até 140 caracteres e etiquetas amigáveis.
- **RF-09 (Pagamento Pix Dinâmico):** Emissão automática de código Pix Copia e Cola (padrão EMV BR Code) e QR Code dinâmico com validade de 10 minutos.
- **RF-10 (Confirmação Pix via Webhook):** Endpoint seguro protegido por segredo compartilhado (`X-Webhook-Secret`) que transiciona o pedido para `PAGO`.
- **RF-11 (Live Tracking via SSE):** Streaming contínuo e reativo via Server-Sent Events (`GET /orders/{id}/stream`) para sincronização em tempo real de coordenadas e status.
- **RF-12 (Gatilho de Proximidade de 60 Metros):** Disparo de evento e notificação quando o entregador atinge distância `<= 60m` do pin do cliente.
- **RF-13 (Farol Visual de Tela Cheia):** Ativação de tela cheia com alternância de cores solares (**Laranja Neon `#FF7A3D`** e **Amarelo Solar `#FFD600`**), código do pedido e temporizador regressivo de 3 minutos.
- **RF-14 (Modo Bússola / Radar Pedestre):** Cálculo contínuo da distância direta (Haversine), rumo em graus (azimute) e direção cardeal em português (*"A 45 m a Sudeste (135°) do Posto 4"*).
- **RF-15 (Foto do Local com Zoom no Radar):** Exibição da foto do guarda-sol na tela do entregador com suporte a zoom interativo e pan.
- **RF-16 (Telemetria Contínua de GPS):** Envio periódico da coordenada do entregador em primeiro e segundo plano com Foreground Service.
- **RF-17 (Confirmação por Geofencing de 60m):** Validação matemática no backend que bloqueia a confirmação de entrega se o entregador estiver a mais de 60 metros do pin do cliente.
- **RF-18 (Canal Rápido de Praia e WhatsApp):** Mensagens pré-formatadas de um toque para imprevistos e botão direto para WhatsApp durante a entrega.

---

## 7. Regras de Negócio Validadas no Servidor (RN-01 a RN-12)

- **RN-01 (Validação Geodésica de Posto de Referência):** O pin do cliente deve estar a no máximo **500 metros** do Posto de Salvamento selecionado. Tentativas fora desse limite retornam erro HTTP `400 BAD_REQUEST`.
- **RN-02 (Validação de Geofencing para Conclusão de Entrega):** O endpoint `POST /orders/{id}/confirm-delivery` calcula a distância geodésica entre o GPS atual do entregador e o pin do cliente. Se `distância > 60 metros`, a entrega é bloqueada com HTTP `422 Unprocessable Entity`.
- **RN-03 (Imutabilidade do Pedido Pago):** Uma vez transicionado para `PAGO`, as coordenadas do pin, itens, quiosque e valores tornam-se estritamente imutáveis.
- **RN-04 (Máquina de Estados Estrita do Pedido):**
  `CRIADO` ➔ `PAGO` ➔ `EM_PREPARO` ➔ `A_CAMINHO` ➔ `CHEGOU_NO_LOCAL` ➔ `ENTREGUE`. Cancelamentos (`CANCELADO`) só são autorizados antes do status `A_CAMINHO`.
- **RN-05 (Ativação Condicional do Farol Visual):** A tela do Farol Visual só pode ser acionada no app do cliente quando o pedido estiver em `CHEGOU_NO_LOCAL` ou quando estiver `A_CAMINHO` com distância `<= 60 metros`.
- **RN-06 (Elegibilidade de Itens no Canal de Venda):** Um produto só é exibido e comercializado se o quiosque estiver ativo, a parceria estiver ativa, o produto constar na lista de IDs elegíveis e respeitar os filtros da parceria.
- **RN-07 (Trava de Pedido Mínimo e Máximo de Itens):** O backend rejeita compras cujo subtotal seja inferior a `minimumOrder` ou cujo total de unidades supere `maxItemsPerOrder`.
- **RN-08 (Validação de Horário de Atendimento):** Pedidos só podem ser abertos dentro do intervalo `acceptFrom` e `acceptUntil` configurado na parceria, utilizando o fuso horário oficial `America/Sao_Paulo`.
- **RN-09 (Cálculo do Repasse Líquido):**
  `kioskNet = subtotal - comissao - (deliveryFee se pagador == KIOSK)`. Quando o cliente paga a taxa, ela é somada ao total cobrado dele e não deduzida do quiosque.
- **RN-10 (Limites de Comissão da Plataforma):** A comissão percentual é restrita ao intervalo de `0.0%` a `30.0%`. Valores negativos ou superiores a 30% são rejeitados na API.
- **RN-11 (Autenticidade do Webhook Pix):** O endpoint `POST /webhooks/pix` exige a presença e correspondência do cabeçalho `X-Webhook-Secret` configurado em cofre seguro.
- **RN-12 (Limpeza de Telemetria ao Finalizar):** Ao atingir o status `ENTREGUE` ou `CANCELADO`, a telemetria do entregador para aquele pedido é desativada e a conexão SSE é concluída.

---

## 8. Especificação das Interfaces e Experiências do Usuário

### 8.1 App do Cliente (Jornada das 6 Telas Costeiras)

A experiência do cliente no [`apps/app_cliente`](apps/app_cliente/README.md) é estruturada em 6 telas costeiras projetadas com a paleta oficial (Verde Sage, Laranja Damasco/Apricot, Areia e Tons Solares):

1. **Tela 1 — Cadastro e Edição Detalhada do "Ponto na Praia" (`BeachSpotFormScreen`):**
   - Mini-mapa interativo com pin na areia e cálculo do Posto de Salvamento mais próximo (Postos 1 ao 6).
   - Identificação do guarda-sol com referência de cor e ponto de encontro (até 140 caracteres).
   - Guia de 3 fotos da praia: Guarda-sol/Barraca (obrigatória/principal), Visão do Posto (opcional) e Outro referencial (cooler/bandeira).
   - Dados de contato com máscara brasileira `+55 (13) 9XXXX-XXXX`.
   - Etiquetas rápidas (`Meu Guarda-sol`, `Barraca da Família`, `Point do Surf`, `Outro`).
2. **Tela 2 — Home Principal de Descoberta da Orla (`CustomerDiscoveryTab`):**
   - Header com seletor do ponto na praia, sacola com contador e busca instantânea.
   - Grade de 10 categorias praianas (*Porções, Frutos do Mar, Água de Coco, Bebidas, Açaí, Lanches, Retornáveis ♻️*).
   - Carrossel horizontal de quiosques populares e filtros rápidos (ordenação, entrega grátis, perto do posto).
   - Cards de quiosques com foto de capa, logo, avaliação, tempo de entrega e selo ecológico.
3. **Tela 3 — Vitrine de Quiosques Populares na Orla (`PopularKiosksScreen`):**
   - Visualização ampla em formato de lista com imagens panorâmicas dos quiosques em destaque.
   - Filtros combinados por categoria de alimentos e postos de salvamento.
4. **Tela 4 — Loja e Cardápio do Quiosque (`KioskStorefrontScreen`):**
   - Cabeçalho com logo, foto de capa, avaliação e métricas operacionais (tempo e taxa de entrega).
   - Abas dinâmicas por categoria de produtos.
   - Carrossel de pratos mais pedidos com botão `+` rápido sobre a foto.
   - Barra inferior fixa exibindo o progresso do pedido mínimo e botão de acesso à sacola.
5. **Tela 5 — Sacola de Compras na Praia (`BeachCartScreen`):**
   - Revisão de itens com foto, ajuste de quantidades e switch para embalagem retornável.
   - Resumo financeiro com subtotal, taxa de entrega e botão de checkout Pix.
6. **Tela 6 — Minha Conta e Perfil do Banhista (`CustomerAccountTab`):**
   - Resumo da conta, atalhos para pontos salvos na areia e histórico de pedidos.
   - Card educativo do Farol Visual com botão para simulação e teste prático em tela cheia.

---

### 8.2 App do Entregador (Radar Pedestre, Bússola e Telemetria)

Projetado especificamente para entregas a pé na areia no [`apps/app_entregador`](apps/app_entregador/README.md):
- **Painel de Pedidos:** Fila de pedidos prontos para entrega (`EM_PREPARO`) com tempo decorrido e identificação do quiosque de origem.
- **Modo Bússola / Radar Pedestre (`BeachRadarWidget`):**
  - Desenho de linha tracejada direta no mapa entre o entregador e o pin do cliente.
  - Indicador de rumo e orientação cardeal em português (*"A 45 m a Sudeste (135°) do Posto 4"*).
  - Foto do guarda-sol enviada pelo cliente com modal de zoom tátil em tela cheia.
- **Rastreamento em Segundo Plano:** Envio de telemetria contínua com notificação persistente do sistema Android (`Foreground Service`).
- **Validação de Entrega:** Bloqueio preventivo na interface e validação por Geofencing a 60 metros no servidor ao tocar em "Confirmar Entrega".

---

### 8.3 Portal Web B2B (Onboarding, Vitrine, Cardápio e Gestão de Pedidos)

Desenvolvido em React 19 + TypeScript para os quiosques e administração no [`web`](web/README.md):
- **Auto-Onboarding do Parceiro (`PartnerAuthPanel`):**
  - Cadastro simplificado com endereço comercial tradicional da orla (sem necessidade de pin no mapa).
  - Vínculo automático ao Posto de Salvamento mais próximo via seleção assistida.
- **Identidade e Vitrine (`StorefrontIdentityForm`):**
  - Upload de logomarca circular e foto de capa via Cloudinary.
  - Edição de nome fantasia, CNPJ, descrição curta e destaque popular na orla.
- **Gestão de Cardápio com Fotos (`MenuManager`):**
  - Cadastro e edição de produtos com foto, preço, disponibilidade imediata, selo sustentável e categoria costeira.
- **Gestor de Pedidos do Quiosque (`PartnerOrdersManager`):**
  - Painel kanban em tempo real com abas por status (`Pendentes`, `Em Preparo`, `A Caminho`, `Concluídos`).
  - Atualização com um clique para `EM_PREPARO` e cancelamento fundamentado com motivos padronizados.
- **Configuração de Parcerias e Simulador (`PartnershipConfigPanel`):**
  - Parametrização de taxas, comissões e calculadora de repasse líquido para o quiosque.
- **Área Administrativa (`AdminPanel`):**
  - Criação de parcerias globais e vinculação de operadores a quiosques.

---

### 8.4 Protótipo Interativo & Showcase Multiplataforma

Disponível no [`apps/app_prototipo`](apps/app_prototipo/README.md):
- Showcase navegável de todas as etapas da experiência do cliente e do entregador sem dependência de dados reais no backend.
- Demonstração do Design System oficial e da tela de Splash temática de Entrega Sustentável na Praia de Santos.
- Suporte nativo para Web (`flutter run -d chrome`), Android e iOS.

---

## 9. Catálogo Completo de Endpoints REST e Webhooks

| Método | Endpoint | Perfil / Acesso | Descrição Funcional |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Público | Cadastro de clientes (`CLIENT`) e entregadores (`COURIER`) |
| `POST` | `/auth/login` | Público | Autenticação com retorno de token JWT e perfil |
| `GET` | `/partnerships` | Público | Lista canais de parceria ativos |
| `GET` | `/reference-points` | Público | Lista postos de salvamento oficiais na orla |
| `GET` | `/reference-points/nearby` | Público | Busca postos próximos a uma coordenada (`<= 5km`) |
| `GET` | `/kiosks` | Público | Lista quiosques ativos filtrados por canal de parceria |
| `GET` | `/kiosks/{id}/partnerships` | Público | Consulta taxas e restrições de um quiosque específico |
| `POST` | `/kiosk/me/onboarding` | Autenticado | Auto-cadastro do quiosque/parceiro com endereço tradicional |
| `GET` | `/kiosk/me/storefront` | `KIOSK_OPERATOR` | Consulta dados da vitrine, logo e capa do quiosque |
| `PUT` | `/kiosk/me/storefront` | `KIOSK_OPERATOR` | Atualiza logo, foto de capa, descrição e endereço |
| `GET` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Lista itens do cardápio do quiosque |
| `POST` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Cadastra novo item com foto e categoria |
| `PUT` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Atualiza item do cardápio |
| `DELETE` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Remove item do cardápio |
| `PATCH` | `/kiosk/me/menu/{itemId}/availability` | `KIOSK_OPERATOR` | Pausa ou ativa venda imediata do produto |
| `GET` | `/kiosk/me/partnerships` | `KIOSK_OPERATOR` | Consulta parcerias configuradas do quiosque |
| `PUT` | `/kiosk/me/partnerships/{id}` | `KIOSK_OPERATOR` | Configura produtos elegíveis, taxas e restrições |
| `POST` | `/kiosk/me/partnerships/{id}/preview` | `KIOSK_OPERATOR` | Simula valores de subtotal, comissão e líquido |
| `POST` | `/uploads/menu-item-photo` | `KIOSK_OPERATOR` | Upload de foto de produto para o Cloudinary |
| `POST` | `/uploads/location-photo` | Autenticado | Upload de foto do guarda-sol para o Cloudinary |
| `POST` | `/orders` | `CLIENT` | Criação de pedido na areia com snapshot e cobrança Pix |
| `GET` | `/orders/{id}` | Dono / Courier | Detalhes completos do pedido e localização |
| `GET` | `/orders/{id}/stream` | Dono / Courier | **Server-Sent Events (SSE)** em tempo real |
| `PATCH` | `/orders/{id}/status` | Dono / Courier | Atualiza status (`CANCELADO`, `A_CAMINHO`, etc.) |
| `GET` | `/orders/available` | `COURIER` | Fila de pedidos prontos disponíveis para entrega |
| `GET` | `/orders/courier/active` | `COURIER` | Entregas ativas atribuídas ao entregador |
| `PATCH` | `/orders/{id}/courier-location` | `COURIER` atribuído | Envio de telemetria GPS e avaliação de 60m |
| `POST` | `/orders/{id}/confirm-delivery` | `COURIER` atribuído | Confirmação de entrega validada por Geofencing (60m) |
| `POST` | `/orders/{id}/messages` | Dono / Courier | Envio de mensagem rápida no canal da praia |
| `GET` | `/orders/{id}/messages` | Dono / Courier | Histórico de mensagens do pedido |
| `POST` | `/orders/{id}/pix-charge` | Dono (`CLIENT`) | Emissão/regeneração de cobrança Pix dinâmica |
| `POST` | `/webhooks/pix` | Webhook (`X-Webhook-Secret`) | Confirmação de pagamento Pix e liberação do pedido |
| `POST` | `/admin/partnerships` | `ADMIN` | Criação de canal de parceria global |
| `PUT` | `/admin/partnerships/{id}` | `ADMIN` | Ativação ou pausa de parceria global |
| `PATCH` | `/admin/kiosk-operators` | `ADMIN` | Associação de usuário como operador de quiosque |

---

## 10. Matriz de Rastreabilidade e Status de Implementação

| Módulo / Funcionalidade do PRD | Status no Código | Evidências no Repositório |
| :--- | :---: | :--- |
| **Arquitetura Monorepo Multi-App** | ✅ **100% Implementado** | Pastas `apps/app_cliente`, `apps/app_entregador`, `apps/app_prototipo` e `packages/core_shared`. |
| **Design System Centralizado** | ✅ **100% Implementado** | `packages/core_shared/lib/design_system/` (paleta, tema, logo vetorial nativo). |
| **Motor Geodésico `BeachCompass`** | ✅ **100% Implementado** | `packages/core_shared/lib/domain/utils/beach_compass.dart` (Haversine e azimute em português). |
| **Modelos de Domínio e Validadores** | ✅ **100% Implementado** | `packages/core_shared/lib/domain/` e `forms/` (107 testes unitários passando). |
| **Jornada das 6 Telas do Cliente** | ✅ **100% Implementado** | `BeachSpotFormScreen`, `CustomerDiscoveryTab`, `PopularKiosksScreen`, `KioskStorefrontScreen`, `BeachCartScreen`, `CustomerAccountTab`. |
| **Farol Visual de Tela Cheia** | ✅ **100% Implementado** | `SignalBeaconScreen` com alternância de cores solares e temporizador. |
| **Radar Pedestre e Modo Bússola** | ✅ **100% Implementado** | `BeachRadarWidget` no `app_entregador` com traçado direto e foto com zoom. |
| **Telemetria GPS e Geofencing 60m** | ✅ **100% Implementado** | `PATCH /orders/{id}/courier-location` e `POST /orders/{id}/confirm-delivery` validados no backend. |
| **Streaming em Tempo Real (SSE)** | ✅ **100% Implementado** | `GET /orders/{id}/stream` com `SseEmitter` e recálculo reativo de proximidade. |
| **Canal Rápido de Praia e WhatsApp** | ✅ **100% Implementado** | `POST/GET /orders/{id}/messages` e `url_launcher` para WhatsApp. |
| **CRUD de Cardápio e Vitrine Web** | ✅ **100% Implementado** | `MenuManager.tsx`, `StorefrontIdentityForm.tsx`, `TraditionalAddressForm.tsx` e `KioskMenuController.java`. |
| **Gestão de Pedidos do Quiosque Web** | ✅ **100% Implementado** | `PartnerOrdersManager.tsx` (Kanban com abas, tempos e cancelamento com justificativa). |
| **Simulador de Parcerias e Repasse** | ✅ **100% Implementado** | `PartnershipConfigPanel.tsx` e `POST /kiosk/me/partnerships/{id}/preview`. |
| **Infraestrutura Docker & E2E** | ✅ **100% Implementado** | `docker-compose.yml` (MongoDB `rs0` + Cloudinary Mock) e `e2e_delivery_flow.mjs` (**44 PASS / 0 FAIL**). |
| **Suíte de Testes Automatizados** | ✅ **100% Implementado** | **228 testes backend** (JaCoCo 80%), **138 testes mobile** e **26 testes web**. |
| **Gateway Pix com Banco Real** | 🟡 **Simulado / Pronto para Provedor** | `PixPaymentGateway` gera EMV e SVG determinísticos; webhook está pronto para receber payload de PSP real. |
| **Notificações Push com Firebase FCM** | 🟡 **Mockado em Memória** | `NotificationService` gera `PushAlert` e loga no console; falta credencial do Firebase Admin SDK. |
| **Persistência de Pontos Salvos na Nuvem** | 🟡 **Armazenamento Local no App** | O cliente define múltiplos pontos no app, mas não há coleção no MongoDB (`user_saved_spots`). |
| **Avaliação Pós-Entrega (Rating/Reviews)** | 🟡 **Pendente no App** | `Kiosk.avaliacaoMedia` existe no modelo, mas a tela de feedback pós-entrega não foi criada. |

---

## 11. Próximos Passos de Evolução (Roadmap Futuro)

Com a arquitetura central, logística costeira e as 6 telas 100% funcionais e testadas, os próximos passos concentram-se na preparação para **Go-Live Comercial**:

### Fase 1: Integrações Externas de Produção
1. **Conexão com Gateway Pix Homologado (PSP BACEN):**
   - Substituir o gerador local do `PixPaymentGateway` por integração HTTP/mTLS com um PSP oficial (ex.: **EFI / Gerencianet**, **Mercado Pago** ou **Santander**).
   - Validar a emissão de cobranças Pix com QR Code oficial e conciliação bancária via webhook TLS.
2. **Integração Real com Firebase Cloud Messaging (FCM):**
   - Configurar o `firebase-admin` no backend Spring Boot com arquivo de service account.
   - Adicionar o campo `fcmToken` no cadastro e login de usuários (`User.java`) para envio de push notification real mesmo com o app do cliente fechado.

### Fase 2: Experiência do Usuário e Fidelização
3. **Persistência de Pontos Salvos na Nuvem:**
   - Criar endpoints `GET/POST/DELETE /user/me/saved-spots` e coleção `saved_spots` no MongoDB, permitindo que o cliente acesse seus guarda-sóis e barracas habituais em qualquer dispositivo.
4. **Módulo de Avaliação e Avaliação Pós-Entrega (Reviews):**
   - Implementar tela de feedback no cliente (`POST /orders/{id}/review`) após o status `ENTREGUE`, com avaliação de 1 a 5 estrelas e comentário sobre o atendimento do quiosque e do entregador.
   - Recalcular dinamicamente a `avaliacaoMedia` do quiosque no banco de dados.

### Fase 3: Operações e Inteligência
5. **Automação de Split de Pagamento:**
   - Implementar regras de repasse bancário automático, transferindo a comissão para a plataforma e o valor líquido diretamente para a chave Pix do quiosque no momento da liquidação.
6. **Modo Offline / Resiliência na Faixa de Areia:**
   - Implementar cache local via SQLite/Isar nos apps mobile para tolerar variações bruscas de sinal 4G/5G na praia durante a caminhada do entregador.
