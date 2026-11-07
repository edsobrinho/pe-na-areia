---
name: penaareia-web-react
description: >-
  Procedimentos para desenvolvimento, validação e build do Portal do Parceiro (Quiosque) e Painel Administrativo
  em React 19, TypeScript, Vite e Tailwind CSS na pasta web/. Utilize ao criar componentes de dashboard,
  gerenciar cardápios com fotos, implementar métricas de faturamento ou feed de avaliações.
---

# Skill: Portal Web do Parceiro e Admin (React 19 + TypeScript + Vite)

Guia de desenvolvimento frontend web para os quiosques e administração do Pé na Areia.

## Estrutura do Módulo Web (`web/`)
- `src/components/PartnerOrdersManager.tsx`: Mural Kanban de pedidos do quiosque com status em tempo real via Server-Sent Events (SSE) e feed de avaliações com estrelas.
- `src/components/KioskMenuManager.tsx`: Gestor de cardápio com precificação e upload de fotos para o Cloudinary.
- `src/components/AdminPanel.tsx`: Painel gerencial da plataforma com métricas consolidadas, contagem de pedidos, faturamento e média de satisfação.
- `src/types.ts`: Definições TypeScript rigorosas para `Order`, `Kiosk`, `OrderReview` e métricas.

## Padrões de Código
1. **React 19:**
   - Aproveite a Actions API para mutações e submissões.
   - Utilize a diretiva `'use client'` estritamente quando houver necessidade de interatividade DOM ou estado local.
   - Não adicione `useMemo` ou `useCallback` sem necessidade comprovada de gargalo de performance.
2. **TypeScript Estrito:**
   - Proibido o uso de `any` ou `unknown` sem type guards.
   - Derive tipos usando Zod (`z.infer<typeof Schema>`).

## Comandos Operacionais

### 1. Iniciar Servidor de Desenvolvimento
```powershell
cd web
npm run dev
```
Disponível em: `http://localhost:5173`

### 2. Linting Rápido com Oxlint
```powershell
cd web
npm run lint
```

### 3. Testes Unitários com Vitest
```powershell
cd web
npm test
```

### 4. Build de Produção
```powershell
cd web
npm run build
```
Valida a compilação do TypeScript (`tsc -b`) e empacota os artefatos estáticos em `web/dist/`.
