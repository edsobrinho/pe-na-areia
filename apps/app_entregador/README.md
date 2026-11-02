# Pé na Areia · App do Entregador 🧭

Aplicativo oficial do entregador pedestre (courier) para navegação por bússola/radar, telemetria contínua e confirmação de entregas na faixa de areia da praia de Santos/SP.

---

## 📌 Sumário

- [Visão Geral e Desafio Logístico](#-visão-geral-e-desafio-logístico)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Modo Bússola e Radar Pedestre na Areia](#-modo-bússola-e-radar-pedestre-na-areia)
- [Validação de Entrega por Geofencing (60 Metros)](#-validação-de-entrega-por-geofencing-60-metros)
- [Arquitetura e Estrutura de Código](#-arquitetura-e-estrutura-de-código)
- [Identificação, Permissões e Políticas da Google Play](#-identificação-permissões-e-políticas-da-google-play)
- [Comandos de Desenvolvimento, Teste e Build](#-comandos-de-desenvolvimento-teste-e-build)

---

## 🎯 Visão Geral e Desafio Logístico

Entregar pedidos na faixa de areia da praia apresenta desafios que os apps tradicionais de entrega não resolvem:
1. **Não existem ruas, CEPs ou números prediais na areia:** Motores de rota veicular (Google Directions) falham ao tentar traçar trajetos até o mar.
2. **Milhares de pessoas e guarda-sóis semelhantes:** A visão do entregador é obstruída por cadeiras, tendas e banhistas.
3. **Deslocamento pedestre livre:** O entregador caminha em linha reta pela areia fofa.

O **App do Entregador** resolve esses gargalos combinando **navegação geodésica direta (Modo Bússola)**, **foto do guarda-sol com zoom**, **telemetria contínua** e **validação por Geofencing** para garantir que o cliente só receba seu pedido quando o entregador estiver fisicamente presente.

---

## 🚀 Funcionalidades Principais

### 1. Painel de Pedidos e Entregas Ativas
- **Fila de Pedidos Prontos:** Consulta de pedidos no status `EM_PREPARO` com paginação por cursor (`GET /orders/available`).
- **Aceite Imediato:** O entregador assume a responsabilidade do pedido, alterando o status para `A_CAMINHO`.
- **Entregas Ativas:** Painel dedicado para alternar entre pedidos em transporte e detalhes do destino.

### 2. 🧭 Modo Bússola / Radar Pedestre na Areia (`BeachRadarWidget`)
- **Linha Direta no Mapa:** Exibe um mapa com traçado vetorial direto (`Polyline`) entre a coordenada atual do entregador e o pin do cliente na areia.
- **Cálculo Geodésico em Tempo Real:** Utiliza a fórmula de Haversine para computar a distância precisa em metros.
- **Rosa dos Ventos em Português:** Converte o azimute em graus (`0°–360°`) em instruções cardeais e colaterais claras em relação ao Posto de Salvamento mais próximo (ex.: *"A 45 m a Sudeste (135°) do Posto 4"*).
- **Indicador Visual de Rumo:** Ponteiro giratório sincronizado com o rumo pedestre, guiando o entregador até a posição exata.

### 3. Visualização da Foto do Local e Descrição do Guarda-Sol
- **Card de Referência Visual:** Exibe a descrição do cliente (ex.: *"Guarda-sol azul e branco, duas cadeiras ao lado da rede de futevôlei"*).
- **Zoom Interativo da Foto:** Toque na foto enviada pelo cliente para abrir visualizador em tela cheia com zoom e pan para identificar detalhes do guarda-sol na multidão.

### 4. Telemetria GPS em Segundo Plano
- **Transmissão Periódica:** Enquanto uma entrega estiver `A_CAMINHO`, o app transmite a localização para `PATCH /orders/{id}/courier-location`.
- **Foreground Service:** Mantém o rastreamento ativo mesmo com a tela do celular apagada ou com o app minimizado no bolso do entregador.
- **Disparo do Alerta de 60m:** Quando a telemetria do entregador cruza o raio de 60 metros do cliente, o backend dispara o evento SSE que avisa o banhista para sair do mar e ativar o Farol.

### 5. Confirmação de Entrega com Geofencing Obrigatório
- O botão **"Confirmar Entrega"** dispara `POST /orders/{id}/confirm-delivery` enviando a coordenada GPS atual do entregador.
- O backend calcula a distância até o pin original do cliente:
  - **<= 60 metros:** Entrega validada com sucesso, status avança para `ENTREGUE`.
  - **> 60 metros:** A operação é bloqueada pelo servidor, impedindo fraudes ou finalizações acidentais fora do local.

### 6. Canal de Comunicação com o Cliente
- Acesso às mensagens contextuais rápidas trocadas no pedido.
- Botão de abertura direta para o **WhatsApp** do cliente para alinhamento rápido em caso de imprevistos.

---

## 🧩 Arquitetura e Estrutura de Código

```text
apps/app_entregador/
├── lib/
│   ├── main.dart                                # Ponto de entrada do app do entregador
│   ├── app/
│   │   ├── app.dart                             # MaterialApp configurado com o tema oficial
│   │   ├── dependencies.dart                    # Injeção de repositórios e serviços de localização
│   │   └── routes.dart                          # Rotas (/login, /home, /radar)
│   └── presentation/
│       ├── auth/
│       │   └── login_screen.dart                # Autenticação exclusiva para perfil COURIER
│       └── courier/
│           ├── courier_home_screen.dart         # Lista de pedidos disponíveis e entregas ativas
│           └── beach_radar_widget.dart          # Radar pedestre, bússola e foto com zoom
└── test/                                        # Testes automatizados do painel e widgets
```

---

## 🔒 Identificação, Permissões e Políticas da Google Play

- **Application ID:** `com.penaareia.entregador`
- **Permissões Android declaradas em `AndroidManifest.xml`:**
  - `android.permission.INTERNET` — Comunicação com a API REST.
  - `android.permission.ACCESS_FINE_LOCATION` — Rastreamento de GPS de alta precisão.
  - `android.permission.ACCESS_COARSE_LOCATION` — Localização por rede celular.
  - `android.permission.ACCESS_BACKGROUND_LOCATION` — Permite que o entregador envie sua posição enquanto caminha na areia com a tela do aparelho bloqueada.
  - `android.permission.FOREGROUND_SERVICE` e `android.permission.FOREGROUND_SERVICE_LOCATION` — Execução em primeiro plano com notificação persistente na barra de status.
  - `android.permission.WAKE_LOCK` — Evita que o processador entre em suspensão profunda durante a entrega.

> [!IMPORTANT]
> **Política de Localização em Segundo Plano da Google Play:**
> Para publicação na Google Play Store, o `app_entregador` requer o preenchimento da **Declaração de Uso de Localização em Segundo Plano** no Play Console. É obrigatório anexar um vídeo de demonstração comprovando que a localização em segundo plano é fundamental para a funcionalidade principal do aplicativo (informar ao cliente a aproximação na areia e acionar o alerta sonoro e Farol Visual).

---

## 🚀 Comandos de Desenvolvimento, Teste e Build

```powershell
Set-Location apps/app_entregador

# Instalar dependências
flutter pub get

# Executar suíte de testes
flutter test

# Verificar lint e boas práticas
flutter analyze

# Executar em dispositivo físico apontando para o backend Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.0.4:8080

# Compilar APK de produção para distribuição local
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.0.4:8080

# Compilar Android App Bundle (AAB) para a Google Play Store
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.penaareia.com.br
```
