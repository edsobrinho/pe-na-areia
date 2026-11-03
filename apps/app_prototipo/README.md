# Pé na Areia · Protótipo Funcional & Showcase 📱

Aplicativo de demonstração navegável, showcase do Design System e ambiente de testes interativos do ecossistema **Pé na Areia**.

---

## 📌 Sumário

- [Visão Geral e Propósito](#-visão-geral-e-propósito)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Suporte Multiplataforma (Web, Android e iOS)](#-suporte-multiplataforma-web-android-e-ios)
- [Estrutura de Código](#-estrutura-de-código)
- [Comandos de Execução e Build](#-comandos-de-execução-e-build)

---

## 🎯 Visão Geral e Propósito

O **App Protótipo** funciona como um showroom executável completo da experiência do produto Pé na Areia. Ele permite que investidores, designers, desenvolvedores e parceiros comerciais naveguem por todas as etapas da experiência — tanto do cliente quanto do entregador — sem exigir uma instância do backend ativa ou conexão com o banco de dados.

---

## 🚀 Funcionalidades Principais

### 1. Mapa de Fluxo do Cliente (Banista)
Navegação guiada pelas 5 etapas fundamentais:
- **Quiosques & Cardápio:** Seleção de produtos, porções, água de coco fresca e açaí com opção de embalagem retornável/sustentável.
- **Localização na Areia:** Simulação do pin do guarda-sol na praia de Santos e postos de salvamento.
- **Checkout & Pix:** Simulação da cobrança Pix com chave Copia e Cola e QR Code.
- **Acompanhamento (Live Tracking):** Barra de progresso de status e cálculo dinâmico de distância restante.
- **Farol Visual (`SignalBeacon`):** Demonstração da tela cheia solar de alta visibilidade com alternância de cores solares e temporizador.

### 2. Mapa de Fluxo do Entregador (Courier)

Navegação pelas 4 etapas de logística:

- **Fila de Pedidos:** Listagem de pedidos com cards informativos e tempo de espera.
- **Rota & Modo Bússola:** Visualização do radar geodésico na areia e cálculo de azimute.
- **Confirmação:** Simulação do Geofencing de entrega.
- **Chat de Praia:** Mensagens rápidas e contextualizadas com o cliente.

### 3. Tela de Boas-Vindas e Splash Sustentável

- Tela de apresentação com o tema de **Entrega Sustentável na Praia de Santos**, valorizando o cuidado ambiental da orla e o comércio local.

---

## 🌐 Suporte Multiplataforma (Web, Android e iOS)

O protótipo foi projetado para rodar nativamente em:

- **Navegadores Web (Flutter Web):** Ideal para apresentações em reuniões, pitches ou demonstrações em desktops sem instalação.
- **Smartphones Android (.apk):** Teste tátil e de responsividade em aparelhos reais.
- **iOS:** Simulação no Xcode e dispositivos Apple.

---

## 🧩 Estrutura de Código

```text
apps/app_prototipo/
├── lib/
│   ├── main.dart                                # Ponto de entrada
│   ├── app/
│   │   ├── app.dart                             # Configuração MaterialApp com tema core_shared
│   │   ├── dependencies.dart                    # Injeção de dependências
│   │   └── routes.dart                          # Rotas (/splash, /login, /prototype)
│   └── presentation/
│       ├── splash/
│       │   └── splash_screen.dart               # Splash oficial de Santos
│       ├── auth/
│       │   └── login_screen.dart                # Demonstração da tela de login
│       └── prototype/
│           └── prototype_screen.dart            # Painel interativo com abas de fluxo e simulação
├── web/                                         # Configuração e index.html para Flutter Web
└── test/                                        # 9 testes automatizados
```

---

## 🚀 Comandos de Execução e Build

```powershell
Set-Location apps/app_prototipo

# Instalar dependências
flutter pub get

# Executar suíte de testes
flutter test

# Verificar lint
flutter analyze

# Executar no navegador Google Chrome (Flutter Web)
flutter run -d chrome

# Compilar para Web estática (pronto para hospedar em Vercel/Firebase)
flutter build web --release

# Compilar APK Android para distribuição rápida de testes
flutter build apk --release
```
