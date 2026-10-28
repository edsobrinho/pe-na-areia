# Pé na Areia — App Mobile (Flutter)

Aplicativo mobile multiplataforma (**Android** e **iOS**) do ecossistema **Pé na Areia**, construído em **Flutter 3.29+** com arquitetura em camadas (`domain`, `data`, `presentation`) e gerenciamento de estado via `Provider`.

---

## Principais Funcionalidades no App

### 1. Experiência do Cliente (`CustomerHomeScreen`)
- **Catálogo Visual com Fotos (`fotoUrl`):** Seleção do canal de venda (`/partnerships`), navegação pelos quiosques ativos (`/kiosks?partnershipId=`) e visualização de miniaturas reais dos produtos cadastrados pelos quiosques no Cloudinary.
- **Pin Interativo na Faixa de Areia (`LocationPickerScreen`):** Marcação do ponto exato do guarda-sol no Google Maps, sugestão dos Postos de Salvamento mais próximos (`/reference-points/nearby`), descrição textual validada (até 140 caracteres) e captura/upload de foto do local (`/uploads/location-photo`).
- **Pagamento Antecipado Pix:** Exibição do código **Pix Copia e Cola** (`pixCopiaECola`) com botão de cópia rápida para a área de transferência e QR Code quando o pedido aguarda confirmação de pagamento.
- **Rastreamento do Entregador em Tempo Real:** Exibição do marcador do entregador se movendo no mapa (`localizacaoEntregador`), cálculo da distância em metros até o cliente e banner de **Alerta de Proximidade (60m)** quando o entregador entra na areia.
- **🔦 Farol Visual Inteligente de Tela Cheia (`SignalBeaconScreen`):**
  - O botão **"🔦 Ativar Sinalizador na Praia"** é exibido exclusivamente quando o pedido está em `CHEGOU_NO_LOCAL` **ou** quando está `A_CAMINHO` a **`<= 60 metros`** do cliente (`Order.podeAtivarSinalizador`).
  - Modo imersivo (`SystemUiMode.immersiveSticky`) alternando cores de alto contraste sob luz solar (**Laranja Neon `#FF7A3D`**, **Amarelo Solar `#FFD600`** e **Branco**), com opção de fixar a cor, cronômetro regressivo de **3 minutos**, código curto do pedido e descrição do local.
- **💬 Canal Rápido de Contato na Praia:** Atalhos de 1 toque (*"🌊 A maré subiu, mudei alguns metros para trás"*, *"🔦 Estou levantando o Sinalizador na tela"*, *"🏖️ Estou atento perto do guarda-sol"*) integrados a `POST /orders/{id}/messages` e botão direto para **WhatsApp** com mensagem pré-formatada.

### 2. Experiência do Entregador (`CourierHomeScreen` + `BeachRadarWidget`)
- **Painel de Entregas:** Listagem de pedidos prontos (`EM_PREPARO`) disponíveis para aceite e entregas ativas sob responsabilidade do entregador.
- **🧭 Modo Bússola / Radar Pedestre na Areia (`BeachCompass` + `BeachRadarWidget`):**
  - Cálculo geodésico em tempo real usando fórmula de **Haversine** e **Azimute/Bearing (`0°–360°`)** entre o GPS atual do entregador e o `pinCliente`.
  - Exibição da **distância direta em metros** e **direção cardeal/colateral em português** (`Norte`, `Nordeste`, `Leste`, `Sudeste`, `Sul`, `Sudoeste`, `Oeste`, `Noroeste`), por exemplo: *"A 42 m a Sudeste (135°) do Posto 4"*.
  - Desenho de **`Polyline` tracejada direta** no Google Maps ligando a posição atual do entregador ao guarda-sol do cliente.
  - Exibição destacada da **foto do guarda-sol (`fotoLocalUrl`) com zoom interativo (`InteractiveViewer`)** ao tocar.
- **Telemetria GPS Automática:** Emissão periódica da coordenada atual (a cada 8 segundos enquanto `A_CAMINHO`) para `PATCH /orders/{id}/courier-location`.
- **Canal Rápido e Confirmação por Geofencing (60m):** Envio de mensagens rápidas de 1 toque ao cliente e confirmação de entrega (`POST /orders/{id}/confirm-delivery`) validada pelo GPS dentro do raio de 60 metros.

---

## Como Executar

Requisitos: **Flutter 3.29+**, backend em execução (consulte o [README da raiz](../README.md)) e chave do Google Maps configurada.

```powershell
Set-Location frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

- `10.0.2.2` aponta para o computador host no emulador Android.
- No simulador iOS ou desktop, utilize `http://localhost:8080` ou o IP da máquina na rede local.

### Instalação Manual (`.apk`) no Celular Físico via Wi-Fi + DNS Local + Docker

1. **Passo 1 — DNS de Rede Local (`sslip.io`)**: Descubra o IP Wi-Fi do seu PC (`Get-NetIPAddress -AddressFamily IPv4`) — por exemplo, `192.168.0.3` — e utilize o domínio curinga `http://api.pe-na-areia.192.168.0.3.sslip.io:8080` (ou configure um Host Override no DNS do seu roteador).
2. **Passo 2 — Firewall do Windows**: No PowerShell como Administrador, libere as portas `8080` (Backend) e `8099` (Cloudinary Mock):
   ```powershell
   New-NetFirewallRule -DisplayName "Pe na Areia Docker LAN" -Direction Inbound -LocalPort 8080,8099 -Protocol TCP -Action Allow
   ```
3. **Passo 3 — Subir o Docker para a Rede Local**:
   ```powershell
   $env:CLOUDINARY_PUBLIC_BASE_URL="http://cdn.pe-na-areia.192.168.0.3.sslip.io:8099"
   $env:APP_CORS_ORIGINS="http://localhost:*,http://127.0.0.1:*,http://*.sslip.io:*,http://192.168.*:*"
   docker compose -f infrastructure/docker-compose.yml up -d
   ```
4. **Passo 4 — Gerar e Instalar o `.apk`**:
   ```powershell
   cd frontend
   flutter build apk --release --dart-define=API_BASE_URL=http://api.pe-na-areia.192.168.0.3.sslip.io:8080
   ```
   Instale o arquivo gerado (`build/app/outputs/flutter-apk/app-release.apk`) via `adb install -r build\app\outputs\flutter-apk\app-release.apk` ou enviando-o para o celular via WhatsApp/Drive.

### Configuração da Chave do Google Maps

Ative o **Maps SDK for Android** e/ou **Maps SDK for iOS** no Google Cloud Console:

- **Android:** adicione `MAPS_API_KEY=SUA_CHAVE` em `android/local.properties` ou defina a variável de ambiente `MAPS_API_KEY`.
- **iOS:** defina `GMS_API_KEY = SUA_CHAVE` em `ios/Flutter/ApiKeys.xcconfig`.

---

## Estrutura de Pastas (`lib/`)

```text
frontend/lib/
├── core/                  # Configuração de ambiente, cliente HTTP, armazenamento seguro e erros
├── data/
│   ├── dto/               # DTOs de transferência com a API
│   ├── mappers/           # Mapeadores JSON <-> Entidades de Domínio (OrderMapper, KioskMapper, etc.)
│   └── repositories/      # Repositórios (Auth, Kiosk, Order, Partnership, ReferencePoint, Upload)
├── domain/
│   ├── models/            # Modelos de domínio (Order, Kiosk, MenuItem com fotoUrl, QuickMessage, etc.)
│   └── utils/             # Utilitários de domínio:
│       ├── beach_compass.dart     # Cálculo Haversine, Bearing/Azimute e Rosa dos Ventos em PT-BR
│       └── form_validators.dart   # Validações e máscaras de formulário (e-mail, telefone, senha, pin)
└── presentation/
    ├── auth/              # Tela de login e cadastro com máscaras e validação
    ├── beacon/            # SignalBeaconScreen (Farol Visual de Tela Cheia)
    ├── courier/           # CourierHomeScreen e BeachRadarWidget (Bússola/Radar Pedestre)
    ├── customer/          # CustomerHomeScreen e LocationPickerScreen
    └── prototype/         # Protótipo interativo inicial e mapa dos fluxos
```

---

## Análise Estática e Testes Automatizados

O projeto conta com **124 testes automatizados** cobrindo modelos, mappers, repositórios, validações de formulário, cálculos da bússola na areia (`BeachCompass`) e regras de ativação do Farol Visual (`SignalBeaconScreen`):

```powershell
Set-Location frontend
flutter analyze
flutter test
```
