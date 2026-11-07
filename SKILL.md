---
name: penaareia-skills
description: >-
  Manual central de skills e runbooks operacionais do projeto Pé na Areia.
  Utilize esta skill para consultar procedimentos passo a passo de build, execução de testes,
  fluxo de entrega na areia com código de 4 dígitos e geofencing de 60m, builds mobile Flutter,
  gestão de logs estruturados e portais web React.
---

# Pé na Areia: Central de Skills & Runbooks Operacionais

Este documento consolida as habilidades operacionais e procedimentos passo a passo para o desenvolvimento, compilação, testes e sustentação da plataforma **Pé na Areia**.

---

## 1. Skill: Operação do Backend (Java 21 + Spring Boot 3.3 + MongoDB)

### Quando usar
Ao implementar novos endpoints, alterar serviços de domínio, executar migrações de dados ou rodar o backend localmente.

### Procedimentos

#### 1.1. Inicialização dos Serviços de Apoio (Docker)
Antes de iniciar a API, garanta que o MongoDB com Replica Set (`rs0`) e o Mock do Cloudinary estejam em execução:
```powershell
docker compose up -d mongodb cloudinary-mock
```
*Verificação:*
```powershell
docker compose ps
# O serviço 'mongodb' deve exibir status 'healthy' na porta 27017.
# O serviço 'cloudinary-mock' deve responder na porta 8099.
```

#### 1.2. Execução Local da API
```powershell
cd backend
./gradlew bootRun
```
*Verificação:*
- A API estará disponível em: `http://localhost:8080`
- Swagger UI (OpenAPI 3): `http://localhost:8080/swagger-ui.html`
- Healthcheck Actuator: `http://localhost:8080/actuator/health`

#### 1.3. Execução de Testes e Cobertura JaCoCo (Mínimo 80%)
```powershell
cd backend
./gradlew test jacocoTestReport jacocoTestCoverageVerification
```
*Critério de Aceite:*
- 100% dos testes unitários e de integração passando.
- Cobertura de linhas $\ge$ 80% (o build falha caso a métrica não seja atingida).
- Relatório HTML gerado em: `backend/build/reports/jacoco/test/html/index.html`.

---

## 2. Skill: Ciclo de Vida Flutter Multi-App & Builds Mobile

### Quando usar
Ao desenvolver recursos nos apps (`app_cliente`, `app_entregador`, `app_prototipo`), atualizar o design system em `packages/core_shared` ou compilar novos APKs.

### Procedimentos

#### 2.1. Análise Estática de Código (Zero Warnings)
Execute a análise estática em cada aplicativo para garantir conformidade de tipagem e boas práticas:
```powershell
flutter analyze packages/core_shared
flutter analyze apps/app_cliente
flutter analyze apps/app_entregador
flutter analyze apps/app_prototipo
```

#### 2.2. Execução dos Testes Mobile
```powershell
flutter test packages/core_shared
flutter test apps/app_cliente
flutter test apps/app_entregador
flutter test apps/app_prototipo
```

#### 2.3. Compilação Release dos Três Apps para `dist-mobile/`
O projeto conta com script automatizado em PowerShell que alinha o Gradle 8.14+, compila com a URL da API configurada e copia os artefatos finais:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-all.ps1 -ApiBaseUrl "http://192.168.0.4:8080"
```
*Artefatos gerados:*
- `dist-mobile/cliente/pe-na-areia-cliente.apk`
- `dist-mobile/entregador/pe-na-areia-entregador.apk`
- `dist-mobile/prototipo/pe-na-areia-prototipo.apk`

---

## 3. Skill: Validação do Fluxo de Entrega na Praia (PIN de 4 Dígitos & Geofencing)

### Quando usar
Para testar, validar ou demonstrar o ciclo de vida completo de um pedido na praia.

### Ciclo Operacional

```text
[Cliente]              [Quiosque / Admin]               [Entregador]
   │                           │                             │
   ├─ 1. Cria Pedido ─────────►│                             │
   │  (Gera PIN 4 dígitos)     ├─ 2. Aceita / Em Preparo     │
   │                           │                             │
   │                           ├─ 3. Aguarda Entregador ────►│
   │                                                         ├─ 4. Aceita Entrega
   │                                                         │  (A Caminho)
   │                           5. Encontro na Areia          │
   ├────── Informa PIN ─────────────────────────────────────►│
   │       verbalmente                                       ├─ 6. Digita PIN
   │                                                         │  (Valida Geofencing 60m)
   │◄───── Confirmação da Entrega (Status ENTREGUE) ─────────┤
   │
   ├─ 7. Avalia Pedido (1 a 5 estrelas) ────────────────────►│ (Atualiza score do quiosque)
```

#### Execução Automatizada via Teste E2E:
```powershell
node e2e/e2e_delivery_flow.mjs
```
*Validações do Script:*
1. Criação do pedido com coordenadas na praia de Santos (-23.9723, -46.3271).
2. Obtenção do `codigoEntrega` de 4 dígitos gerado pelo backend.
3. Avanço para `EM_PREPARO` e `AGUARDANDO_ENTREGADOR`.
4. Aceite pelo entregador e envio de telemetria contínua.
5. Chamada de `POST /orders/{id}/confirm-delivery` enviando `codigoEntrega` e localização a menos de 60m.
6. Envio de avaliação via `POST /orders/{id}/review` com nota 5 e comentário.
7. Verificação da nota atualizada nas métricas do Quiosque e do Admin.

---

## 4. Skill: Operação do Portal Web (React 19 + TypeScript + Vite)

### Quando usar
Ao implementar novas visões no Portal do Parceiro (`web/src/components/PartnerOrdersManager.tsx`), no Painel do Administrador (`web/src/components/AdminPanel.tsx`) ou no gestor de cardápio (`KioskMenuManager.tsx`).

### Procedimentos

#### 4.1. Instalação e Execução em Desenvolvimento
```powershell
cd web
npm install
npm run dev
```
*Acesso:* `http://localhost:5173`

#### 4.2. Linting Rápido com Oxlint e Testes com Vitest
```powershell
cd web
npm run lint
npm test
```

#### 4.3. Build de Produção
```powershell
cd web
npm run build
```
*Verificação:* A pasta `web/dist` será gerada com os assets minificados e sem erros de tipagem TypeScript.

---

## 5. Skill: Observabilidade e Auditoria de Logs JSON

### Quando usar
Ao auditar ou inspecionar requisições, diagnosticar erros em produção ou verificar conformidade contra vazamento de dados sensíveis.

### Diretrizes de Inspeção

1. **Formato Obrigatório:** As linhas de log no console/arquivo devem ser emitidas como objetos JSON válidos:
   ```json
   {
     "timestamp": "2026-11-07T17:40:00.123Z",
     "level": "INFO",
     "logger": "com.penaareia.service.OrderWorkflowService",
     "message": "pedido_entrega_confirmada",
     "service": "pe-na-areia-backend",
     "requestId": "req-98f2b1a0",
     "traceId": "trace-40182",
     "orderId": "672c10b0a8",
     "distanceMeters": 14.2
   }
   ```
2. **Auditoria de Dados Sensíveis:**
   - Execute varreduras para garantir que campos proibidos (`password`, `senha`, `cpf`, `token`, `codigoEntrega`) nunca sejam expostos em texto aberto.
   - O `logback-spring.xml` possui filtros automáticos de exclusão (`excludeKeyValueKeyName`).

---

## 6. Skill: Resolução de Falhas Comuns (Troubleshooting)

### Falha: `Cannot read properties of undefined (reading 'maps')` no Flutter Web
* **Causa:** O Google Maps JS SDK não foi carregado no navegador.
* **Ação:** O widget deve invocar `GoogleMapsChecker.isReady`. Se for `false`, exibe o fallback `_buildMapFallback` com a bússola/radar da praia e coordenadas.

### Falha: `ClassNotFoundException: Didn't find class com.penaareia.*.MainActivity` no Android
* **Causa:** Desalinhamento entre o `namespace` em `build.gradle.kts` e a pasta/declaração de pacote do `MainActivity.kt`.
* **Ação:** Garantir que o arquivo `MainActivity.kt` resida em `android/app/src/main/kotlin/com/penaareia/<app>/MainActivity.kt` com `package com.penaareia.<app>`.

### Falha: `Your project's Gradle version is lower than Flutter's minimum supported version of 8.14.0`
* **Causa:** Versão desatualizada do Gradle Wrapper.
* **Ação:** No arquivo `android/gradle/wrapper/gradle-wrapper.properties`, defina:
  `distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.6-all.zip`.
