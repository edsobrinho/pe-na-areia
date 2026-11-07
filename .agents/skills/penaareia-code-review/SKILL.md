---
name: penaareia-code-review
description: >-
  Checklist e critérios para revisão de código e auditoria de qualidade no Pé na Areia,
  abrangendo Java 21, Spring Boot 3.3, Flutter Multi-App, React 19 e regras de segurança da orla.
---

# Skill: Revisão de Código e Portão de Qualidade (Pé na Areia)

Checklist de auditoria de Pull Requests e novas implementações no projeto Pé na Areia.

## Eixos de Avaliação

### 1. Correção e Regras de Negócio da Praia
- [ ] O `codigoEntrega` de 4 dígitos permanece mascarado para entregadores antes do status `ENTREGUE`.
- [ ] A confirmação da entrega valida `distanceMeters <= 60.0` com fórmula precisa.
- [ ] O recálculo da nota média do quiosque é atômico após o recebimento de avaliações.

### 2. Padrões Java 21 & Spring Boot
- [ ] DTOs modelados exclusivamente como `record`.
- [ ] Sem concatenação de queries (uso estrito de Spring Data MongoDB).
- [ ] Ausência de `@Autowired` em campos (injeção obrigatória por construtor).
- [ ] Cobertura JaCoCo mantida em $\ge 80\%$.

### 3. Padrões Flutter & Mobile Multi-App
- [ ] Cores e tipografia utilizam o Design System Sage & Apricot (`packages/core_shared`).
- [ ] Checagem `GoogleMapsChecker.isReady` presente em qualquer visualização de mapa.
- [ ] Zero erros ou alertas em `flutter analyze`.
- [ ] `MainActivity.kt` localizado no pacote correto (`com.penaareia.<app>`).

### 4. Padrões React 19 & Web
- [ ] Tipagem TypeScript estrita sem `any`.
- [ ] Diretiva `'use client'` posicionada apenas em componentes interativos.
- [ ] Zero erros no linter (`npm run lint`).
