---
name: penaareia-observability-logs
description: >-
  Diretrizes e procedimentos para padronização de logs JSON estruturados, correlação com MDC (requestId, traceId)
  e proteção absoluta contra vazamento de dados pessoais nas camadas Controller, Service e Repository no backend Pé na Areia.
---

# Skill: Observabilidade e Logs Estruturados (Java 21 + Spring Boot 3.3)

Procedimentos para garantir rastreabilidade, diagnóstico de incidentes e conformidade de privacidade nos logs do Pé na Areia.

## Princípios de Logging
1. **Logs 100% Estruturados em JSON:** Emitidos via LogstashEncoder e capturados pelo console Docker.
2. **Propagação de Contexto (MDC):**
   - Todo log carrega automaticamente `service="pe-na-areia-backend"`, `requestId`, `traceId` e `spanId`.
3. **Nomenclatura de Eventos Estável:**
   - Formato `snake_case`: `<entidade>_<acao>_<resultado>`.
   - Exemplos: `pedido_criado`, `pedido_em_preparo`, `pedido_entrega_confirmada`, `pedido_geofence_violado`.

## Níveis por Gravidade
- **INFO:** Fluxo regular de negócio (criação de pedido, aceitação, confirmação de entrega).
- **WARN:** Violações de regra de negócio causadas pelo cliente/usuário (ex.: PIN incorreto, entregador fora do raio de 60m, quiosque fechado).
- **ERROR:** Erros de infraestrutura, falha de comunicação com MongoDB, indisponibilidade do Cloudinary.

## Proteção Absoluta contra Vazamento de Dados Sensíveis
O arquivo `backend/src/main/resources/logback-spring.xml` já possui exclusões ativas. Contudo, em código:
- **Nunca logar:**
  - Código de entrega de 4 dígitos (`codigoEntrega`) digitado ou gerado.
  - CPF ou dados de pagamento Pix.
  - Senhas, hashes ou tokens JWT no header `Authorization`.
  - Coordenadas GPS privadas fora da orla da praia.
