# Catálogo de Evidências Visuais e Homologação de Telas (QA) — Pé na Areia

Bem-vindo ao repositório de evidências visuais de testes e homologação de qualidade (QA) da plataforma **Pé na Areia**, delivery hiperlocal na orla da praia de Santos - SP.

Este diretório contém as capturas de tela oficiais comprobatórias da implementação e conformidade dos requisitos de negócio **R1 a R5** descritos em `ORIGINAL_REQUEST.md`.

---

## 1. Estrutura do Diretório de Evidências

```text
evidencias/
├── README.md                              # Este documento (guia e índice de evidências)
├── RELATORIO_TESTES_QA.md                 # Relatório consolidado de testes de QA e conformidade
├── r1_pin_confirmacao/                    # [R1] Desacoplamento de Sequencial e Confirmação por PIN Verbal
│   ├── 01_cliente_exibicao_pin.png        # Tela do cliente: exibição do PIN de 4 dígitos e Pedido #0001
│   ├── 02_entregador_codigo_sequencial.png# Tela do entregador: código diário #0001 com PIN protegido
│   ├── 03_entregador_dialogo_pin.png      # Modal de inserção e validação do PIN de 4 dígitos
│   └── 04_entrega_confirmada_sucesso.png  # Confirmação pós-validação verbal de PIN e geofencing
├── r2_chat_tempo_real/                    # [R2] Chat em Tempo Real com Expiração por Status
│   ├── 01_chat_ativo_pronto_entrega.png   # Chat aberto em PRONTO_ENTREGA (Quiosque e Cliente)
│   ├── 02_chat_ativo_a_caminho.png        # Troca de mensagens ativas durante rota A_CAMINHO
│   └── 03_chat_expirado_entregue.png      # Bloqueio definitivo de mensagens em ENTREGUE / CANCELADO
├── r3_rastreamento_rota/                  # [R3] Rota e Rastreamento em Tempo Real do Entregador
│   ├── 01_cliente_rota_polyline.png       # Rota dinâmica com Polyline conectando entregador ao pin
│   └── 02_alerta_proximidade_60m.png      # Gatilho de alerta de 60m e Farol Visual (SignalBeacon)
├── r4_coleta_multipla_5_pedidos/          # [R4] Loteamento de até 5 Pedidos Simultâneos Próximos
│   ├── 01_entregador_lote_3_pedidos.png   # Gestão simultânea de 3 pedidos de quiosques vizinhos
│   └── 02_bloqueio_sexto_pedido.png       # Modal de rejeição de 6º pedido ativo (limite excedido)
└── portal_web/                            # Painel Administrativo e Portal do Parceiro
    ├── 01_kanban_pedidos_quiosque.png     # Kanban em tempo real com código diário #0001 e telemetria
    └── 02_cardapio_vitrine_fotos.png      # Gestão de cardápio fotográfico com Cloudinary Mock
```

---

## 2. Como Reproduzir e Regenerar as Evidências Visuais

As capturas de tela são geradas de forma 100% determinística através do Google Chrome Headless (com fallback automático para Microsoft Edge), sem requerer servidores externos:

### Via PowerShell (Windows):
```powershell
powershell -ExecutionPolicy Bypass -File scripts\capture-evidence.ps1
```

### Via Node.js (Multiplataforma):
```bash
node scripts/capture-evidence.mjs
```

Ambos os comandos inspecionam o ambiente, renderizam as telas respeitando os tokens do Design System oficial **"Brisa Minimalista — Sage & Apricot"** e gravam os arquivos PNG diretamente nesta pasta `evidencias/`.

---

## 3. Relatório Detalhado de QA

Para consultar a matriz completa de conformidade dos requisitos R1 a R5, resumo de testes executados, métricas de cobertura de código e auditoria de segurança da orla, consulte:
👉 **[`RELATORIO_TESTES_QA.md`](./RELATORIO_TESTES_QA.md)**
