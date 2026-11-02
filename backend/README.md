# Pé na Areia · Backend API 🏖️

Serviço central de backend da plataforma **Pé na Areia**, desenvolvido em **Java 21** com **Spring Boot 3.3**, banco de dados geoespacial **MongoDB 7 (Replica Set `rs0`)**, streams de dados em tempo real via **Server-Sent Events (SSE)**, integração com pagamentos **Pix (Copia e Cola / QR Code com Webhook)** e upload de mídia com **Cloudinary**.

---

## 📌 Sumário

- [Visão Geral e Arquitetura](#-visão-geral-e-arquitetura)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Estrutura de Pacotes](#-estrutura-de-pacotes)
- [Pré-requisitos](#-pré-requisitos)
- [Variáveis de Ambiente e Configuração](#-variáveis-de-ambiente-e-configuração)
- [Executando Localmente](#-executando-localmente)
- [Suíte de Testes e Cobertura JaCoCo](#-suíte-de-testes-e-cobertura-jacoco)
- [Referência de Endpoints REST](#-referência-de-endpoints-rest)
- [Regras de Negócio e Segurança](#-regras-de-negócio-e-segurança)
- [Containers e Docker Compose](#-containers-e-docker-compose)

---

## 🎯 Visão Geral e Arquitetura

O backend do Pé na Areia atua como o motor de regras de negócio, persistência geoespacial e logística de entrega de última milha na faixa de areia da orla de Santos/SP.

### Principais Pilares da Arquitetura:
1. **Java 21 & Virtual Threads (`Project Loom`):**
   Configurado com `spring.threads.virtual.enabled=true`, permitindo que operações I/O intensivas (consultas MongoDB, chamadas REST externas e streaming SSE de pedidos) rodem em threads virtuais leves de alta concorrência.
2. **Persistência Geoespacial MongoDB (GeoJSON):**
   Utiliza `GeoJsonPoint` e índices espaciais `2dsphere` para mapeamento de quiosques, postos de salvamento (Postos 1 ao 6 na orla de Santos) e cálculo de proximidade geodésica.
3. **Transações Multi-Documento:**
   Exige MongoDB em modo **Replica Set** (`rs0`) para garantir atomicidade ACID em transações críticas como criação de pedido, snapshots de preço e aceites simultâneos de entregadores.
4. **Live Tracking com Server-Sent Events (SSE):**
   Canal unidirecional persistente (`GET /orders/{id}/stream`) que transmite instantaneamente alterações de status, coordenadas de telemetria do entregador e mensagens de praia para o app do cliente.
5. **Auditoria e Observabilidade Sem Vazamento de Segredos:**
   `HttpRequestLoggingFilter` e `ApplicationLayerLoggingAspect` registram métricas estruturadas (`traceId`, `spanId`, latência em milissegundos e rota normalizada) mascarando senhas, dados de cartão ou payloads confidenciais.

---

## 💻 Tecnologias Utilizadas

- **Java 21** (Eclipse Temurin LTS)
- **Spring Boot 3.3.4**
  - `spring-boot-starter-web` (REST MVC e SSE SseEmitter)
  - `spring-boot-starter-data-mongodb` (Spring Data MongoDB & Transações)
  - `spring-boot-starter-security` (Autenticação JWT stateless e RBAC)
  - `spring-boot-starter-validation` (Bean Validation Jakarta)
  - `spring-boot-starter-actuator` & `micrometer-tracing-bridge-brave` (Métricas e Tracing distribuído)
- **MongoDB 7.0** (Configurado com Replica Set `rs0` e índices 2dsphere)
- **Cloudinary SDK** (`cloudinary-http45:1.39.0`) para armazenamento em nuvem de fotos de locais e cardápio
- **JJWT 0.12.6** (`jjwt-api`, `jjwt-impl`, `jjwt-jackson`)
- **SpringDoc OpenAPI 2.6.0** (Swagger UI e documentação interativa em `/docs`)
- **Logstash Logback Encoder 8.0** (Logs estruturados em JSON)
- **JUnit 5**, **Mockito** e **JaCoCo** (Meta de cobertura mínima de 80% de linhas e ramos)

---

## 🧩 Estrutura de Pacotes

```text
backend/src/main/java/com/penaareia/
├── config/
│   ├── ApplicationLayerLoggingAspect.java   # Aspecto AOP de tracing de métodos de serviço
│   ├── CloudinaryConfig.java                # Bean cliente Cloudinary com suporte a emulador local
│   ├── CorsConfig.java                      # Configuração dinâmica de CORS para Web e Mobile
│   ├── HttpRequestLoggingFilter.java        # Log estruturado com traceId, spanId e duração
│   ├── MongoConfig.java                     # Habilita MongoTransactionManager no replica set
│   └── OpenApiConfig.java                   # Metadados e segurança Swagger OpenAPI
├── controller/
│   ├── AdminController.java                 # Gestão global de parcerias e operadores
│   ├── AuthController.java                  # Registro e login com JWT (/auth/register e /auth/login)
│   ├── KioskController.java                 # Consulta de quiosques e canais de venda
│   ├── KioskMenuController.java             # Gestão de cardápio do quiosque (/kiosk/me/menu)
│   ├── OrderController.java                 # Workflow de pedidos, telemetria e SSE (/orders)
│   ├── PartnershipController.java           # Canais de parceria ativos
│   ├── PixWebhookController.java            # Webhook de confirmação Pix (/webhooks/pix)
│   ├── ReferencePointController.java        # Postos de salvamento na orla de Santos
│   └── UploadController.java                # Upload de fotos para Cloudinary (/uploads)
├── dto/                                     # Data Transfer Objects com anotações de validação
├── model/                                   # Documentos MongoDB e Entidades de Domínio
│   ├── Courier.java                         # Dados do entregador e status de telemetria
│   ├── Kiosk.java                           # Quiosque com endereço tradicional, geolocalização e fotos
│   ├── KioskPartnership.java                # Parceria, comissão (0-30%) e produtos elegíveis
│   ├── Order.java                           # Pedido, snapshot de itens, Pix e coordenadas
│   ├── OrderStatus.java                     # Workflow: CRIADO, PAGO, EM_PREPARO, A_CAMINHO, CHEGOU_NO_LOCAL, ENTREGUE, CANCELADO
│   ├── Partnership.java                     # Canal global de parceria
│   ├── PaymentMethod.java                   # PIX
│   ├── ReferencePoint.java                  # Postos de salvamento (Posto 1 ao 6)
│   └── User.java                            # Usuário (CLIENT, COURIER, KIOSK_OPERATOR, ADMIN)
├── repository/                              # Interfaces Spring Data MongoDB com consultas GeoJSON
├── security/                                # Filtro JWT, UserDetailsService e SecurityFilterChain
├── seed/                                    # Carga inicial de postos de referência e parcerias
└── service/                                 # Regras de negócio, transações e validações geodésicas
```

---

## ⚙️ Variáveis de Ambiente e Configuração

O arquivo [`src/main/resources/application.yml`](src/main/resources/application.yml) consome as seguintes propriedades:

| Variável | Padrão Local | Descrição |
| :--- | :--- | :--- |
| `SERVER_PORT` | `8080` | Porta TCP do serviço Spring Boot |
| `MONGODB_URI` | `mongodb://localhost:27017/pe_na_areia?replicaSet=rs0` | String de conexão MongoDB com suporte a Replica Set |
| `MONGODB_DATABASE` | `pe_na_areia` | Nome da base de dados MongoDB |
| `JWT_SECRET` | *(chave local de dev)* | Chave secreta HMAC-SHA com no mínimo 32 caracteres |
| `JWT_EXPIRATION_MS` | `86400000` (24 horas) | Tempo de vida do token de acesso em milissegundos |
| `CLOUDINARY_CLOUD_NAME` | `pe-na-areia-local` | Nome da conta Cloudinary |
| `CLOUDINARY_API_KEY` | `local-key-123456` | API Key Cloudinary |
| `CLOUDINARY_API_SECRET` | `local-secret-123456` | API Secret Cloudinary |
| `CLOUDINARY_UPLOAD_PREFIX` | `http://localhost:8099` | URL base da API Cloudinary (emulador Docker ou nuvem oficial) |
| `PIX_WEBHOOK_TOKEN` | `dev-pix-webhook-token-secret-12345` | Segredo esperado no cabeçalho `X-Webhook-Secret` |
| `APP_CORS_ORIGINS` | `http://localhost:*,http://127.0.0.1:*` | Padrões de origens CORS autorizadas |
| `DELIVERY_CONFIRMATION_RADIUS_METERS` | `60` | Distância máxima em metros para validação do Geofencing |

---

## 🚀 Executando Localmente

### Opção 1: Inicialização Completa com Docker Compose (Recomendado)
A partir da raiz do repositório:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml up --build -d
```

### Opção 2: Subir Banco + Mock no Docker e rodar a aplicação no Host
Suba apenas o MongoDB Replica Set e o emulador de Cloudinary:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml up -d mongodb cloudinary-mock
```

Em seguida, execute no terminal do backend:

```powershell
Set-Location backend
.\gradlew.bat bootRun
```

A API estará disponível em:
- **Base URL:** `http://localhost:8080`
- **Swagger UI:** `http://localhost:8080/docs`
- **OpenAPI JSON:** `http://localhost:8080/api-docs`
- **Healthcheck Actuator:** `http://localhost:8080/actuator/health`

---

## 🧪 Suíte de Testes e Cobertura JaCoCo

O backend possui uma suíte robusta de testes unitários, testes de repositório geoespacial e testes de integração com MockMvc e Spring Security:

```powershell
Set-Location backend

# Executa todos os testes unitários e de integração
.\gradlew.bat test

# Gera o relatório de cobertura JaCoCo e valida limites mínimos
.\gradlew.bat check jacocoTestReport
```

> [!NOTE]
> O build do Gradle está configurado com `jacocoTestCoverageVerification` exigindo no mínimo **80% de cobertura de linhas (`LINE`)** e **80% de ramos (`BRANCH`)**. O relatório HTML detalhado é gerado em `backend/build/reports/jacoco/test/html/index.html`.

---

## 📡 Referência de Endpoints REST

### Autenticação & Identidade
- `POST /auth/register` — Cadastro de clientes (`CLIENT`) e entregadores (`COURIER`) com retorno de JWT.
- `POST /auth/login` — Autenticação de usuários cadastrados e devolução de perfil (`roles`).

### Quiosques, Parcerias & Cardápio
- `GET /partnerships` — Listagem de canais de venda ativos.
- `GET /kiosks?partnershipId={id}` — Quiosques ativos e cardápios vinculados ao canal.
- `GET /kiosks/{id}/partnerships` — Canais e taxas específicas de um quiosque.
- `GET /kiosk/me/menu` — Cardápio completo do quiosque autenticado (`KIOSK_OPERATOR`).
- `POST /kiosk/me/menu` — Cadastro de novo item com upload de foto e categoria.
- `PUT /kiosk/me/menu/{itemId}` — Atualização cadastral de produto.
- `DELETE /kiosk/me/menu/{itemId}` — Exclusão lógica ou física de item do catálogo.
- `POST /kiosk/me/partnerships/{id}/preview` — Simulador de repasse e comissão.

### Pedidos & Logística na Praia
- `POST /orders` — Criação do pedido com coordenadas do guarda-sol na areia, snapshot de preço e cobrança Pix.
- `GET /orders/available` — Fila de pedidos prontos (`EM_PREPARO`) para aceite por entregadores (`COURIER`).
- `GET /orders/courier/active` — Entregas ativas atribuídas ao entregador conectado.
- `GET /orders/{id}` — Detalhes completos do pedido, pin no mapa, dados Pix e mensagens.
- `GET /orders/{id}/stream` — Stream em tempo real via **Server-Sent Events (SSE)**.
- `PATCH /orders/{id}/status` — Atualização da máquina de estados do pedido.
- `PATCH /orders/{id}/courier-location` — Envio contínuo de coordenadas GPS do entregador.
- `POST /orders/{id}/messages` — Envio de mensagem rápida de praia (*"A maré subiu"*, *"Sinalizador ativo"*).
- `GET /orders/{id}/messages` — Histórico de mensagens rápidas do pedido.
- `POST /orders/{id}/confirm-delivery` — Confirmação de entrega validada por Geofencing (raio <= 60m).

### Uploads & Webhooks
- `POST /uploads/location-photo` — Upload seguro da foto do guarda-sol do cliente no Cloudinary.
- `POST /uploads/menu-item-photo` — Upload de fotos de produtos e logomarcas de quiosques.
- `POST /webhooks/pix` — Webhook protegido por segredo para liquidação instantânea de pagamentos.

---

## 🔒 Regras de Negócio e Segurança

1. **Validação de Geofencing a 60 Metros:**
   O endpoint `POST /orders/{id}/confirm-delivery` calcula a distância geodésica entre a coordenada GPS informada pelo entregador e a coordenada original do pin do guarda-sol do cliente. Se a distância for superior a 60 metros, o pedido não é finalizado e retorna erro `400 BAD_REQUEST`.
2. **Snapshot de Preços e Taxas:**
   Ao submeter um pedido, o backend grava uma cópia imutável dos itens, preços unitários e taxas de entrega no documento do pedido, garantindo que reajustes posteriores no cardápio do quiosque não afetem pedidos em andamento.
3. **Máquina de Estados Estrita:**
   Transições de status seguem o fluxo `CRIADO` ➔ `PAGO` ➔ `EM_PREPARO` ➔ `A_CAMINHO` ➔ `CHEGOU_NO_LOCAL` ➔ `ENTREGUE` (ou `CANCELADO` antes do início do preparo).
4. **Proteção de Webhook:**
   O endpoint `/webhooks/pix` exige o cabeçalho `X-Webhook-Secret` correspondente ao valor configurado em `PIX_WEBHOOK_TOKEN`.

