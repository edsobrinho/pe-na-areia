# AGENTS.md — Guia Operacional de Agentes: Projeto Pé na Areia

Bem-vindo ao repositório do **Pé na Areia**, a plataforma de delivery hiperlocal na faixa de areia da orla de Santos - SP. Este documento serve como manual operacional, conjunto de regras de workspace e catálogo de agentes especialistas que atuam de forma coordenada no projeto.

---

## 1. Visão Geral e Contexto de Negócio

O **Pé na Areia** resolve a complexidade logística de entregar comidas e bebidas geladas diretamente ao banhista na praia.
* **Cliente na Areia:** Localiza-se via GPS, seleciona ponto de referência (número do canal, posto de bombeiros, cor do guarda-sol), faz o pedido, paga via Pix antecipado, acompanha a rota em tempo real e aciona o **Farol Visual (SignalBeacon)** com cor e pulso para guiar o entregador.
* **Código de Entrega de 4 Dígitos (PIN OTP):** Na finalização do pedido, é gerado um código numérico de 4 dígitos exclusivo. O cliente dita verbalmente esse código ao entregador no momento do encontro na areia.
* **Entregador na Praia:** Utiliza o radar pedestre, caminha até o local indicado e digita o PIN informado pelo cliente. A entrega só é confirmada se o código for válido e se o entregador estiver dentro do **raio de geofencing de 60 metros** do cliente.
* **Avaliação Pós-Entrega:** O cliente avalia de 1 a 5 estrelas o pedido e o entregador, com comentário opcional, alimentando as métricas de reputação dos quiosques.
* **Quiosques & Administrador:** Acompanham pedidos em tempo real, gerenciam cardápio com fotos e monitoram faturamento e avaliações nos portais web.

---

## 2. Arquitetura da Solução & Monorepo

O repositório é estruturado no formato Monorepo multi-camadas:

```text
pe-na-areia/
├── backend/                       # API REST Spring Boot 3.3.4 + Java 21 LTS + MongoDB
│   ├── src/main/java/com/penaareia/
│   │   ├── controller/            # Controllers REST (Order, Kiosk, Admin, Telemetry)
│   │   ├── service/               # Regras de negócio, geofencing e workflow
│   │   ├── repository/            # Repositórios Spring Data MongoDB
│   │   ├── model/                 # Entidades de domínio (Order, Kiosk, Review, etc.)
│   │   └── dto/                   # Records imutáveis de entrada/saída
│   └── src/main/resources/        # application.yml e logback-spring.xml (JSON structured)
├── apps/                          # Apps móveis Flutter 3.24+ / Dart 3.5+
│   ├── app_cliente/               # App do Cliente na areia (com.penaareia.cliente)
│   ├── app_entregador/            # App do Entregador/Courier (com.penaareia.entregador)
│   └── app_prototipo/             # Protótipo executável do produto (com.penaareia.prototipo)
├── packages/
│   └── core_shared/               # Design System (Sage & Apricot), models, repositórios e utils
├── web/                           # Portal do Parceiro e Painel Admin (React 19 + TypeScript + Vite)
├── scripts/                       # Scripts de automação (build-all.ps1)
├── dist-mobile/                   # APKs compilados para distribuição Android
└── docker-compose.yml             # Orquestração do Backend, MongoDB (rs0) e Mock Cloudinary
```

---

## 3. Regras de Ouro e Diretrizes do Workspace

Toda modificação realizada por qualquer agente deve seguir estritamente estas diretrizes:

1. **Segredo do Código de Entrega (PIN OTP):**
   - O `codigoEntrega` de 4 dígitos **nunca** pode ser revelado ao entregador antes da confirmação verbal na areia.
   - O backend mascara esse campo nos endpoints consumidos pelo entregador até que o pedido atinja o status `ENTREGUE`.
   - Nunca logar o código de entrega em texto puro nos logs do sistema.
2. **Geofencing de Segurança na Areia (60 metros):**
   - A confirmação de entrega exige validação das coordenadas do entregador em relação às coordenadas salvas do cliente (`distanceMeters <= 60.0`).
3. **Resiliência Multiplataforma dos Mapas:**
   - Em aplicações Flutter Web, nunca instancie `GoogleMap` diretamente sem checar `GoogleMapsChecker.isReady`.
   - Se o script JS do Google Maps não estiver carregado ou for bloqueado, o fallback temático visual (`_buildMapFallback`) deve ser acionado sem gerar tela vermelha de crash.
4. **Padrão de Logs Estruturados em JSON:**
   - Todos os logs do backend utilizam SLF4J com LogstashEncoder.
   - Cada linha deve conter MDC com `requestId` e `traceId`.
   - **Zero dados sensíveis:** Proibido logar CPF, telefone, senhas, tokens JWT, dados de cartão ou dados biométricos.
5. **Compatibilidade Android & Gradle:**
   - Flutter SDK moderno exige Gradle `>= 8.14.0` (utilizamos Gradle `8.14.6` com AGP `8.13.2` e Kotlin `2.3.20`).
   - Mantenha `namespace` e declaração de pacote do `MainActivity.kt` alinhados para evitar `ClassNotFoundException`.

---

## 4. Elenco de Agentes Especialistas

Cada agente possui escopo e responsabilidades bem delineadas dentro do ciclo de vida do Pé na Areia:

### 4.1. `agente-backend-java21-spring`
- **Foco:** Desenvolvimento e evolução da API REST em Java 21 e Spring Boot 3.3.4.
- **Responsabilidades:**
  - Implementar controllers, services e repositórios MongoDB.
  - Manter transições da máquina de estados do pedido (`OrderStatus`).
  - Assegurar cobertura de testes JaCoCo $\ge$ 80% (linhas e branches).
  - Tratar exceções com `ProblemDetail` (RFC 9457).
  - Configurar Virtual Threads (`spring.threads.virtual.enabled=true`).

### 4.2. `agente-dev-java-21`
- **Foco:** Aplicação dos recursos idiomáticos modernos do Java 21 LTS.
- **Responsabilidades:**
  - Uso de `record` para todos os DTOs de transporte.
  - Pattern Matching para `switch` e `instanceof`.
  - Sequenced Collections (`getFirst()`, `getLast()`, `reversed()`).
  - Text Blocks (`"""..."""`) para queries e templates.
  - Concorrência de alta vazão sem gargalos de *pinning* de threads.

### 4.3. `agente-padronizacao-logs-camadas-java21`
- **Foco:** Observabilidade, padronização de eventos e segurança contra vazamento de dados.
- **Responsabilidades:**
  - Padronizar logs em formato JSON nas camadas Controller, Service e Repository.
  - Nomes de evento em `snake_case` (`<camada>_<acao>_<resultado>`).
  - Uso de `INFO` para fluxo normal, `WARN` para regras de negócio rejeitadas pelo cliente (4xx) e `ERROR` para falhas do sistema (5xx).
  - Sanitização de dados pessoais e mascaramento centralizado.

### 4.4. `agent-frontend-flutter-mobile`
- **Foco:** Ecossistema mobile Multi-App (`app_cliente`, `app_entregador`, `app_prototipo` e `packages/core_shared`).
- **Responsabilidades:**
  - Garantir fidelidade visual ao Design System oficial **"Brisa Minimalista — Sage & Apricot"** (`AppColors`, `AppTheme`).
  - Implementar telas do cliente: seleção de quiosque, pino na areia, farol visual e diálogo de avaliação (1 a 5 estrelas).
  - Implementar telas do entregador: radar da praia, input do PIN de entrega e fallback gracioso do Google Maps.
  - Validar builds Android com Gradle 8.14 e saídas para `dist-mobile/`.

### 4.5. `agent-frontend-react`
- **Foco:** Portal do Parceiro e Painel Administrativo em `web/` (React 19+, TypeScript, Vite, Tailwind CSS).
- **Responsabilidades:**
  - Construir interfaces web performáticas, acessíveis e tipadas estritamente com TypeScript e Zod.
  - Desenvolver o Kanban de pedidos da orla com atualizações em tempo real (SSE).
  - Exibir badges de confirmação de entrega com código e feed de avaliações dos clientes no dashboard.
  - Gestão de cardápio com upload assíncrono para o Cloudinary.

### 4.6. `agents-test-qa`
- **Foco:** Garantia da qualidade, suites de testes e validação ponta a ponta (E2E).
- **Responsabilidades:**
  - Executar e auditar testes unitários e de integração no backend com JUnit 5, Mockito e MockMvc.
  - Executar testes de widgets e repositórios no Flutter com `flutter test`.
  - Executar a automação E2E (`node e2e/e2e_delivery_flow.mjs`) cobrindo o fluxo completo de compra, aceitação, código de 4 dígitos, confirmação de entrega e avaliação.

### 4.7. `java21-code-review-and-quality`
- **Foco:** Auditoria multidimensional de código e portão de qualidade.
- **Responsabilidades:**
  - Revisar código sob as 5 dimensões: Correção, Legibilidade, Arquitetura, Segurança e Performance.
  - Seguir regras alinhadas ao SonarQube, Checkstyle e SpotBugs.
  - Garantir 0 warnings no `flutter analyze` e no linter do React.

---

## 5. Comandos de Verificação Rápida

| Componente | Comando | Objetivo |
| :--- | :--- | :--- |
| **Backend** | `./gradlew test` (na pasta `backend`) | Executar todos os testes com JUnit 5 |
| **Backend Coverage** | `./gradlew jacocoTestReport` | Gerar relatório de cobertura (mínimo 80%) |
| **Mobile Flutter** | `flutter analyze apps/app_cliente` | Análise estática do app do cliente |
| **Mobile Entregador** | `flutter analyze apps/app_entregador` | Análise estática do app do entregador |
| **Mobile Build All** | `powershell -File .\scripts\build-all.ps1` | Compilar release APKs dos 3 apps para `dist-mobile/` |
| **Web React** | `npm run build` (na pasta `web`) | Compilação TypeScript e bundle Vite |
| **Web Lint** | `npm run lint` (na pasta `web`) | Linter rápido do frontend web |
| **Docker Stack** | `docker compose up -d` | Subir MongoDB (rs0), Mock Cloudinary e Backend |
| **Fluxo E2E** | `node e2e/e2e_delivery_flow.mjs` | Teste E2E do ciclo completo de entrega |

---

## 6. Localização dos Artefatos de Configuração

* Agentes customizados: `.agents/agents/*.agent.md`
* Skills de procedimentos: `.agents/skills/<skill-name>/SKILL.md`
* Manual de skills: `SKILL.md`
