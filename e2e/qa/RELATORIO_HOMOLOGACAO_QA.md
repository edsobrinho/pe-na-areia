# Relatório de Homologação QA Sênior — Pé na Areia v2.1

**Data da Execução:** 28/10/2026  
**Cenário Simulado:** *"Dia de Sol no Posto 5 — Santos/SP"* (`kiosk-santos-1`, `pe-na-areia-app`, Posto 5 `6acfd917f737c71df923a343`)  
**Status Final:** ✅ **APROVADO SEM RESSALVAS (100% PASS)**

---

## 1. Resumo Consolidado das Suítes Executadas

| Camada / Suíte | Comando Executado | Resultado | Detalhes |
| :--- | :--- | :--- | :--- |
| **Infraestrutura Docker** | `docker compose -f infrastructure/docker-compose.yml ps` | ✅ **3/3 UP & HEALTHY** | `mongodb` (`rs0`, `:27017`), `cloudinary-mock` (`:8099`), `backend` (`:8080`) |
| **E2E Full-Stack (3 Atores)** | `node e2e/e2e_delivery_flow.mjs` | ✅ **53 PASS / 0 FAIL** | Simulação completa: Operador Web (`KIOSK_OPERATOR`), Cliente na Areia (`CLIENT`) e Entregador (`COURIER`) |
| **Backend (Spring Boot 3)** | `cd backend && .\gradlew.bat test` | ✅ **BUILD SUCCESSFUL** | Testes unitários e de serviço (`OrderServiceTest`, `KioskServiceTest`, `PartnershipServiceTest`, `CloudinaryStorageServiceTest`, etc.) |
| **Frontend Mobile (Flutter 3)** | `cd frontend && flutter analyze && flutter test` | ✅ **0 Issues / 127 PASS** | Análise estática limpa + 127 testes de unidade, validadores, radar pedestre e widgets |
| **Painel Web (React 19 + TS)** | `cd web && npm.cmd run build && npm.cmd test` | ✅ **Build OK / 26 PASS** | Compilação TypeScript + Vite (`248ms`) + 26 testes de máscaras e validadores brasileiros |

---

## 2. Matriz de Rastreabilidade — As 53 Verificações E2E (`e2e_delivery_flow.mjs`)

### Fase 1 — Portal Web do Restaurante / Quiosque (`it_01` e `it_11`)
- [x] **Autenticação e Promoção de Operador (`KIOSK_OPERATOR`)**: Registro e login vinculados ao `kiosk-santos-1`.
- [x] **Ativação do Canal de Parceria (`PUT /kiosk/me/partnerships/pe-na-areia-app`)**: Configuração de comissão (`10%`), taxa de entrega (`R$ 0,00`, pagador `KIOSK`), pedido mínimo (`R$ 20,00`) e tempo de preparo (`15 min`).
- [x] **Simulador de Repasse (`POST /kiosk/me/partnerships/pe-na-areia-app/preview`)**: Cálculo exato de `subtotal = R$ 62,50` e `kioskNet = R$ 56,25` sem criar pedido.
- [x] **Configuração da Vitrine do Quiosque (`PUT /kiosk/me/storefront`)**: Persistência de `descricaoCurta`, `fotoCapaUrl`, `logoUrl`, `aceitaEmbalagemSustentavel: true` e `destaquePopular: true`.
- [x] **Upload de Foto do Cardápio (`POST /uploads/menu-item-photo`)**: Armazenamento no container `cloudinary-mock` na pasta `pe-na-areia/cardapio`.
- [x] **CRUD Completo de Item com Foto e Destaque (`POST /kiosk/me/menu`, `GET /kiosk/me/menu`, `DELETE /kiosk/me/menu/{id}`)**: Cadastro de *"Açaí na Tigela 500ml"* com `destaque: true`, `returnablePackaging: true` e `fotoUrl`.

### Fase 2 — Jornada do Banhista no App do Cliente — 6 Telas Costeiras (`it_02` a `it_07`)
- [x] **Tela 2 (`Início` — Descoberta da Orla)**:
  - `GET /partnerships` retorna os canais de venda ativos (`pe-na-areia-app`).
  - `GET /kiosks` retorna o quiosque com metadados de vitrine (`fotoCapaUrl`, `logoUrl`, `descricaoCurta`, `destaquePopular: true`).
- [x] **Tela 3 (`Quiosques Populares na Orla` — `PopularKiosksScreen`)**: Filtragem por `destaquePopular == true` e ordenação por nota/distância.
- [x] **Tela 4 (`Loja do Quiosque` — `KioskStorefrontScreen`)**:
  - `GET /kiosks/kiosk-santos-1/partnerships` retorna `prepMinutes: 15`, `deliveryFee: 0` e `minimumOrder: 20`.
  - Itens do cardápio trazem `destaque: boolean` para o carrossel *"Mais pedidos na areia"*.
- [x] **Tela 5 (`Minha Sacola na Praia` — `BeachCartScreen`) & Validações Negativas (`it_03`)**:
  - Bloqueio de pedido em nome de outro usuário (`422`).
  - Bloqueio de pedido sem itens (`400/422`) ou com quantidade zero (`400`).
  - Bloqueio de item esgotado (`422`) ou inexistente (`404`).
  - Bloqueio de pin a mais de `500m` do Posto de Referência (`422`).
  - Bloqueio de pedido abaixo do valor mínimo da parceria (`R$ 12,00 < R$ 20,00` -> `422`).
- [x] **Tela 1 (`Confirmar Ponto na Praia` — `BeachSpotFormScreen`)**:
  - **Guia de 3 Fotos na Areia (`it_04`)**: Upload real dos 3 slots (`guarda-sol.png`, `visao-posto.png`, `outro-item.png`) via `POST /uploads/location-photo` e verificação de entrega HTTP `200 image/png` pelo container `cloudinary-mock`.
  - **Criação do Pedido (`it_05` — `POST /orders`)**: Persistência de `referenciaBarraca`, `complementoLocal`, `contatoNome`, `contatoTelefone`, `etiquetaLocal: MEU_GUARDA_SOL`, `fotoLocalUrl` e `fotoVisaoPostoUrl`.
  - **Pix Copia e Cola (`pixCopiaECola`)**: Geração de payload EMV BR Code (`br.gov.bcb.pix`) e `pixTxId`, com valor total calculado no servidor (`R$ 62,50`).
- [x] **Cancelamento Seguro (`it_07`)**: Cliente consegue cancelar pedido antes de sair para entrega (`CANCELADO`).

### Fase 3 — App do Entregador: Radar Pedestre, Live Tracking, Farol Visual e Geofencing 60m (`it_08` a `it_10`)
- [x] **Isolamento e Segurança (`it_06`)**:
  - Cliente impedido de consultar `/orders/available` (`422`) e `/orders/courier/active` (`422`).
  - Requisição anônima bloqueada com `401 Unauthorized`.
  - Segundo entregador (`aparelho-C`) impedido de visualizar pedido de terceiros (`422`).
- [x] **Aceite da Entrega (`it_08`)**:
  - Entregador lista pedidos prontos (`GET /orders/available`) e aceita (`PATCH /orders/{id}/status` -> `A_CAMINHO`).
  - Recebe integralmente os metadados do Ponto na Praia (`referenciaBarraca`, `complementoLocal`, `contatoTelefone`, `fotoLocalUrl`, `fotoVisaoPostoUrl`).
- [x] **Live Tracking e Gatilho de Proximidade de 60m (`it_09`)**:
  - Coordenada enviada a `~220m` do pin (`> 60m`): `alertaProximidadeEnviado` permanece `false`.
  - Coordenada enviada a `~22m` do pin (`<= 60m`): `alertaProximidadeEnviado` transiciona para `true`, disparando o alerta para o cliente ativar o **Farol Visual (`SignalBeaconScreen`)**.
- [x] **Canal Rápido de Mensagens na Areia (`it_09`)**:
  - Cliente envia `"A maré subiu, mudei alguns metros para trás"` (`POST /orders/{id}/messages` -> `200`).
  - Entregador responde `"Estou a 20m a Sudeste, levante o Sinalizador Laranja!"` (`200`).
  - Histórico completo consultado via `GET /orders/{id}/messages` (`2 mensagens`).
- [x] **Trava Geofencing de Entrega Final no Raio de 60m (`it_10`)**:
  - Entregador marca `CHEGOU_NO_LOCAL` (`200`).
  - Tentativa de confirmar entrega a `~135m` do pin do cliente é **rejeitada com HTTP `422`**.
  - Confirmação de entrega a `~5m` do pin do cliente é **aprovada com HTTP `200`**, mudando o status para `ENTREGUE`.
