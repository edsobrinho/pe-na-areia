# Pé na Areia 🏖️

Plataforma full-stack de pedidos e logística de última milha para entrega na faixa de areia da orla de Santos/SP. O cliente escolhe produtos com foto de quiosques parceiros, paga antecipadamente via **Pix Copia e Cola / QR Code**, fixa o **pin exato do seu guarda-sol no mapa** e utiliza o **Farol Visual de Tela Cheia** quando o entregador se aproxima; o entregador navega pela areia usando o **Modo Bússola / Radar Pedestre**, transmite sua localização em tempo real e confirma a entrega validada por GPS (raio de 60 metros).

---

## 📚 Documentação do Ecossistema

Consulte a documentação dedicada de cada projeto e arquitetura:
- 🚀 **[Plano de Deploy e Distribuição Contínua](DEPLOY.md)** — Guia completo de deploy Wi-Fi (LAN), conteinerização, MongoDB Atlas, Cloudinary oficial, gateways Pix e publicação nas lojas Google Play Store e Apple App Store.
- ⚙️ **[Backend API (Spring Boot 3.3 + Java 21)](backend/README.md)** — Arquitetura de microserviço, Virtual Threads, GeoJSON, transações ACID, SSE, upload Cloudinary e suíte de 227 testes com JaCoCo.
- 💻 **[Portal Web do Parceiro & Admin (React 19 + TypeScript)](web/README.md)** — Painel de auto-cadastro de quiosques, catálogo com fotos, gestão de categorias, canais de parceria e simulador de repasse.
- 📦 **[Módulo Core Shared (Flutter)](packages/core_shared/README.md)** — Design System unificado (Sage & Apricot), modelos de domínio, cliente HTTP, algoritmos geodésicos (`BeachCompass`) e máscaras.
- 🏖️ **[App do Cliente / Banista](apps/app_cliente/README.md)** — Aplicação para pedidos na areia, pin no mapa, pagamento Pix, Live Tracking SSE e Farol Visual (`SignalBeaconScreen`).
- 🧭 **[App do Entregador / Courier](apps/app_entregador/README.md)** — Navegação por Radar Pedestre na areia, bússola geodésica, telemetria contínua e confirmação validada por Geofencing (60m).
- 📱 **[Protótipo Funcional & Showcase](apps/app_prototipo/README.md)** — Demonstração interativa completa e multiplataforma (Web, Android e iOS) sem dependência de backend.
- 📄 **[PRD Consolidado v2.1](PRD.md)** — Especificação completa do ecossistema: logística na praia, Farol Visual, Radar Pedestre, gestão de quiosques, cardápio com fotos, parcerias e regras de negócio.

---

## 🧩 Estrutura do Repositório (Arquitetura Monorepo Multi-App)

```text
pe-na-areia/
├── backend/                     # [Java 21 + Spring Boot 3.3] API REST, GeoJSON, SSE, Pix e Cloudinary
├── web/                         # [React 19 + Vite + TS] Portal Web B2B (Quiosque, Parceiro e Admin)
├── packages/
│   └── core_shared/             # [Flutter Package] Design System, Modelos, HTTP, Repositórios e Geodésia
├── apps/
│   ├── app_cliente/             # [Flutter App] App do Cliente / Banista (com.penaareia.cliente)
│   ├── app_entregador/          # [Flutter App] App do Entregador / Courier (com.penaareia.entregador)
│   └── app_prototipo/           # [Flutter App] Protótipo Navegável & Showcase Multiplataforma
├── dist-mobile/                 # Instaladores Android organizados para distribuição
│   ├── cliente/                 # pe-na-areia-cliente.apk
│   ├── entregador/              # pe-na-areia-entregador.apk
│   └── prototipo/               # pe-na-areia-prototipo.apk
├── scripts/                     # Automação multi-app (test-all, build-all, iniciar-wifi, serve-mobile)
├── infrastructure/              # Docker Compose (MongoDB rs0, Cloudinary Mock e Backend Spring Boot)
│   ├── docker-compose.yml
│   └── cloudinary-mock/         # Emulador local compatível com o SDK oficial do Cloudinary
└── e2e/
    └── e2e_delivery_flow.mjs    # Integração HTTP automatizada (56 verificações; sem automação visual)
```

---

## 🎯 Principais Funcionalidades Implementadas

### 1. Para Clientes (App do Cliente e Portal Web)
- **Autenticação e Validações:** Cadastro e login JWT (`CLIENT`) com validação e máscaras de entrada (e-mail, nome, senha, telefone brasileiro `(XX) XXXXX-XXXX` e limite de 140 caracteres na descrição do ponto).
- **Catálogo Visual por Parceria:** Escolha do canal de venda (`partnershipId`), visualização de quiosques ativos e cardápios com **fotos reais dos produtos (`fotoUrl`)**, filtro de disponibilidade e preferência por embalagem sustentável/retornável.
- **Pin Interativo na Faixa de Areia:** Seleção do ponto exato no Google Maps, sugestão automática do Posto de Salvamento mais próximo (validado até 500 m no servidor), descrição textual do guarda-sol e upload de foto do local (`POST /uploads/location-photo`).
- **Pagamento Antecipado Pix ("Zero Dinheiro na Areia"):** Geração automática de **Pix Copia e Cola** (payload EMV BR Code), QR Code e identificador de transação (`pixTxId`), com atualização via Webhook (`POST /webhooks/pix`).
- **Live Tracking em Tempo Real e Alerta de 60m:** Acompanhamento da posição do entregador via **Server-Sent Events (`GET /orders/{id}/stream`)** e cálculo de distância restante. Quando o entregador entra no raio de **60 metros**, o cliente recebe alerta imediato (*"🏖️ Seu entregador está na areia a menos de 60m! Saia do mar e ative o Sinalizador"*).
- **🔦 Farol Visual Inteligente de Tela Cheia (`SignalBeaconScreen`):** Botão habilitado automaticamente quando o status do pedido é `CHEGOU_NO_LOCAL` **ou** quando está `A_CAMINHO` a **`<= 60 metros`**. Ao tocar, o celular entra em tela cheia imersiva alternando cores solares de alto contraste (**Laranja Neon `#FF7A3D`**, **Amarelo Solar `#FFD600`** e **Branco**), com cronômetro regressivo de 3 minutos e código curto do pedido para localização imediata na multidão.
- **💬 Canal Rápido de Contato na Praia:** Atalhos de 1 toque (*"🌊 A maré subiu, mudei alguns metros para trás"*, *"🔦 Estou levantando o Sinalizador na tela"*) e botão direto para **WhatsApp** com mensagem pré-formatada, habilitados exclusivamente enquanto o pedido está `A_CAMINHO` ou `CHEGOU_NO_LOCAL`.

### 2. Para Entregadores (App do Entregador)
- **Painel de Entregas:** Consulta de pedidos prontos (`EM_PREPARO`) com paginação por cursor e entregas ativas sob responsabilidade do entregador.
- **🧭 Modo Bússola / Radar Pedestre na Areia (`BeachRadarWidget` + `BeachCompass`):**
  - Como rotas veiculares do Google Maps não entram na faixa de areia, o app calcula em tempo real a **distância direta em metros (Haversine)**, o **azimute em graus (`0°–360°`)** e a **direção cardeal/colateral em português** (ex.: *"A 45 m a Sudeste (135°) do Posto 4"*).
  - Desenha uma **linha tracejada direta (`Polyline`)** no mapa conectando o entregador ao pin do cliente.
  - Exibe em destaque a **foto do guarda-sol/local com zoom interativo** ao tocar e a descrição textual do cliente.
- **Telemetria GPS Automática:** Enquanto houver entrega `A_CAMINHO`, o app envia periodicamente a coordenada atual para `PATCH /orders/{id}/courier-location`.
- **Confirmação de Entrega por Geofencing (60m):** O backend valida a posição GPS do entregador no momento da confirmação (`POST /orders/{id}/confirm-delivery`) e bloqueia tentativas fora do raio de 60 metros do pin do cliente.

### 3. Para Operadores de Quiosque e Administradores (Portal Web React)
- **Gestão Completa do Cardápio com Fotos (`MenuManager`):** Operadores (`KIOSK_OPERATOR`) cadastram, editam e excluem itens do cardápio (`GET/POST/PUT/DELETE /kiosk/me/menu`) com upload de foto integrado ao Cloudinary (`POST /uploads/menu-item-photo`).
- **Configuração de Canais de Parceria:** Parametrização de comissões (`0%–30%`), taxa de entrega, pagador da taxa (`CLIENT` ou `KIOSK`), pedido mínimo, limite de itens, janela de atendimento e simulador de repasse líquido.
- **Administração (`ADMIN`):** Criação e ativação/pausa de canais de parceria globais e associação de usuários como operadores de quiosques.

---

## 🐳 Infraestrutura Local em Docker (MongoDB + Cloudinary Mock + Backend)

Requisitos: **Docker** com **Docker Compose v2**.

A infraestrutura local sobe três containers orquestrados com healthchecks:
1. **`mongodb` (`mongo:7`)**: Replica Set de nó único (`rs0`) na porta `27017`, necessário para transações multi-documento do Spring Data MongoDB.
2. **`cloudinary-mock` (`node:22-alpine`)**: Servidor local na porta `8099` 100% compatível com o SDK oficial `cloudinary-http45` do Java (`POST /v1_1/:cloudName/image/upload` e `GET /:cloudName/image/upload/v1/...`), permitindo testar uploads de fotos do local e do cardápio sem depender de conta externa na nuvem.
3. **`backend` (`eclipse-temurin:21`)**: API Spring Boot na porta `8080`, pré-configurada com `CLOUDINARY_UPLOAD_PREFIX=http://cloudinary-mock:8099`.

Na raiz do repositório, execute no PowerShell:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose --env-file .env -f infrastructure/docker-compose.yml up --build -d
```

Verifique o status dos 3 containers:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml ps
```

Serviços disponíveis após a inicialização:
- **API Backend:** `http://localhost:8080`
- **Documentação OpenAPI / Swagger UI:** `http://localhost:8080/docs`
- **Cloudinary Mock Healthcheck:** `http://localhost:8099/health`
- **MongoDB Replica Set:** `mongodb://localhost:27017/pe_na_areia?replicaSet=rs0`

Para encerrar os containers mantendo os dados do volume:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml down
```

### Executar o Teste End-to-End (E2E)

Suba a infraestrutura E2E isolada. Ela usa portas e volumes próprios e não altera os dados Docker de desenvolvimento:

```powershell
docker compose -p pe-na-areia-e2e -f infrastructure/docker-compose.yml -f e2e/docker-compose.yml up -d --build --wait
$env:API_BASE_URL = "http://localhost:18080"
$env:MONGODB_CONTAINER = "pe-na-areia-e2e-mongodb"
$env:PIX_WEBHOOK_TOKEN = "dev-pix-webhook-token-secret-12345"
node e2e/e2e_delivery_flow.mjs

# Remova os containers e volumes de teste ao terminar
docker compose -p pe-na-areia-e2e -f infrastructure/docker-compose.yml -f e2e/docker-compose.yml down -v
```

Resultado esperado: `PASS: 56  FAIL: 0`. Esta suíte valida os contratos HTTP dos perfis de operador, cliente e entregador; não automatiza navegador nem telas Flutter.

---

## 🚀 Executando Cada Camada em Desenvolvimento

### 1. Backend (Java 21 + Spring Boot 3.3)

Consulte o [README do Backend](backend/README.md) para detalhes completos de endpoints, DTOs e serviços.

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml up -d mongodb cloudinary-mock
Set-Location backend
.\gradlew.bat bootRun
```

Para rodar a suíte de testes JUnit 5 e validar a cobertura JaCoCo:

```powershell
Set-Location backend
.\gradlew.bat test
.\gradlew.bat check jacocoTestReport
```

---

### 2. Ecossistema Mobile Multi-App (Flutter 3.29+)

O ecossistema mobile é desacoplado em 3 aplicativos e 1 módulo compartilhado:
- **`packages/core_shared`**: Design System, Modelos de Domínio, Cliente HTTP, Repositórios e Validadores.
- **`apps/app_cliente`**: App do Cliente (`com.penaareia.cliente`) — Catálogo, Pin do Guarda-sol, Pix e Farol Visual.
- **`apps/app_entregador`**: App do Entregador (`com.penaareia.entregador`) — Radar Pedestre, Bússola e Telemetria GPS.
- **`apps/app_prototipo`**: Protótipo Interativo e Showcase (`com.penaareia.prototipo`) — Multiplataforma (Web e Android).

Para executar testes e análise estática em todos os projetos mobile de uma só vez:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-all.ps1
```

Para compilar os APKs de produção de todos os aplicativos:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-all.ps1 -Target all
```

---

#### 📱 Como Baixar e Rodar no Celular Físico via Wi-Fi (Sem Cabos)

Você pode baixar e instalar qualquer um dos aplicativos diretamente pelo navegador do seu celular conectado na mesma rede Wi-Fi, com o backend Spring Boot e MongoDB rodando no seu computador.

##### Método Rápido Automático (1 Clique / Comando)
Na raiz do repositório, dê **duplo clique em `scripts\iniciar-wifi.bat`** ou execute no PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-wifi.ps1
```

O script detecta automaticamente o IP da sua rede Wi-Fi (ex.: `192.168.0.4`), inicia os containers Docker (MongoDB, Cloudinary Mock e Backend Spring Boot) e abre o **Servidor de Download Mobile** na porta `8088`.

No seu celular (conectado ao mesmo Wi-Fi), acesse:
👉 **`http://<IP-DO-PC>:8088`** *(ex.: `http://192.168.0.4:8088`)*

A página exibirá a central de downloads responsiva com os cards dos três aplicativos:
- 🏖️ **App do Cliente**
- 🧭 **App do Entregador**
- 📱 **Protótipo Interativo**

Toque no botão de download do app desejado, abra o arquivo baixado e confirme a instalação!

---

##### Método Passo a Passo Manual

Caso prefira rodar manualmente cada etapa:

###### 1. Descobrir o IP do Wi-Fi
No PowerShell:
```powershell
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" }).IPAddress
```
*Suponha que o IP retornado seja `192.168.0.4`.*

###### 2. Liberar as Portas no Firewall do Windows (uma única vez)
Abra o PowerShell como Administrador:
```powershell
New-NetFirewallRule -DisplayName "Pe na Areia LAN Services" -Direction Inbound -LocalPort 8080,8088,8099,5173 -Protocol TCP -Action Allow
```

###### 3. Subir o Backend Docker na Rede Local
```powershell
$env:CLOUDINARY_PUBLIC_BASE_URL="http://192.168.0.4:8099"
$env:APP_CORS_ORIGINS="http://localhost:*,http://127.0.0.1:*,http://192.168.*:*"
docker compose -f infrastructure/docker-compose.yml up -d
```
> **Teste rápido no navegador do celular:** Acesse `http://192.168.0.4:8080/reference-points`. Se exibir o JSON dos postos da praia (`HTTP 200`), o backend está pronto.

###### 4. Compilar os APKs Multi-App Apontando para o seu IP
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-all.ps1 -Target all -ApiBaseUrl http://192.168.0.4:8080
```
Os APKs gerados ficam salvos em:
- `dist-mobile/cliente/pe-na-areia-cliente.apk`
- `dist-mobile/entregador/pe-na-areia-entregador.apk`
- `dist-mobile/prototipo/pe-na-areia-prototipo.apk`

###### 5. Iniciar o Servidor de Download
```powershell
node scripts/serve-mobile.mjs
```
Abra `http://192.168.0.4:8088` no navegador do celular e instale com 1 toque.

---

### 3. Portal Web (React 19 + TypeScript + Vite)

Consulte o [README do Portal Web](web/README.md) para o guia completo de variáveis de ambiente e perfis de acesso (`KIOSK_OPERATOR` e `ADMIN`).

```powershell
Set-Location web
if (-not (Test-Path .env.local)) { Copy-Item .env.example .env.local }
npm.cmd install
npm.cmd test
npm.cmd run build
npm.cmd run dev
```

O portal web ficará acessível em **`http://localhost:5173`**.

---

## 📡 Referência Completa de Endpoints da API

| Método | Rota | Acesso | Descrição |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Público | Cadastra `CLIENT` ou `COURIER` e retorna token JWT |
| `POST` | `/auth/login` | Público | Autentica usuário e retorna token JWT + perfil |
| `GET` | `/partnerships` | Público | Lista canais de venda ativos |
| `GET` | `/reference-points` | Público | Lista postos de salvamento/referência ativos na orla |
| `GET` | `/reference-points/nearby?lat=&lng=&raioKm=` | Público | Sugere postos próximos ao pin (`raioKm` entre `0.1` e `5.0`) |
| `GET` | `/kiosks?partnershipId=` | Público | Lista quiosques ativos e cardápios elegíveis no canal |
| `GET` | `/kiosks/{id}/partnerships` | Público | Lista ofertas, taxas e restrições por quiosque |
| `GET` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Lista todos os itens do cardápio do quiosque do operador |
| `POST` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Cria novo item no cardápio (com `fotoUrl`, preço, categoria, etc.) |
| `PUT` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Atualiza item existente do cardápio |
| `DELETE` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Remove item do cardápio |
| `GET` | `/kiosk/me/partnerships` | `KIOSK_OPERATOR` | Lista configurações de canais do quiosque associado |
| `PUT` | `/kiosk/me/partnerships/{partnershipId}` | `KIOSK_OPERATOR` | Atualiza produtos, filtros, taxas e restrições do canal |
| `POST` | `/kiosk/me/partnerships/{partnershipId}/preview` | `KIOSK_OPERATOR` | Simula valores de subtotal, comissão e líquido do quiosque |
| `POST` | `/admin/partnerships` | `ADMIN` | Cria novo canal de parceria global |
| `PUT` | `/admin/partnerships/{partnershipId}` | `ADMIN` | Ativa ou pausa canal global |
| `PATCH` | `/admin/kiosk-operators` | `ADMIN` | Associa conta de usuário existente a um quiosque (`KIOSK_OPERATOR`) |
| `POST` | `/uploads/location-photo` | Autenticado | Envia foto do guarda-sol/local para `pe-na-areia/locais` no Cloudinary |
| `POST` | `/uploads/menu-item-photo` | `KIOSK_OPERATOR` | Envia foto de produto para `pe-na-areia/cardapio` no Cloudinary |
| `POST` | `/orders` | `CLIENT` | Cria pedido na areia, grava snapshot de preços e gera cobrança Pix |
| `GET` | `/orders/available?size=50&cursor=` | `COURIER` | Lista pedidos prontos (`EM_PREPARO`) disponíveis para aceite |
| `GET` | `/orders/courier/active?size=50&cursor=` | `COURIER` | Lista entregas ativas atribuídas ao entregador |
| `GET` | `/orders/{id}` | Dono ou `COURIER` | Consulta detalhes do pedido, coordenadas, Pix e mensagens |
| `GET` | `/orders/{id}/stream` | Dono ou `COURIER` | Stream **Server-Sent Events (SSE)** em tempo real do pedido |
| `PATCH` | `/orders/{id}/status` | Dono ou `COURIER` | Avança ou cancela status do pedido conforme regras do workflow |
| `PATCH` | `/orders/{id}/courier-location` | `COURIER` atribuído | Atualiza GPS do entregador em tempo real e avalia alerta de 60m |
| `POST` | `/orders/{id}/messages` | Dono ou `COURIER` | Envia mensagem rápida contextual (`A_CAMINHO` / `CHEGOU_NO_LOCAL`) |
| `GET` | `/orders/{id}/messages` | Dono ou `COURIER` | Lista mensagens rápidas trocadas no pedido |
| `POST` | `/orders/{id}/pix-charge` | Dono (`CLIENT`) | Gera ou regenera cobrança Pix dinâmica para pedido não pago |
| `POST` | `/webhooks/pix` | Webhook (`X-Webhook-Secret`) | Confirma pagamento Pix (`txId`/`orderId`) e avança status para `PAGO` |
| `POST` | `/orders/{id}/confirm-delivery` | `COURIER` atribuído | Confirma entrega validando GPS do entregador dentro de 60m do pin |

---

## 🛡️ Observabilidade, Segurança e Qualidade

- **Logs Estruturados e Tracing:** Cada requisição HTTP emite log JSON com `requestId`, `traceId`, `spanId`, rota normalizada, status e duração (`HttpRequestLoggingFilter` + `ApplicationLayerLoggingAspect`), sem vazar payloads sensíveis ou credenciais.
- **Java 21 & Virtual Threads:** Configurado com `spring.threads.virtual.enabled=true` para alta vazão em chamadas I/O ao MongoDB, Cloudinary e gateway Pix.
- **Cobertura de Testes Automatizados:**
  - **Backend:** 227 testes JUnit 5 + JaCoCo com exigência mínima de 80% de cobertura de linhas e ramos (`.\gradlew.bat test`).
  - **Ecossistema Mobile Multi-App:** 138 testes automatizados em Dart/Flutter cobrindo o `core_shared` e os 3 aplicativos (`.\scripts\test-all.ps1`).
  - **Portal Web React:** 26 testes automatizados cobrindo validações e regras de negócio com `node:test` (`npm test`).
  - **Integração E2E HTTP:** 56 verificações contra a infraestrutura Docker isolada (`node e2e/e2e_delivery_flow.mjs`); não é automação de UI.
