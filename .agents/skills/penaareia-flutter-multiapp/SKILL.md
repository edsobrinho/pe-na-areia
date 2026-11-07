---
name: penaareia-flutter-multiapp
description: >-
  Instruções para desenvolvimento, análise estática, testes e compilação dos três aplicativos móveis Flutter
  do Pé na Areia (app_cliente, app_entregador, app_prototipo) e do pacote compartilhado core_shared.
  Utilize quando alterar widgets, atualizar telas de pedidos/radar, ajustar o Design System Sage & Apricot ou gerar APKs.
---

# Skill: Flutter Multi-App Monorepo (Pé na Areia)

Procedimentos para gerenciamento do ecossistema mobile do Pé na Areia.

## Estrutura dos Projetos
- `packages/core_shared/`: Design System (`AppColors`, `AppTheme`), modelos de domínio (`Order`, `Kiosk`), repositórios e utilitários (`GoogleMapsChecker`).
- `apps/app_cliente/` (`com.penaareia.cliente`): Catálogo de quiosques, localização na areia, farol visual e avaliação de entrega.
- `apps/app_entregador/` (`com.penaareia.entregador`): Radar pedestre na areia, telemetria contínua e confirmação via PIN.
- `apps/app_prototipo/` (`com.penaareia.prototipo`): Protótipo navegável para demonstrações e testes rápidos.

## Regras de Interface e Resiliência
1. **Design System "Brisa Minimalista — Sage & Apricot":**
   - Cores primárias: `ocean700` (`#00383D`), `sage500` (`#739E82`), `apricot500` (`#FFA364`), `sand100` (`#F7F4EA`).
2. **Resiliência do Google Maps:**
   - Sempre verificar `GoogleMapsChecker.isReady` antes de exibir `GoogleMap`.
   - Se for `false` (comum no Flutter Web ou sem chaves JS ativas), invocar o fallback temático `_buildMapFallback`.
3. **Android Gradle & Kotlin:**
   - Gradle `8.14.6` com AGP `8.13.2` e Kotlin `2.3.20`.
   - `MainActivity.kt` deve estar alinhado com o `namespace` de cada app.

## Comandos Operacionais

### 1. Análise Estática (Zero Erros)
```powershell
flutter analyze packages/core_shared
flutter analyze apps/app_cliente
flutter analyze apps/app_entregador
flutter analyze apps/app_prototipo
```

### 2. Execução de Testes
```powershell
flutter test packages/core_shared
flutter test apps/app_cliente
flutter test apps/app_entregador
flutter test apps/app_prototipo
```

### 3. Geração dos APKs de Produção (`dist-mobile/`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-all.ps1 -ApiBaseUrl "http://192.168.0.4:8080"
```
Saídas geradas:
- `dist-mobile/cliente/pe-na-areia-cliente.apk`
- `dist-mobile/entregador/pe-na-areia-entregador.apk`
- `dist-mobile/prototipo/pe-na-areia-prototipo.apk`
