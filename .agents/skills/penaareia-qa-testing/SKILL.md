---
name: penaareia-qa-testing
description: >-
  Matriz de testes automatizados e critérios de qualidade do Pé na Areia: testes unitários e de integração no backend,
  testes de widgets no Flutter e testes E2E com simulação do ciclo de entrega na praia.
---

# Skill: Matriz de Testes & QA (Pé na Areia)

Plano e rotina de execução da garantia de qualidade para a plataforma Pé na Areia.

## 1. Testes de Backend (Java 21 + Spring Boot)
- **Frameworks:** JUnit 5, Mockito, AssertJ, MockMvc.
- **Execução:**
  ```powershell
  cd backend
  ./gradlew test
  ```
- **Portão de Cobertura:**
  ```powershell
  ./gradlew jacocoTestCoverageVerification
  ```
  Falha automaticamente se a cobertura for inferior a 80%.

## 2. Testes Mobile (Flutter)
- **Frameworks:** `flutter_test`, mocks de repositório.
- **Execução:**
  ```powershell
  flutter test packages/core_shared
  flutter test apps/app_cliente
  flutter test apps/app_entregador
  flutter test apps/app_prototipo
  ```

## 3. Testes Web (React 19)
- **Frameworks:** Vitest, Node test runner.
- **Execução:**
  ```powershell
  cd web
  npm test
  ```

## 4. Testes Ponta a Ponta (E2E)
- **Execução:**
  ```powershell
  node e2e/e2e_delivery_flow.mjs
  ```
- Cobre o ciclo integral: cliente cria pedido na areia -> pagamento -> quiosque prepara -> entregador caminha -> PIN de 4 dígitos validado com geofencing de 60m -> entrega confirmada -> avaliação 5 estrelas.
