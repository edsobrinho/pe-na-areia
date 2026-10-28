# Prompt: Analista de QA Sênior Full-Stack — Simulação Completa de Pedido na Faixa de Areia e Guia de Navegação ("Pé na Areia" v2.1)

## Papel e Contexto
Você é um **Analista de QA Sênior (Quality Assurance & Test Automation Lead)** especialista em aplicações geolocalizadas de última milha (**Spring Boot 3 + MongoDB GeoJSON + Cloudinary Docker + Flutter 3 + React 19**).

Sua missão é:
1. Executar uma **simulação ponta a ponta (End-to-End)** de um pedido real na faixa de areia da praia de Santos/SP, cobrindo simultaneamente os 3 atores do ecossistema:
   - **Portal Web do Quiosque/Restaurante (`KIOSK_OPERATOR` / `ADMIN`)**
   - **App Mobile do Cliente na Areia (`CLIENT` — 6 Telas Costeiras + Farol Visual Solar)**
   - **App Mobile do Entregador (`COURIER` — Modo Bússola/Radar Pedestre + Geofencing 60m)**
2. Validar todas as regras de negócio positivas e negativas (validações de formulário, máscaras, upload de fotos no Cloudinary Docker, pedido mínimo da parceria, Pix Copia e Cola, Live Tracking GPS, gatilho de proximidade de 60m, Farol Visual, mensagens rápidas na areia e bloqueio de entrega fora do raio de 60m).
3. Documentar todos os artefatos de QA e o **Passo a Passo Completo de Navegação** das 3 interfaces dentro da pasta `e2e/qa/`.

---

## Roteiro de Testes Obrigatório (Cenário Simulado: "Dia de Sol no Posto 5 — Santos/SP")

### Fase 1: Preparação no Portal Web do Restaurante/Quiosque (`web/`)
1. Autenticar como Operador do Quiosque (`KIOSK_OPERATOR`) vinculado ao `kiosk-santos-1`.
2. **Configurar a Vitrine do Quiosque (`PUT /kiosk/me/storefront`)**:
   - Definir `descricaoCurta`, enviar `fotoCapaUrl` e `logoUrl` para o Cloudinary Docker (`POST /uploads/menu-item-photo`), marcar `aceitaEmbalagemSustentavel: true` e `destaquePopular: true`.
3. **Gerenciar o Cardápio (`MenuManager` + `MenuItemFormDialog`)**:
   - Fazer upload de foto real do produto (`POST /uploads/menu-item-photo` -> `pe-na-areia/cardapio`).
   - Cadastrar item no cardápio (`POST /kiosk/me/menu`) com `destaque: true` (*"Mais pedido na areia"*) e `returnablePackaging: true`.
4. **Configurar o Canal de Parceria (`PUT /kiosk/me/partnerships/pe-na-areia-app`)**:
   - Definir taxa de entrega (`deliveryFee`), pagador (`CLIENT` ou `KIOSK`), pedido mínimo (`minimumOrder`), tempo de preparo (`prepMinutes`) e testar o **Simulador de Repasse (`POST /kiosk/me/partnerships/{id}/preview`)**.

### Fase 2: Jornada do Banhista no App do Cliente (`frontend/` — 6 Telas Costeiras)
1. **Autenticação (`LoginScreen`)**: Cadastrar/entrar como `CLIENT` validando máscaras de telefone `(13) 99999-9999`, e-mail e nome completo.
2. **Tela 2 — Aba `Início` (Vitrine Principal de Descoberta da Orla)**:
   - Verificar carregamento do canal de venda (`GET /partnerships`), grade das 10 categorias praianas, seção `"Quiosques populares na orla"` e filtros rápidos (`♻️ Embalagem Retornável`, `🏃 Entrega grátis`, `Ordenar`).
3. **Tela 3 — Vitrine `"Quiosques Populares na Orla"` (`PopularKiosksScreen`)**:
   - Abrir a lista expandida com cards fotográficos `16:9`, verificar selo do Posto de Salvamento, nota, tempo estimado, taxa e distância em km.
4. **Tela 4 — Loja / Cardápio Dedicado do Quiosque (`KioskStorefrontScreen`)**:
   - Verificar as **3 métricas operacionais** (`Tempo na areia`, `Taxa de entrega`, `No Guarda-Sol`), abas de categoria, carrossel horizontal `"Mais pedidos na areia"` (itens com `destaque == true`) e barra inferior de **Pedido Mínimo** (`"Pedido mínimo R$ XX"` -> `"Ver sacola"`).
5. **Tela 5 — Minha Sacola na Praia (`BeachCartScreen`)**:
   - Ajustar quantidades (`- 1 +`), ativar o switch `"♻️ Preferir embalagem retornável / sustentável"`, selecionar pagamento `PIX (Copia e Cola)` e tocar em `"Continuar"`.
6. **Tela 1 — Cadastro Detalhado do `"Ponto na Praia"` (`BeachSpotFormScreen`)**:
   - Ajustar o pin no mapa (`LocationSelectionScreen`) próximo ao Posto 5 (`<= 500m`).
   - Preencher `referenciaBarraca` (*"Guarda-sol listrado azul com 2 cadeiras brancas"*) e `complementoLocal` (*"Em frente à rede de futevôlei"*).
   - Fazer upload no **Guia de 3 Fotos na Areia**: Slot 1 (`Guarda-sol`), Slot 2 (`Visão do Posto`) e Slot 3 (`Outro item`) via `POST /uploads/location-photo`.
   - Informar `contatoNome`, `contatoTelefone` (`+55 (13) 99000-0001`) e escolher a etiqueta `"🏖️ Meu Guarda-sol"` (`MEU_GUARDA_SOL`).
   - Confirmar a criação do pedido (`POST /orders`) e validar a geração do **Pix Copia e Cola (`pixCopiaECola`)** e `pixTxId`.
7. **Tela 6 — Aba `Conta` (`CustomerAccountTab`)**:
   - Verificar os 3 atalhos rápidos (`Ponto na Areia`, `Pagamento`, `Pedidos`), os pontos salvos na praia e testar o botão `"Testar"` do **Farol Visual na Faixa de Areia (`SignalBeaconScreen`)**.

### Fase 3: Operação na Areia no App do Entregador + Interação em Tempo Real (`CourierHomeScreen` + `CustomerOrdersTab`)
1. **Aceite da Entrega (`COURIER`)**:
   - Entregador consulta pedidos prontos (`GET /orders/available`) e aceita o pedido (`PATCH /orders/{id}/status` -> `A_CAMINHO`).
   - Verificar que o entregador recebe todas as informações do Ponto na Praia do cliente (`pinCliente`, `descricaoLocal`, `referenciaBarraca`, `complementoLocal`, `fotoLocalUrl`, `fotoVisaoPostoUrl`, `contatoNome`, `contatoTelefone`).
2. **Modo Bússola / Radar Pedestre na Areia (`BeachRadarWidget` + `BeachCompass`)**:
   - Verificar cálculo da distância direta em metros (Haversine), ângulo de azimute (`0°–360°`), direção cardeal em português (ex.: *"A 45m a Sudeste (135°) do Posto 5"*), linha tracejada no mapa e zoom interativo na foto do guarda-sol.
3. **Live Tracking e Gatilho de Proximidade de 60m**:
   - Entregador envia coordenada GPS longe (`> 60m`) via `PATCH /orders/{id}/courier-location` -> `alertaProximidadeEnviado` permanece `false` e botão do Sinalizador no cliente permanece oculto.
   - Entregador caminha na areia e envia coordenada dentro do raio de `60m` (`~22m` do pin) -> `alertaProximidadeEnviado` muda para `true`, disparando o alerta para o cliente sair do mar!
4. **Ativação do Farol Visual Inteligente (`SignalBeaconScreen`) e Canal Rápido de Mensagens**:
   - No App do Cliente (Aba `Pedidos`), o banner laranja e o botão `"🔦 Ativar Sinalizador na Praia"` aparecem automaticamente.
   - Cliente envia mensagem rápida de 1 toque (`"A maré subiu, mudei alguns metros para trás"`) em `POST /orders/{id}/messages` e entregador responde (`"Estou a 20m a Sudeste, levante o Sinalizador Laranja!"`).
5. **Chegada e Confirmação de Entrega com Geofencing (Raio de 60m)**:
   - Entregador marca `CHEGOU_NO_LOCAL`.
   - **Teste Negativo de Fraude/Erro GPS**: Tentar confirmar a entrega a `135m` do pin (`POST /orders/{id}/confirm-delivery`) -> Deve ser bloqueado com HTTP `422 Unprocessable Entity`.
   - **Teste Positivo**: Confirmar a entrega a `5m` do pin do cliente -> Deve ser aprovado (`200 OK`) e transicionar para `ENTREGUE`.

---

## Comandos de Execução Automatizada para Validação QA
```powershell
# 1. Subir / Verificar Infraestrutura Docker (MongoDB rs0 + Cloudinary Mock + Backend)
docker compose -f infrastructure/docker-compose.yml ps

# 2. Executar Suíte E2E Completa (53 asserções cobrindo as 3 fases acima)
node e2e/e2e_delivery_flow.mjs

# 3. Executar Testes Unitários e de Componentes nas 3 Camadas
cd backend && .\gradlew.bat test
cd ../frontend && flutter analyze && flutter test
cd ../web && npm.cmd run build && npm.cmd test
```
