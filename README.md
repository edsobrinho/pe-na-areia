# Pé na Areia 🏖️

Plataforma full-stack de pedidos e logística de última milha para entrega na faixa de areia da orla de Santos/SP. O cliente escolhe produtos com foto de quiosques parceiros, paga antecipadamente via **Pix Copia e Cola / QR Code**, fixa o **pin exato do seu guarda-sol no mapa** e utiliza o **Farol Visual de Tela Cheia** quando o entregador se aproxima; o entregador navega pela areia usando o **Modo Bússola / Radar Pedestre**, transmite sua localização em tempo real e confirma a entrega validada por GPS (raio de 60 metros).

Leia os documentos de produto para detalhes de arquitetura e regras de negócio:
- [PRD Principal v2.0](PRD.md) — Logística na faixa de areia, Farol Visual, Radar Pedestre, Live Tracking SSE, Canal Rápido e Pix com Webhook.
- [PRD v1.1 — Parcerias e Gestão de Cardápio por Quiosque](PRD-v1.1-parcerias-quiosques.md) — CRUD de cardápio com fotos, canais de venda, comissões e snapshot de preços.

---

## Estrutura do Repositório

```text
pe-na-areia/
├── backend/                     # Java 21, Spring Boot 3.3, MongoDB GeoJSON, SSE, JWT, Pix e Cloudinary
├── frontend/                    # App Mobile Flutter 3.29+ (Cliente e Entregador)
├── web/                         # Portal Web React 19 + TypeScript + Vite (Cliente, Operador e Admin)
├── infrastructure/              # Docker Compose (MongoDB rs0, Cloudinary Mock e Backend)
│   ├── docker-compose.yml
│   └── cloudinary-mock/         # Emulador local compatível com o SDK oficial do Cloudinary
└── e2e/
    └── e2e_delivery_flow.mjs    # Suíte End-to-End automatizada (44 asserções full-stack)
```

---

## Principais Funcionalidades Implementadas

### 1. Para Clientes (App Flutter e Portal Web)
- **Autenticação e Validações:** Cadastro e login JWT (`CLIENT`) com validação e máscaras de entrada (e-mail, nome, senha, telefone brasileiro `(XX) XXXXX-XXXX` e limite de 140 caracteres na descrição do ponto).
- **Catálogo Visual por Parceria:** Escolha do canal de venda (`partnershipId`), visualização de quiosques ativos e cardápios com **fotos reais dos produtos (`fotoUrl`)**, filtro de disponibilidade e preferência por embalagem sustentável/retornável.
- **Pin Interativo na Faixa de Areia:** Seleção do ponto exato no Google Maps, sugestão automática do Posto de Salvamento mais próximo (validado até 500 m no servidor), descrição textual do guarda-sol e upload de foto do local (`POST /uploads/location-photo`).
- **Pagamento Antecipado Pix ("Zero Dinheiro na Areia"):** Geração automática de **Pix Copia e Cola** (payload EMV BR Code), QR Code e identificador de transação (`pixTxId`), com atualização via Webhook (`POST /webhooks/pix`).
- **Live Tracking em Tempo Real e Alerta de 60m:** Acompanhamento da posição do entregador via **Server-Sent Events (`GET /orders/{id}/stream`)** e cálculo de distância restante. Quando o entregador entra no raio de **60 metros**, o cliente recebe alerta imediato (*"🏖️ Seu entregador está na areia a menos de 60m! Saia do mar e ative o Sinalizador"*).
- **🔦 Farol Visual Inteligente de Tela Cheia (`SignalBeaconScreen`):** Botão habilitado automaticamente quando o status do pedido é `CHEGOU_NO_LOCAL` **ou** quando está `A_CAMINHO` a **`<= 60 metros`**. Ao tocar, o celular entra em tela cheia imersiva alternando cores solares de alto contraste (**Laranja Neon `#FF7A3D`**, **Amarelo Solar `#FFD600`** e **Branco**), com cronômetro regressivo de 3 minutos e código curto do pedido para localização imediata na multidão.
- **💬 Canal Rápido de Contato na Praia:** Atalhos de 1 toque (*"🌊 A maré subiu, mudei alguns metros para trás"*, *"🔦 Estou levantando o Sinalizador na tela"*) e botão direto para **WhatsApp** com mensagem pré-formatada, habilitados exclusivamente enquanto o pedido está `A_CAMINHO` ou `CHEGOU_NO_LOCAL`.

### 2. Para Entregadores (App Flutter)
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

## Infraestrutura Local em Docker (MongoDB + Cloudinary Mock + Backend)

Requisitos: **Docker** com **Docker Compose v2**.

A infraestrutura local sobe três containers orquestrados com healthchecks:
1. **`mongodb` (`mongo:7`)**: Replica Set de nó único (`rs0`) na porta `27017`, necessário para transações multi-documento do Spring Data MongoDB.
2. **`cloudinary-mock` (`node:22-alpine`)**: Servidor local na porta `8099` 100% compatível com o SDK oficial `cloudinary-http44` do Java (`POST /v1_1/:cloudName/image/upload` e `GET /:cloudName/image/upload/v1/...`), permitindo testar uploads de fotos do local e do cardápio sem depender de conta externa na nuvem.
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

Com os containers Docker rodando, execute a suíte E2E completa (que valida cadastro, parceria, upload de foto no Cloudinary Docker, criação de pedido com Pix, Live Tracking na areia, alerta de 60m, mensagens rápidas, geofencing de entrega e CRUD de cardápio com foto):

```powershell
node e2e/e2e_delivery_flow.mjs
```

Resultado esperado: `PASS: 44  FAIL: 0`.

---

## Executando Cada Camada em Desenvolvimento

### 1. Backend (Java 21 + Spring Boot)

Para rodar o backend diretamente no host (com `mongodb` e `cloudinary-mock` no Docker):

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

### 2. App Mobile (Flutter 3.29+)

Consulte o [README do Frontend](frontend/README.md) para detalhes de configuração da chave do Google Maps em Android/iOS.

```powershell
Set-Location frontend
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

#### 📱 Como Gerar o `.apk` e Instalar Manualmente no Celular Físico (Mesmo Wi-Fi + DNS Local + Docker)

Para testar o aplicativo diretamente no seu smartphone físico conectado na mesma rede Wi-Fi da máquina de desenvolvimento, siga os **4 passos** abaixo:

##### Passo 1 — Descobrir o IP do Wi-Fi e Definir o DNS de Rede Local (`sslip.io`)
Descubra o IPv4 da placa Wi-Fi do seu computador no PowerShell:

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" } | Select-Object InterfaceAlias, IPAddress
```

Supondo que o IP retornado seja `192.168.0.3`, utilize o serviço gratuito de DNS curinga **`sslip.io`** (que resolve automaticamente qualquer domínio contendo seu IP local para o próprio IP na rede Wi-Fi, sem precisar alterar o roteador):
- **DNS do Backend:** `http://api.pe-na-areia.192.168.0.3.sslip.io:8080`
- **DNS do Cloudinary Docker:** `http://cdn.pe-na-areia.192.168.0.3.sslip.io:8099`

*(Alternativamente, se o seu roteador possuir **LAN DNS / Host Override**, você pode apontar um domínio como `api.penaareia.lan` para `192.168.0.3`).*

##### Passo 2 — Liberar as Portas `8080` e `8099` no Firewall do Windows
Abra o **PowerShell como Administrador** uma única vez para permitir conexões de entrada do celular na rede local:

```powershell
New-NetFirewallRule -DisplayName "Pe na Areia Docker LAN" -Direction Inbound -LocalPort 8080,8099 -Protocol TCP -Action Allow
```

##### Passo 3 — Subir o Docker com o DNS da Rede Wi-Fi
Na raiz do projeto, suba os containers configurando a URL pública das imagens (`CLOUDINARY_PUBLIC_BASE_URL`) e as origens de CORS (`APP_CORS_ORIGINS`):

```powershell
$env:CLOUDINARY_PUBLIC_BASE_URL="http://cdn.pe-na-areia.192.168.0.3.sslip.io:8099"
$env:APP_CORS_ORIGINS="http://localhost:*,http://127.0.0.1:*,http://*.sslip.io:*,http://192.168.*:*"
docker compose -f infrastructure/docker-compose.yml up -d
```

> **Teste rápido no navegador do celular:** Com o celular no mesmo Wi-Fi, acesse `http://api.pe-na-areia.192.168.0.3.sslip.io:8080/reference-points`. Se retornar o JSON dos postos (`HTTP 200`), a comunicação Wi-Fi + DNS + Docker está pronta.

##### Passo 4 — Compilar o `.apk` com o DNS Embutido e Instalar no Celular
O `AndroidManifest.xml` já está configurado com `android:usesCleartextTraffic="true"` e o Gradle Wrapper com `gradle-8.10.2-all.zip`. Para gerar o instalador `.apk` apontando para o seu DNS local:

```powershell
Set-Location frontend
flutter build apk --release --dart-define=API_BASE_URL=http://api.pe-na-areia.192.168.0.3.sslip.io:8080
```

O arquivo final será gerado em:
`frontend/build/app/outputs/flutter-apk/app-release.apk`

**Formas de instalação manual no celular:**
1. **Via Cabo USB / ADB:**
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```
2. **Sem Cabo (WhatsApp / Google Drive / Telegram):** Envie o arquivo `app-release.apk` para o celular, toque nele para instalar e autorize *"Instalar de fontes desconhecidas"*.

### 3. Portal Web (React 19 + TypeScript + Vite)

Consulte o [README do Portal Web](web/README.md) para o guia completo de variáveis de ambiente e perfis de acesso.

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

## Referência Completa de Endpoints da API

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

## Observabilidade, Segurança e Qualidade

- **Logs Estruturados e Tracing:** Cada requisição HTTP emite log JSON com `requestId`, `traceId`, `spanId`, rota normalizada, status e duração (`HttpRequestLoggingFilter` + `ApplicationLayerLoggingAspect`), sem vazar payloads sensíveis ou credenciais.
- **Java 21 & Virtual Threads:** Configurado com `spring.threads.virtual.enabled=true` para alta vazão em chamadas I/O ao MongoDB, Cloudinary e gateway Pix.
- **Cobertura de Testes Automatizados:**
  - **Backend:** JUnit 5 + JaCoCo com exigência mínima de 80% de cobertura (`.\gradlew.bat test`).
  - **Frontend Flutter:** 124 testes unitários e de widget cobrindo modelos, mappers, validações, bússola geodésica e farol visual (`flutter test`).
  - **Portal Web React:** 26 testes automatizados cobrindo validações, máscaras e regras de negócio (`npm test`).
  - **E2E Full-Stack:** 44 verificações integradas contra os containers Docker (`node e2e/e2e_delivery_flow.mjs`).
