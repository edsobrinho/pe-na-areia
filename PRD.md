# PRD — Pé na Areia

**Versão:** 2.0  
**Data:** 28 de outubro de 2026  
**Status:** Implementado e Validado End-to-End (Backend + App Mobile Flutter + Portal Web React + Infraestrutura Docker)

## 1. Resumo do Produto

**Pé na Areia** é uma plataforma completa de pedidos e logística de última milha para praias urbanas, começando pela orla de Santos/SP. O cliente escolhe itens de quiosques parceiros (com fotos reais do cardápio e opção de embalagem sustentável), realiza o pagamento antecipado via **Pix Copia e Cola / QR Code** e marca seu ponto exato na faixa de areia por meio de um **pin no mapa**, complementado por posto de salvamento de referência, descrição e foto do guarda-sol/barraca.

Para vencer os desafios reais da entrega na areia — onde rotas veiculares do Google Maps não entram, o GPS oscila e há centenas de guarda-sóis parecidos — o sistema entrega **cinco diferenciais logísticos exclusivos**:
1. **Farol Visual Inteligente de Tela Cheia (Sinalizador Solar)** no celular do cliente, ativado automaticamente quando o entregador entra no raio de 60 metros ou chega ao local.
2. **Modo Bússola / Radar Pedestre na Areia** no app do entregador, calculando distância direta em metros (Haversine), azimute em graus, direção cardeal em português (ex.: *"A 42m a Sudeste (135°) do Posto 4"*), linha tracejada pedestre no mapa e zoom na foto do guarda-sol.
3. **Live Tracking em Tempo Real (SSE + Push FCM de 60m)** com atualização contínua da posição do entregador e alerta automático para o cliente sair do mar quando o entregador entra na faixa de 60 metros.
4. **Canal Rápido de Contato Contexto-Dependente** (mensagens rápidas de 1 toque para imprevistos de maré/mudança de barraca e atalho direto para WhatsApp) habilitado exclusivamente enquanto o pedido está em rota (`A_CAMINHO` ou `CHEGOU_NO_LOCAL`).
5. **Pagamento Pix Dinâmico com Webhook ("Zero Dinheiro na Areia")** e **Gestão Completa de Cardápio com Fotos + Canais de Parceria** no Portal Web do Quiosque.

---

## 2. Problema e Oportunidade

Pedidos feitos na faixa de areia enfrentam quatro barreiras críticas que apps tradicionais de delivery urbano não resolvem:
1. **Ausência de endereço postal e rotas na areia:** Mapas convencionais traçam rotas apenas até o calçadão/avenida. Ao pisar na areia, o entregador perde a orientação direcional até o cliente.
2. **Ambiguidade visual na multidão:** Em dias de sol, dezenas de guarda-sóis da mesma cor cercam o mesmo posto de salvamento, e o GPS civil possui margem de erro de 10 a 15 metros.
3. **Dinâmica rápida de praia:** A maré sobe, o cliente entra no mar ou muda de barraca, exigindo alertas de proximidade precisos e comunicação instantânea sem burocracia.
4. **Segurança e logística financeira:** Levar maquininha de cartão ou troco em espécie para a areia sob sol, maresia e risco de perda inviabiliza a operação em escala.

O **Pé na Areia** resolve cada uma dessas dores combinando georreferenciamento validado no servidor (`GeoJsonPoint`), telemetria em tempo real via Server-Sent Events (`SseEmitter`), orientação por azimute/bússola, sinalização luminosa de alto contraste e liquidação Pix com webhook.

---

## 3. Visão e Objetivos

**Visão:** Permitir que banhistas peçam de quiosques da orla e recebam diretamente no seu guarda-sol na faixa de areia com localização verificável, orientação pedestre exata para o entregador e gestão autônoma de cardápio e parcerias pelos quiosques.

### Objetivos Alcançados na Versão 2.0

1. **Catálogo Visual e Parcerias Multi-Canal:** Permitir que operadores de quiosque cadastrem, editem e excluam produtos com foto (`fotoUrl` via Cloudinary), preço, categoria e indicador de embalagem retornável, além de configurar regras comerciais por canal de venda (`partnershipId`).
2. **Pin de Entrega Validado na Orla:** Capturar coordenadas precisas no mapa, vincular a um Posto de Salvamento a até 500 metros, anexar foto do guarda-sol e validar os dados com máscaras e regras de negócio no frontend, web e backend.
3. **Logística Pedestre na Faixa de Areia:** Guiar o entregador com **Radar/Bússola na Areia**, **Live Tracking**, **Alerta de Proximidade de 60m**, **Farol Visual de Tela Cheia** e **confirmação de entrega bloqueada por Geofencing (raio de 60m)**.
4. **Pagamento Antecipado Pix com Webhook:** Gerar payload EMV BR Code (`pixCopiaECola`), QR Code e `pixTxId`, permitindo confirmação automática via `POST /webhooks/pix`.
5. **Infraestrutura 100% Reproduzível em Docker:** Subir MongoDB Replica Set (`rs0`), container **Cloudinary Mock** compatível com o SDK oficial Java e API Spring Boot em um único comando, com suíte End-to-End automatizada (`44 PASS / 0 FAIL`).

---

## 4. Perfis de Usuário e Necessidades

| Perfil | Role no Sistema | Principais Necessidades Atendidas |
| :--- | :--- | :--- |
| **Cliente na Praia** | `CLIENT` | Descobrir quiosques e pratos com fotos; marcar seu guarda-sol no mapa; pagar com Pix Copia e Cola; acompanhar o entregador em tempo real; receber alerta a 60m; ativar o **Farol Visual** na tela e enviar mensagens rápidas se a maré subir. |
| **Entregador** | `COURIER` | Visualizar pedidos prontos e aceitar entregas; emitir localização GPS automática em rota; usar o **Radar Pedestre (distância + direção cardeal + foto com zoom)** na areia; trocar mensagens rápidas com o cliente e confirmar a entrega via GPS dentro de 60m. |
| **Operador de Quiosque** | `KIOSK_OPERATOR` | Gerenciar o cardápio completo no Portal Web (cadastrar/editar/remover itens e enviar fotos ao Cloudinary); ativar/pausar canais de parceria; configurar comissões, taxas de entrega, pedido mínimo, janela de horário e simular repasses líquidos. |
| **Administrador** | `ADMIN` | Cadastrar e ativar/pausar canais de parceria globais (`partnerships`) e vincular contas de usuários como operadores responsáveis por quiosques (`KIOSK_OPERATOR`). |

---

## 5. Escopo Funcional Detalhado

### 5.1 Conta, Sessão e Validações de Entrada

- Cadastro e autenticação JWT para `CLIENT`, `COURIER`, `KIOSK_OPERATOR` e `ADMIN`.
- Validações e máscaras padronizadas no **App Flutter** e no **Portal Web React**:
  - E-mail validado por formato, nome completo com mínimo de caracteres, senha forte (mínimo de 8 caracteres) e máscara automática de telefone brasileiro `(XX) XXXXX-XXXX` quando aplicável.
  - Descrição do ponto na areia limitada a 140 caracteres com contador visual e sanitização de espaços.

### 5.2 Catálogo Visual, Gestão de Cardápio (CRUD) e Canais de Parceria

- **Exibição de Fotos Reais (`fotoUrl`):** Tanto o App Flutter quanto o Portal Web exibem a miniatura/foto de cada item do cardápio com fallback visual elegante caso o item não possua imagem.
- **CRUD de Cardápio pelo Operador (`KIOSK_OPERATOR`):**
  - Listagem completa dos itens do quiosque (`GET /kiosk/me/menu`).
  - Criação (`POST /kiosk/me/menu`), atualização (`PUT /kiosk/me/menu/{itemId}`) e remoção (`DELETE /kiosk/me/menu/{itemId}`).
  - Upload de foto de produto (`POST /uploads/menu-item-photo`) armazenado na pasta `pe-na-areia/cardapio` do Cloudinary.
- **Regras por Parceria (`partnershipId`):**
  - Elegibilidade de produtos por canal, filtros por categoria e embalagem retornável, comissão (`0%` a `30%`), taxa de entrega e pagador da taxa (`CLIENT` ou `KIOSK`), pedido mínimo, limite de unidades e janela de horário (`America/Sao_Paulo`).
  - Gravação de `pricingSnapshot` imutável no pedido no momento da compra.

### 5.3 Seleção do Local de Entrega na Praia

- Mapa interativo (Google Maps) no Flutter e no Web para posicionamento do pin na faixa de areia.
- Sugestão automática dos postos de referência próximos (`GET /reference-points/nearby`) e validação no backend exigindo que o pin esteja a **no máximo 500 metros** do posto selecionado.
- Upload opcional de foto do local/guarda-sol (`POST /uploads/location-photo`, até 5 MB, JPEG/PNG/WebP, pasta `pe-na-areia/locais`).

### 5.4 Pagamento Pix Dinâmico e Webhook (Zero Dinheiro na Areia)

- Ao criar um pedido com `formaPagamento: PIX` (ou acionar `POST /orders/{orderId}/pix-charge`), o backend utiliza o `PixPaymentGateway` para gerar:
  - `pixCopiaECola` (payload EMV BR Code válido),
  - `pixQrCodeBase64`,
  - `pixTxId` único e `pixExpiracao` (10 minutos).
- Caso `PIX_GATEWAY_URL` e `PIX_GATEWAY_TOKEN` estejam configurados, o sistema integra via HTTP com o provedor externo; em ambiente local/homologação, utiliza gerador EMV determinístico sem dependências externas.
- O endpoint `POST /webhooks/pix` valida o segredo (`X-Webhook-Secret`) e confirma o pagamento (`pago = true`), transicionando pedidos em `CRIADO` para `PAGO` e notificando os clientes conectados via SSE e FCM.
- Na interface do Cliente (Flutter e Web), um card dedicado exibe o código **Pix Copia e Cola** com botão de cópia rápida.

### 5.5 Live Tracking em Tempo Real e Alerta de Entrada na Areia (60m)

- **Telemetria do Entregador:** Enquanto o pedido está `A_CAMINHO`, o app do entregador envia sua coordenada GPS (`PATCH /orders/{orderId}/courier-location`) periodicamente.
- **Streaming SSE:** O endpoint `GET /orders/{orderId}/stream` mantém conexão `SseEmitter` ativa emitindo eventos `order-update` sempre que o status, pagamento, posição do entregador ou mensagens mudam.
- **Gatilho de Proximidade de 60m:** Na primeira vez em que a distância entre `localizacaoEntregador` e `pinCliente` atinge `<= 60 metros`, o backend marca `alertaProximidadeEnviado = true` e dispara notificação push via `NotificationService`:
  > *"🏖️ Seu entregador está na areia a menos de 60m! Saia do mar e ative o Sinalizador."*

### 5.6 Farol Visual Inteligente de Tela Cheia (Cliente)

- **Regra de Ativação Contextual:** O botão `"🔦 Ativar Sinalizador na Praia"` na `CustomerHomeScreen` só é habilitado quando:
  1. `status == CHEGOU_NO_LOCAL`, **OU**
  2. `status == A_CAMINHO` **e** a distância calculada entre o entregador e o pin do cliente for **`<= 60 metros`** (ou `alertaProximidadeEnviado == true`).
- **Comportamento da `SignalBeaconScreen`:**
  - Entra em modo tela cheia imersivo (`SystemUiMode.immersiveSticky`).
  - Alterna automaticamente cores solares de altíssimo contraste a cada 700ms (**Laranja Neon `#FF7A3D`**, **Amarelo Solar `#FFD600`** e **Branco `#FFFFFF`**), com botão para travar a cor caso o cliente prefira.
  - Exibe cronômetro regressivo de **3 minutos**, código curto do pedido (`#ID`) em tipografia gigante e a descrição do ponto na areia para que o entregador reconheça o cliente a dezenas de metros.

### 5.7 Modo "Bússola / Radar Pedestre na Areia" (Entregador)

- **Cálculo Geodésico em Tempo Real (`BeachCompass` + `BeachRadarWidget`):**
  - Calcula a distância direta em metros (fórmula de Haversine) e o azimute/bearing inicial (`0°–360°`) entre o GPS atual do entregador e o `pinCliente`.
  - Converte o ângulo para as 8 direções cardeais/colaterais em português (`Norte`, `Nordeste`, `Leste`, `Sudeste`, `Sul`, `Sudoeste`, `Oeste`, `Noroeste`), exibindo instruções claras como:
    > **"A 45 m a Sudeste (135°) do Posto 4"**
- **Linha Tracejada Pedestre e Foto com Zoom:**
  - Desenha no Google Maps do entregador uma `Polyline` tracejada direta conectando a posição atual do entregador ao pin do cliente na areia.
  - Exibe em destaque a foto do guarda-sol (`fotoLocalUrl`) com modal de zoom interativo (`InteractiveViewer`) ao tocar, além da descrição textual do local.

### 5.8 Canal Rápido de Contato na Praia

- Habilitado exclusivamente durante os estados `A_CAMINHO` e `CHEGOU_NO_LOCAL`.
- Permite enviar e listar mensagens rápidas vinculadas ao pedido (`POST /orders/{orderId}/messages` e `GET /orders/{orderId}/messages`), com atalhos de **1 toque** para situações típicas de praia:
  - Cliente: *"🌊 A maré subiu, mudei alguns metros para trás"*, *"🔦 Estou levantando o Sinalizador na tela"*, *"🏖️ Estou atento perto do guarda-sol"*.
  - Entregador: *"🏃 Estou entrando na faixa de areia!"*, *"👀 Estou perto do posto procurando seu guarda-sol"*, *"🔦 Ative o Sinalizador na tela para eu te ver"*.
- Inclui botão direto para **WhatsApp** com mensagem pré-formatada contendo o código do pedido.

### 5.9 Máquina de Estados do Pedido e Geofencing de Entrega

Fluxo oficial de estados no backend:
`CRIADO → PAGO → EM_PREPARO → A_CAMINHO → CHEGOU_NO_LOCAL → ENTREGUE` (com `CANCELADO` permitido apenas antes de `A_CAMINHO`).

- A confirmação final (`POST /orders/{orderId}/confirm-delivery`) exige as coordenadas GPS atuais do entregador e valida no servidor se a distância até o `pinCliente` é **menor ou igual a 60 metros** (`app.delivery.confirmation-radius-meters`). Tentativas fora do raio são rejeitadas com HTTP `422 Unprocessable Entity`.

---

## 6. Arquitetura e Stack Tecnológica

| Camada | Tecnologias Principais |
| :--- | :--- |
| **Backend (`backend/`)** | Java 21 (Virtual Threads habilitadas), Spring Boot 3.3, Spring Security (JWT), Spring Data MongoDB (`GeoJsonPoint`, transações em Replica Set), Server-Sent Events (`SseEmitter`), Cloudinary SDK (`cloudinary-http44`), Firebase Admin SDK (FCM), Micrometer Tracing + JaCoCo (cobertura >= 80%). |
| **App Mobile (`frontend/`)** | Flutter 3.29+ (Dart null-safety), `provider`, `google_maps_flutter`, `geolocator`, `image_picker`, `http`, `flutter_secure_storage`. |
| **Portal Web (`web/`)** | React 19, TypeScript, Vite 8, `@googlemaps/js-api-loader`, Oxlint, testes automatizados com `node:test`. |
| **Infraestrutura & E2E (`infrastructure/`, `e2e/`)** | Docker Compose v2 (`mongodb:7` com Replica Set `rs0`, `cloudinary-mock` Node.js na porta `8099`, `backend` na porta `8080`) e suíte E2E `e2e/e2e_delivery_flow.mjs`. |

---

## 7. Matriz de Capacidades e Estado Atual

| Capacidade | Estado Atual | Camadas Integradas |
| :--- | :--- | :--- |
| Cadastro/login JWT (`CLIENT`, `COURIER`, `KIOSK_OPERATOR`, `ADMIN`) | **100% Produção / Validado** | Backend + Flutter + Web |
| Máscaras e validações de formulário e checkout | **100% Produção / Validado** | Backend + Flutter + Web |
| Gestão de Parcerias, Taxas, Restrições e Snapshot de Preço | **100% Produção / Validado** | Backend + Flutter + Web |
| CRUD de Cardápio do Quiosque com Upload de Foto (`fotoUrl`) | **100% Produção / Validado** | Backend + Web + Flutter |
| Pin Interativo na Areia + Posto de Referência (<= 500m) + Foto do Local | **100% Produção / Validado** | Backend + Flutter + Web |
| Farol Visual Inteligente de Tela Cheia (`<= 60m` ou `CHEGOU_NO_LOCAL`) | **100% Produção / Validado** | Backend + Flutter |
| Bússola / Radar Pedestre na Areia (Haversine + Azimute + Linha Tracejada) | **100% Produção / Validado** | Flutter + Backend |
| Live Tracking do Entregador + Streaming SSE + Alerta Push 60m | **100% Produção / Validado** | Backend + Flutter |
| Canal Rápido de Mensagens na Praia + Atalho WhatsApp | **100% Produção / Validado** | Backend + Flutter |
| Pagamento Pix Dinâmico (EMV Copia e Cola / QR Code) + Webhook | **100% Produção / Validado** | Backend + Flutter + Web |
| Confirmação de Entrega com Geofencing (raio de 60m) | **100% Produção / Validado** | Backend + Flutter |
| Infraestrutura Cloudinary Mock em Docker + Testes E2E (`44 PASS`) | **100% Produção / Validado** | Docker + Backend + E2E |

---

## 8. Especificação Funcional da Nova Experiência do Cliente (v2.1 — 6 Telas Costeiras)

Esta seção especifica a evolução da jornada visual e funcional do **App do Cliente** com identidade 100% própria do **Pé na Areia** (`AppColors`: Oceano `#0B3B40`/`#135A61`/`#1E8A93`, Areia `#F7F1E2`/`#EFE2C4`, Coral Solar `#FF7A3D` e Espuma do Mar `#4C8C6B`), reaproveitando integralmente os repositórios, validadores e serviços já homologados.

### 8.1 Tela 1 — Cadastro e Edição Detalhada do "Ponto na Praia" (`BeachSpotFormScreen`)
- **Objetivo:** Permitir que o banhista detalhe seu ponto exato na faixa de areia combinando mini-mapa, referências visuais da barraca, guia de fotos categorizadas da praia, dados de contato e etiquetas rápidas.
- **Componentes e Regras:**
  1. **Mini-Mapa com Pin + Botão `"Ajustar no mapa"`:** Exibe preview do Google Maps centrado no `GeoPoint` atual e o Posto de Salvamento vinculado (ex.: *"Próximo ao Posto 4 · Embaré, Santos/SP"*). Ao tocar em `"Ajustar no mapa"`, abre a `LocationSelectionScreen` existente.
  2. **Identificação na Faixa de Areia:**
     - Campo **Referência da Barraca / Cor do Guarda-Sol\*** + checkbox `[ ] Sem guarda-sol / Estou na faixa de areia`.
     - Campo **Complemento / Ponto de Encontro\*** + checkbox `[ ] Sem complemento adicional`.
     - Os campos compõem o `descricaoLocal` validado em até 140 caracteres.
  3. **Guia de Foto na Areia (3 Slots Visuais Praianos):**
     - 🏖️ **Guarda-sol / Barraca** (`fotoLocalUrl` principal enviada via `POST /uploads/location-photo`).
     - 🛟 **Visão do Posto / Calçadão** (`fotoVisaoPostoUrl` opcional).
     - 📸 **Outro Referencial** (`fotoOutroReferencialUrl` opcional — cooler, bandeira, rede).
  4. **Contato na Praia:**
     - **Nome de quem vai receber\*** (`contatoNome`, validado por `Validators.personName`).
     - **Telefone / WhatsApp com DDI `+55`\*** (`contatoTelefone`, formatado com `Formatters.brPhone` e validado por `Validators.brPhone`).
  5. **Salvar Ponto Como (`etiquetaLocal`):**
     - Chips selecionáveis: `🏖️ Meu Guarda-sol`, `👨‍👩‍👧‍👦 Barraca da Família`, `🏄 Point do Surf`, `📍 Outro`.

### 8.2 Tela 2 — Home Principal de Descoberta da Orla (`CustomerDiscoveryTab` — Aba `Início`)
- **Objetivo:** Vitrine principal de descoberta com busca instantânea, categorias praianas, quiosques populares na orla, filtros inteligentes e navegação inferior em 3 abas (`Início`, `Pedidos`, `Conta`).
- **Componentes e Regras:**
  1. **Header Costeiro (`ocean900`):** Seletor do Ponto na Praia atual à esquerda, ícone da Sacola com badge numérico à direita e barra de busca integrada (`"Buscar porções, água de coco, açaí ou quiosque..."`).
  2. **Banner Sustentável + Seletor de Canal (`partnershipId`):** Destaque para embalagem retornável e entrega no guarda-sol com o Sinalizador Solar.
  3. **Grade de 10 Categorias Praianas (2 linhas × 5 colunas):** `Porções`, `Frutos do Mar`, `Água de Coco`, `Bebidas`, `Lanches`, `Açaí & Gelados`, `Petiscos`, `Retornáveis ♻️`, `Entrega Grátis`, `Destaques`.
  4. **Seção Horizontal `"Quiosques Populares na Orla"`:** Avatares/cards compactos dos quiosques marcados com `destaquePopular == true` e link `"Ver todos >"` para a Tela 3.
  5. **Barra de Chips de Filtro e Ordenação:** `Ordenar v` (Menor taxa, Menor tempo, Mais próximos), `♻️ Embalagem Retornável`, `🏃 Entrega Grátis` e `🛟 Perto do Meu Posto`.
  6. **Feed de Quiosques:** Cards com foto de capa (`fotoCapaUrl` ou primeira `fotoUrl` do cardápio), avaliação (`avaliacaoMedia`), tempo estimado (`prepMinutes`), taxa de entrega (`deliveryFee`), distância até o pin e selo de sustentabilidade.

### 8.3 Tela 3 — Vitrine Temática: "Quiosques Populares na Orla" (`PopularKiosksScreen`)
- **Objetivo:** Lista expandida com cards fotográficos amplos (`16:9`) dos quiosques de destaque da orla de Santos.
- **Componentes e Regras:**
  1. Header em degradê oceânico (`ocean900` → `ocean500`) com título `"Quiosques Populares na Orla"` e botão voltar.
  2. Filtros rápidos no topo (`Ordenar v` e `Categorias / Postos v`).
  3. Cards amplos exibindo foto de capa dos pratos do quiosque, avatar/logo (`logoUrl`) e selo do Posto sobrepostos, nome do quiosque + praia/posto, avaliação, taxa de entrega, tempo estimado (`prepMinutes`), distância em km e categorias atendidas.

### 8.4 Tela 4 — Loja / Cardápio Dedicado do Quiosque (`KioskStorefrontScreen`)
- **Objetivo:** Página exclusiva de compra em um quiosque, exibindo métricas operacionais da parceria, carrossel de pratos mais pedidos, abas por categoria e barra inferior de validação de pedido mínimo.
- **Componentes e Regras:**
  1. **AppBar:** Voltar, Compartilhar, Favoritar (`♡`) e Busca interna no cardápio do quiosque.
  2. **Cabeçalho do Quiosque:** Logo (`logoUrl`), nome, `descricaoCurta`, posto de referência e avaliação.
  3. **Painel de Métricas em 3 Colunas (alimentado por `KioskPartnershipOffer`):**
     - **Tempo de entrega** (`prepMinutes`, ex.: `20 a 30 min`),
     - **Taxa de entrega na areia** (`R$ 0` ou `deliveryFee`),
     - **Modalidade** (`Entrega no Guarda-Sol`).
  4. **Abas de Categorias (`TabBar`):** Geradas dinamicamente a partir das categorias do cardápio (`Destaques`, `Porções`, `Bebidas`, `Retornáveis ♻️`).
  5. **Carrossel Horizontal `"Destaques / Mais Pedidos"`:** Cards quadrados com foto (`fotoUrl`), botão `+` flutuante sobre a foto, nome e preço (priorizando itens com `destaque == true`).
  6. **Lista Vertical de Produtos por Categoria:** Nome, descrição, selo `♻️ Retornável`, preço e miniatura à direita com botão `+` / seletor de quantidade.
  7. **Barra Fixa Inferior de Pedido Mínimo e Sacola:**
     - Enquanto `subtotal < minimumOrder`: exibe `"Pedido mínimo R$ XX,XX (faltam R$ YY,YY)"`.
     - Quando `subtotal >= minimumOrder`: exibe botão ativo `"Ver Sacola (N itens · R$ ZZ,ZZ)"`.

### 8.5 Tela 5 — Sacola / Carrinho Detalhado na Praia (`BeachCartScreen`)
- **Objetivo:** Revisão dos itens agrupados por quiosque com ajuste rápido de quantidades, tempo estimado, taxa de entrega e avanço direto para confirmação/pagamento Pix.
- **Componentes e Regras:**
  1. Card do quiosque com nome clicável, badge de tempo estimado (`⚡ 15 a 25 min`) e botão de lixeira para limpar a sacola.
  2. Lista de itens com miniatura (`fotoUrl`), nome, observação de embalagem, preço unitário e seletor `[- 1 +]`.
  3. Switch `"Preferir embalagem sustentável/retornável"` e seletor de forma de pagamento (`PIX` ou `CARTAO`).
  4. Rodapé exibindo subtotal, valor da taxa de entrega na areia e botão `"Continuar"` (`mango500`) que envia `POST /orders` e direciona para a aba `Pedidos` (onde o Pix Copia e Cola, o Live Tracking SSE e o Farol Visual de 60m são exibidos).

### 8.6 Tela 6 — Minha Conta / Perfil do Banhista (`CustomerAccountTab` — Aba `Conta`)
- **Objetivo:** Centralizar perfil do cliente, atalhos rápidos, educação sobre o Sinalizador Solar, pontos salvos na praia e encerramento de sessão.
- **Componentes e Regras:**
  1. Cabeçalho com nome (`session.user.nome`), e-mail e botão de suporte.
  2. Card de 3 atalhos rápidos: `🏖️ Ponto na Areia`, `💠 Pix & Pagamento` e `🧾 Meus Pedidos`.
  3. Card educativo **"🔦 Conheça o Sinalizador Solar"** com botão `"Testar Farol"` (abre demonstração da `SignalBeaconScreen`).
  4. Lista de opções: `Formas de pagamento`, `Meus pontos na praia salvos`, `Quiosques favoritos`, `Preferência de Embalagem Retornável`, `Código e Sinalizador de Entrega` e `Sair da conta`.

---

## 9. Análise de Impacto por Camada (Backend, Frontend, Web e E2E)

| Camada | O que JÁ existe (Não refazer) | Alterações / Adições Necessárias para as 6 Telas |
| :--- | :--- | :--- |
| **Backend (`backend/`)** | CRUD de cardápio com `fotoUrl`, upload Cloudinary, parcerias (`minimumOrder`, `deliveryFee`, `prepMinutes`), pedidos, Pix, Live Tracking e Geofencing 60m. | 1. Em `Kiosk`: adicionar `fotoCapaUrl`, `logoUrl`, `descricaoCurta`, `avaliacaoMedia` e `destaquePopular`; em `Kiosk.MenuItem`: adicionar `destaque` (`boolean`).<br>2. Criar `PUT /kiosk/me/storefront` para o operador configurar a vitrine do quiosque.<br>3. Em `Order` / `CreateOrderRequest` / `OrderResponse`: adicionar campos opcionais do Ponto na Praia (`referenciaBarraca`, `complementoLocal`, `fotoVisaoPostoUrl`, `fotoOutroReferencialUrl`, `contatoNome`, `contatoTelefone`, `etiquetaLocal`). |
| **App do Cliente (`frontend/`)** | `ApiClient`, `CatalogRepository`, `OrderRepository`, `UploadRepository`, `LocationSelectionScreen`, `SignalBeaconScreen`, `Validators`, `Formatters` e acompanhamento de pedido com Pix e Farol. | 1. Atualizar modelos/mappers (`Kiosk`, `MenuItem`, `Order`) com os novos campos opcionais.<br>2. Implementar as 6 telas/componentes (`BeachSpotFormScreen`, `CustomerDiscoveryTab`, `PopularKiosksScreen`, `KioskStorefrontScreen`, `BeachCartScreen`, `CustomerAccountTab`) integradas por `BottomNavigationBar` (`Início`, `Pedidos`, `Conta`) em `CustomerHomeScreen`. |
| **Painel Web do Quiosque (`web/`)** | `MenuManager`, `MenuItemFormDialog` com upload de foto, configuração de parcerias e simulador de repasse. | 1. Em `MenuItemFormDialog` e `MenuManager`: adicionar checkbox `"⭐ Produto em destaque (Mais pedido no App)"` (`destaque`).<br>2. Na aba `Meu Quiosque`: adicionar card de configuração da **Vitrine do Quiosque** (`descricaoCurta`, `fotoCapaUrl`, `logoUrl`, `destaquePopular`) consumindo `PUT /kiosk/me/storefront`. |
| **Testes E2E (`e2e/`)** | `e2e/e2e_delivery_flow.mjs` com 44 asserções cobrindo auth, parceria, upload, Pix, Live Tracking 60m, mensagens, entrega e CRUD de cardápio. | Expandir `e2e_delivery_flow.mjs` para testar:<br>1. `PUT /kiosk/me/storefront` (vitrine popular e fotos de capa/logo).<br>2. Criação de item com `destaque: true` no cardápio.<br>3. Criação de pedido com os novos metadados do Ponto na Praia (`referenciaBarraca`, `complementoLocal`, `contatoNome`, `contatoTelefone`, `etiquetaLocal`). |

