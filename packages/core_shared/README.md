# Core Shared · Pé na Areia 🏖️

Módulo central compartilhado do ecossistema mobile **Pé na Areia**, consumido pelos três aplicativos Flutter independentes:

- **`apps/app_cliente`** (`com.penaareia.cliente`)
- **`apps/app_entregador`** (`com.penaareia.entregador`)
- **`apps/app_prototipo`** (`com.penaareia.prototipo`)

Centraliza os tokens visuais, componentes do Design System, modelos de domínio, cliente HTTP, utilitários geodésicos de navegação na areia, mappers de serialização JSON e validadores de formulários brasileiros, eliminando qualquer duplicação de código entre os apps.

---

## 📌 Sumário

- [Estrutura do Pacote](#-estrutura-do-pacote)
- [Módulos Exportados](#-módulos-exportados)
  - [1. Design System](#1-design-system)
  - [2. Modelos de Domínio e Utilitários Geodésicos](#2-modelos-de-domínio-e-utilitários-geodésicos)
  - [3. Camada de Dados e Rede](#3-camada-de-dados-e-rede)
  - [4. Formulários, Máscaras e Validações](#4-formulários-máscaras-e-validações)
- [Como Consumir nos Aplicativos](#-como-consumir-nos-aplicativos)
- [Exemplo de Uso em Código](#-exemplo-de-uso-em-código)
- [Comandos de Teste e Análise Estática](#-comandos-de-teste-e-análise-estática)

---

## 🧩 Estrutura do Pacote

```text
packages/core_shared/
├── lib/
│   ├── core_shared.dart             # Barril de exportação pública principal
│   ├── design_system/               # Identidade visual, cores, tipografia e widgets base
│   │   ├── app_colors.dart          # Paleta oficial (Sage & Apricot, tons solares e neutros)
│   │   ├── app_text_field.dart      # Input desacoplado com acessibilidade e feedback de erro
│   │   ├── app_theme.dart           # ThemeData Material 3 com personalização de componentes
│   │   └── pe_na_areia_logo.dart    # Logotipo vetorial nativo em CustomPainter (guarda-sol + sol)
│   ├── domain/
│   │   ├── geo.dart                 # Tipos geométricos e distâncias
│   │   ├── models/                  # Entidades imutáveis com equatable/copyWith
│   │   │   ├── auth_session.dart    # Sessão com token JWT e dados do usuário
│   │   │   ├── courier.dart         # Perfil do entregador e status
│   │   │   ├── geo_point.dart       # Coordenada latitude/longitude serializável
│   │   │   ├── kiosk.dart           # Quiosque, horário de atendimento e produtos
│   │   │   ├── order.dart           # Pedido completo com snapshot e Pix
│   │   │   ├── order_location.dart  # Detalhes do guarda-sol (posto, foto, descrição)
│   │   │   ├── order_status.dart    # Enum dos 7 estados do ciclo de entrega
│   │   │   ├── partnership.dart     # Canal de parceria (comissões e taxas)
│   │   │   ├── payment_method.dart  # PIX
│   │   │   ├── reference_point.dart # Postos de salvamento na praia
│   │   │   └── user.dart            # Entidade de usuário e perfil (roles)
│   │   └── utils/
│   │       └── beach_compass.dart   # Cálculo geodésico Haversine e azimute cardeal em português
│   ├── data/
│   │   ├── auth/
│   │   │   └── token_storage.dart   # Gerenciamento de token JWT em SharedPreferences
│   │   ├── http/
│   │   │   ├── api_client.dart      # Cliente HTTP com interceptor de autorização e timeout
│   │   │   └── api_exception.dart   # Tratamento tipado de erros HTTP e respostas da API
│   │   ├── mappers/                 # Deserialização e serialização JSON segura
│   │   ├── repositories/            # Contratos e implementações de repositórios REST
│   │   └── services/
│   │       └── location_service.dart# Abstração de GPS com geolocator
│   └── forms/
│       ├── formatters.dart          # Máscaras brasileiras (telefone, CPF, CEP, moeda)
│       └── validators.dart          # Validadores de entrada (e-mail, senha, telefone, etc.)
└── test/                            # 107 testes unitários automatizados
```

---

## 📦 Módulos Exportados

### 1. Design System

- **`AppColors`**: Paleta completa baseada no tema costeiro de Santos:
  - Primária: Verde Sage (`#4A6B5D`) e Laranja Damasco/Apricot (`#F28C38`).
  - Tons do Farol Visual: Laranja Neon (`#FF7A3D`), Amarelo Solar (`#FFD600`), Branco Puro e Azul Escuro (`#0D2830`).
  - Tons semânticos de status (sucesso, aviso, perigo e neutros de areia).
- **`PeNaAreiaLogo`**: Renderização 100% vetorial e nativa via Flutter `CustomPainter`, garantindo nitidez cristalina em qualquer densidade de tela sem carregar imagens pesadas.
- **`AppTheme`**: Configuração central do `ThemeData` para Material 3 com botões arredondados, elevações sutis e contrastes acessíveis.
- **`AppTextField`**: Componente de input reutilizável com foco customizado, formatação dinâmica e tratamento de erros.

### 2. Modelos de Domínio e Utilitários Geodésicos
- **`BeachCompass`**: Motor geodésico para navegação na faixa de areia:
  - `calculateDistanceMeters(start, end)`: Distância geodésica pela fórmula de Haversine em metros.
  - `calculateAzimuthDegrees(start, end)`: Rumo / azimute no intervalo de `0.0°` a `360.0°`.
  - `azimuthToDirectionLabel(azimuth)`: Tradução do ângulo para os 8 rumos da rosa dos ventos em português (*Norte*, *Nordeste*, *Leste*, *Sudeste*, *Sul*, *Sudoeste*, *Oeste*, *Noroeste*).
  - `formatNavigationInstruction(distance, azimuth, referenceName)`: Formatação amigável (ex.: *"A 45 m a Sudeste (135°) do Posto 4"*).
- **Modelos de Entidades**: Classes imutáveis com deserialização `fromJson`, serialização `toJson` e comparação de igualdade por valor.

### 3. Camada de Dados e Rede
- **`ApiClient`**: Wrapper robusto sobre `http.Client`:
  - Injeção automática do cabeçalho `Authorization: Bearer <token>` quando autenticado.
  - Conversão de exceções em `ApiException` fortemente tipadas com `statusCode` e mensagem de erro amigável.
  - Suporte a chamadas multipart para upload de fotos (`POST /uploads/location-photo`).
- **`TokenStorage`**: Abstração desacoplada para leitura, persistência e limpeza do token JWT do usuário em armazenamento local.

### 4. Formulários, Máscaras e Validações
- **`AppValidators`**: Validação de e-mail RFC 5322, complexidade mínima de senha, número de celular brasileiro com DDD, obrigatoriedade de campos e limite de 140 caracteres na descrição de referência do guarda-sol.
- **`AppFormatters`**: `TextInputFormatter` para aplicação instantânea da máscara de telefone `(XX) XXXXX-XXXX`.

---

## 🔌 Como Consumir nos Aplicativos

No arquivo `pubspec.yaml` de cada aplicativo:

```yaml
dependencies:
  flutter:
    sdk: flutter
  core_shared:
    path: ../../packages/core_shared
```

---

## 💡 Exemplo de Uso em Código

```dart
import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

void main() {
  // 1. Usando a paleta e tema compartilhados
  final theme = AppTheme.lightTheme;

  // 2. Calculando azimute e navegação na areia
  final courierPos = GeoPoint(latitude: -23.9680, longitude: -46.3320);
  final clientPin = GeoPoint(latitude: -23.9685, longitude: -46.3315);

  final distance = BeachCompass.calculateDistanceMeters(courierPos, clientPin);
  final azimuth = BeachCompass.calculateAzimuthDegrees(courierPos, clientPin);
  final instruction = BeachCompass.formatNavigationInstruction(
    distance,
    azimuth,
    'Posto 4',
  );

  print(instruction); // "A 75 m a Sudeste (135°) do Posto 4"
}
```

---

## 🧪 Comandos de Teste e Análise Estática

```powershell
Set-Location packages/core_shared

# Execução da suíte de 107 testes unitários
flutter test

# Análise de lint e boas práticas do Dart
flutter analyze
```
