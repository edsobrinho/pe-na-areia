# Pé na Areia · Plano de Deploy e Distribuição Contínua 🚀

Guia completo e detalhado de arquitetura de implantação, distribuição local para testes em rede Wi-Fi e publicação em ambiente de produção para todo o ecossistema **Pé na Areia**:
1. **Backend API** (Java 21 + Spring Boot 3.3 + MongoDB 7 Replica Set)
2. **Portal Web do Parceiro & Admin** (React 19 + TypeScript + Vite 8)
3. **App do Cliente** (`com.penaareia.cliente`)
4. **App do Entregador** (`com.penaareia.entregador`)
5. **Protótipo Interativo & Showcase** (`com.penaareia.prototipo`)
6. **Core Shared** (`packages/core_shared`)

---

## 📌 Sumário Executivo

- [1. Matriz de Componentes e Ambientes](#1-matriz-de-componentes-e-ambientes)
- [2. Deploy de Teste e Homologação na Rede Wi-Fi (LAN)](#2-deploy-de-teste-e-homologação-na-rede-wi-fi-lan)
  - [2.1 Topologia e Funcionamento](#21-topologia-e-funcionamento)
  - [2.2 Inicialização com 1 Clique (Scripts Automatizados)](#22-inicialização-com-1-clique-scripts-automatizados)
  - [2.3 Passo a Passo Manual e Regras de Firewall](#23-passo-a-passo-manual-e-regras-de-firewall)
  - [2.4 Central de Download dos Aplicativos (`serve-mobile.mjs`)](#24-central-de-download-dos-aplicativos-serve-mobilemjs)
- [3. Deploy de Produção: Backend Spring Boot](#3-deploy-de-produção-backend-spring-boot)
  - [3.1 Dockerfile Multi-Stage e Otimizações de JVM (Java 21)](#31-dockerfile-multi-stage-e-otimizações-de-jvm-java-21)
  - [3.2 Banco de Dados Geoespacial (MongoDB Atlas com Replica Set)](#32-banco-de-dados-geoespacial-mongodb-atlas-com-replica-set)
  - [3.3 Armazenamento em Nuvem (Cloudinary Oficial)](#33-armazenamento-em-nuvem-cloudinary-oficial)
  - [3.4 Provedor de Pagamentos Pix (PSP Oficial e Webhooks)](#34-provedor-de-pagamentos-pix-psp-oficial-e-webhooks)
  - [3.5 Variáveis de Ambiente de Produção](#35-variáveis-de-ambiente-de-produção)
  - [3.6 Opções de Hospedagem em Nuvem](#36-opções-de-hospedagem-em-nuvem)
- [4. Deploy de Produção: Portal Web B2B (React 19 + Vite)](#4-deploy-de-produção-portal-web-b2b-react-19--vite)
  - [4.1 Compilação e Build Estático](#41-compilação-e-build-estático)
  - [4.2 Hospedagem em Vercel, Netlify ou Cloudflare Pages](#42-hospedagem-em-vercel-netlify-ou-cloudflare-pages)
  - [4.3 Configuração de Fallback para SPA](#43-configuração-de-fallback-para-spa)
- [5. Publicação Mobile: Google Play Store e Apple App Store](#5-publicação-mobile-google-play-store-e-apple-app-store)
  - [5.1 Assinatura Digital de APK/AAB no Android (Keystore)](#51-assinatura-digital-de-apkaab-no-android-keystore)
  - [5.2 Publicação do App do Cliente (`com.penaareia.cliente`)](#52-publicação-do-app-do-cliente-compenaareiacliente)
  - [5.3 Publicação do App do Entregador e Requisitos de Segundo Plano](#53-publicação-do-app-do-entregador-e-requisitos-de-segundo-plano)
  - [5.4 Deploy Web do Protótipo Funcional (`com.penaareia.prototipo`)](#54-deploy-web-do-protótipo-funcional-compenaareiaprototipo)
- [6. Pipeline de CI/CD (GitHub Actions Automatizado)](#6-pipeline-de-cicd-github-actions-automatizado)
- [7. Checklist Final de Go-Live e Segurança](#7-checklist-final-de-go-live-e-segurança)

---

## 1. Matriz de Componentes e Ambientes

| Componente | Stack Técnica | Ambiente Local / Wi-Fi | Produção |
| :--- | :--- | :--- | :--- |
| **Backend API** | Java 21 / Spring Boot 3.3 | Docker (`:8080`) ou Gradle Host | AWS ECS / GCP Cloud Run / Render |
| **MongoDB** | MongoDB 7.0 (Replica Set `rs0`) | Docker Container (`:27017`) | MongoDB Atlas M10+ (Multi-AZ) |
| **Storage de Mídia** | Cloudinary SDK / HTTP API | Emulador local Node (`:8099`) | Cloudinary Cloud Oficial com SSL |
| **Portal Web** | React 19 / Vite 8 / TypeScript | Vite Dev Server (`:5173` ou host) | Vercel / Netlify / AWS CloudFront |
| **App Cliente** | Flutter 3.29 (`com.penaareia.cliente`) | APK instalado via Wi-Fi Hub (`:8088`) | Google Play Store + Apple App Store |
| **App Entregador** | Flutter 3.29 (`com.penaareia.entregador`) | APK instalado via Wi-Fi Hub (`:8088`) | Google Play (Trilha Fechada/Produção) |
| **Protótipo** | Flutter 3.29 (`com.penaareia.prototipo`) | Flutter Web (`:chrome`) ou APK (`:8088`) | Vercel Web Hosting / APK Showcase |

---

## 2. Deploy de Teste e Homologação na Rede Wi-Fi (LAN)

O ambiente de teste local permite validar a comunicação ponta a ponta entre celulares reais (banhista e entregador) e o backend Spring Boot rodando no computador de desenvolvimento, **sem necessidade de fios ou cabos USB**.

### 2.1 Topologia e Funcionamento

```text
                       [ Roteador Wi-Fi Local (ex: 192.168.0.1) ]
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            │                         │                         │
  [ PC do Desenvolvedor ]       [ Smartphone Cliente ]   [ Smartphone Entregador ]
  - IP: 192.168.0.4             - Conectado no Wi-Fi     - Conectado no Wi-Fi
  - Docker Compose:             - Baixa pelo navegador:  - Baixa pelo navegador:
    • MongoDB rs0 (:27017)        http://192.168.0.4:8088  http://192.168.0.4:8088
    • Cloudinary Mock (:8099)   - App Cliente aponta:    - App Entregador aponta:
    • Backend API (:8080)         http://192.168.0.4:8080  http://192.168.0.4:8080
  - Hub de Download (:8088)
```

### 2.2 Inicialização com 1 Clique (Scripts Automatizados)

1. Certifique-se de que o **Docker Desktop** está em execução.
2. Na raiz do projeto, execute no PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-wifi.ps1
```
*(Ou dê duplo clique no atalho `scripts\iniciar-wifi.bat`).*

**O que o script faz automaticamente:**
- Descobre o endereço IPv4 ativo do seu adaptador Wi-Fi (ex.: `192.168.0.4`).
- Sobe os containers Docker com as variáveis `CLOUDINARY_PUBLIC_BASE_URL` e `APP_CORS_ORIGINS` apontando para o seu IP.
- Inicia o servidor HTTP da Central de Download Mobile na porta `8088`.

### 2.3 Passo a Passo Manual e Regras de Firewall

Se for executar manualmente pela primeira vez no Windows, libere as portas no Firewall (PowerShell como Administrador):

```powershell
New-NetFirewallRule -DisplayName "Pe na Areia LAN Services" -Direction Inbound -LocalPort 8080,8088,8099,5173 -Protocol TCP -Action Allow
```

Em seguida, suba os containers:

```powershell
$wifiIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" }).IPAddress
$env:CLOUDINARY_PUBLIC_BASE_URL = "http://${wifiIp}:8099"
$env:APP_CORS_ORIGINS = "http://localhost:*,http://127.0.0.1:*,http://${wifiIp}:*"

docker compose -f infrastructure/docker-compose.yml up -d
```

### 2.4 Central de Download dos Aplicativos (`serve-mobile.mjs`)

Para compilar os APKs apontando para o IP do seu computador e servi-los para download:

```powershell
# Compila os 3 aplicativos automaticamente
powershell -ExecutionPolicy Bypass -File .\scripts\build-all.ps1 -Target all

# Inicia o servidor web responsivo na porta 8088
node scripts/serve-mobile.mjs
```

No celular conectado à mesma rede Wi-Fi, abra o navegador e acesse:
👉 **`http://<IP-DO-SEU-PC>:8088`** *(ex.: `http://192.168.0.4:8088`)*

A página exibirá os 3 cards com status de compilação, tamanho em MB e botão de download imediato:
- **🏖️ App do Cliente** (`cliente.apk`)
- **🧭 App do Entregador** (`entregador.apk`)
- **📱 Protótipo Interativo** (`prototipo.apk`)

---

## 3. Deploy de Produção: Backend Spring Boot

### 3.1 Dockerfile Multi-Stage e Otimizações de JVM (Java 21)

O backend possui um Dockerfile multi-stage em [`infrastructure/Dockerfile`](infrastructure/Dockerfile) que compila o código e gera uma imagem enxuta baseada em `eclipse-temurin:21-jre`:

```dockerfile
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace/backend
COPY backend/ ./
RUN chmod +x gradlew && ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/backend/build/libs/pe-na-areia-backend-*.jar app.jar
ENV JAVA_OPTS="-XX:+UseZGC -XX:+ZGenerational -XX:MaxRAMPercentage=75.0"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

> [!TIP]
> O uso do **ZGC Generacional** (`-XX:+UseZGC -XX:+ZGenerational`) reduz as pausas de coleta de lixo a menos de 1 milissegundo, garantindo latências ultra-baixas nos streams contínuos de Server-Sent Events (SSE).

### 3.2 Banco de Dados Geoespacial (MongoDB Atlas com Replica Set)

1. Crie um cluster no **MongoDB Atlas** (nível `M10` ou superior para ambiente de produção comercial).
2. O Atlas cria nativamente um cluster em **Replica Set de 3 nós**, atendendo ao requisito de transações multi-documento do Spring Data.
3. Obtenha a URI de conexão (ex.: `mongodb+srv://app_user:<senha>@cluster0.penaareia.mongodb.net/pe_na_areia?retryWrites=true&w=majority`).
4. **Índices Geoespaciais:** O Spring Data cria automaticamente os índices geoespaciais `2dsphere` definidos em `Kiosk`, `ReferencePoint` e `Order`.

### 3.3 Armazenamento em Nuvem (Cloudinary Oficial)

Para produção, substitua o emulador local pelas credenciais da sua conta no [Cloudinary](https://cloudinary.com/):
- `CLOUDINARY_CLOUD_NAME`: Nome do seu cloud (ex.: `penaareia-prod`)
- `CLOUDINARY_API_KEY`: Chave de API
- `CLOUDINARY_API_SECRET`: Segredo da API
- `CLOUDINARY_UPLOAD_PREFIX`: `https://api.cloudinary.com` (ou omita para usar a nuvem oficial padrão)

### 3.4 Provedor de Pagamentos Pix (PSP Oficial e Webhooks)

1. Cadastre-se em uma Instituição de Pagamento autorizada pelo BACEN com suporte a Pix imediato via API (ex.: **EFI / Gerencianet**, **Mercado Pago**, **Santander** ou **Itaú**).
2. Configure o webhook do PSP para apontar para:
   `https://api.penaareia.com.br/webhooks/pix`
3. Configure o cabeçalho de autenticação ou token compartilhado na variável `PIX_WEBHOOK_TOKEN`.

### 3.5 Variáveis de Ambiente de Produção

| Variável | Exemplo de Produção | Descrição |
| :--- | :--- | :--- |
| `SPRING_PROFILES_ACTIVE` | `prod` | Perfil ativo do Spring |
| `SERVER_PORT` | `8080` | Porta interna do container |
| `MONGODB_URI` | `mongodb+srv://...` | String de conexão MongoDB Atlas com TLS |
| `MONGODB_DATABASE` | `pe_na_areia_prod` | Nome do banco de produção |
| `JWT_SECRET` | *(chave 256 bits aleatória)* | Segredo de assinatura de tokens JWT |
| `JWT_EXPIRATION_MS` | `86400000` | Validade de 24 horas |
| `CLOUDINARY_CLOUD_NAME`| `penaareia-prod` | Identificador do cloud |
| `CLOUDINARY_API_KEY` | `987654321012345` | API Key oficial |
| `CLOUDINARY_API_SECRET`| `secret-key-prod-abc` | API Secret oficial |
| `PIX_WEBHOOK_TOKEN` | `whsec_k98sd7f98s7df98sd` | Token validado em `X-Webhook-Secret` |
| `APP_CORS_ORIGINS` | `https://admin.penaareia.com.br,https://quiosques.penaareia.com.br` | Domínios autorizados para CORS |

### 3.6 Opções de Hospedagem em Nuvem

- **GCP Cloud Run / AWS App Runner:** Excelente para deploy serverless de containers. Basta conectar o repositório ou imagem Docker e configurar as variáveis de ambiente.
- **Render / Railway:** Implantação rápida com suporte nativo a Docker e SSL automático.
- **AWS ECS Fargate / Kubernetes:** Recomendado para escalabilidade horizontal avançada com balanceador de carga ALB e terminação SSL.

---

## 4. Deploy de Produção: Portal Web B2B (React 19 + Vite)

### 4.1 Compilação e Build Estático

```powershell
Set-Location web
npm install
npm run build
```
O build estático otimizado é gerado na pasta `web/dist/`.

### 4.2 Hospedagem em Vercel, Netlify ou Cloudflare Pages

Configure as seguintes variáveis de ambiente no painel de controle do provedor:

```env
VITE_API_BASE_URL=https://api.penaareia.com.br
```

- **Root Directory:** `web`
- **Build Command:** `npm run build`
- **Output Directory:** `dist`

### 4.3 Configuração de Fallback para SPA

Como o React Router lida com as rotas no frontend, requisições diretas a rotas como `/admin` ou `/kiosk/menu` devem retornar o `index.html`.

- **Para Vercel (`web/vercel.json`):**
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

- **Para Netlify (`web/public/_redirects`):**
```text
/*    /index.html   200
```

---

## 5. Publicação Mobile: Google Play Store e Apple App Store

### 5.1 Assinatura Digital de APK/AAB no Android (Keystore)

Para gerar uma chave de assinatura RSA de 2048 bits para cada aplicativo:

```powershell
keytool -genkey -v -keystore pe-na-areia-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias penaareia
```

Crie o arquivo `android/key.properties` dentro da pasta de cada app (`apps/app_cliente/android/key.properties` e `apps/app_entregador/android/key.properties`):

```properties
storePassword=sua_senha_do_keystore
keyPassword=sua_senha_do_alias
keyAlias=penaareia
storeFile=/caminho/absoluto/ou/relativo/pe-na-areia-release.jks
```

> [!CAUTION]
> **Nunca comite arquivos `.jks` ou `key.properties` no Git.** Eles já estão devidamente ignorados no `.gitignore`.

### 5.2 Publicação do App do Cliente (`com.penaareia.cliente`)

1. Gere o Android App Bundle de produção:
```powershell
Set-Location apps/app_cliente
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.penaareia.com.br
```
2. O arquivo gerado fica em:
   `apps/app_cliente/build/app/outputs/bundle/release/app-release.aab`
3. Suba o `.aab` na **Google Play Console** na faixa de Teste Fechado ou Produção.
4. Para iOS, abra `apps/app_cliente/ios` no **Xcode**, configure o Team ID e execute `Product > Archive` para distribuição via **TestFlight**.

### 5.3 Publicação do App do Entregador e Requisitos de Segundo Plano

1. Gere o App Bundle de produção:
```powershell
Set-Location apps/app_entregador
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.penaareia.com.br
```
2. **Declaração de Localização em Segundo Plano (Google Play Policy):**
   - No Google Play Console, vá em **Conteúdo do App > Permissões Sensíveis > Localização em segundo plano**.
   - **Finalidade:** Selecione *"Funcionalidade principal do app de entrega / logística"*.
   - **Vídeo de Demonstração Obrigatório:** Suba um vídeo de 30 a 60 segundos demonstrando que o entregador coloca o celular no bolso ou bloqueia a tela enquanto caminha na areia, e o cliente recebe a atualização de localização contínua até os 60 metros.

### 5.4 Deploy Web do Protótipo Funcional (`com.penaareia.prototipo`)

O protótipo pode ser hospedado como uma aplicação web estática para apresentações e demonstrações para parceiros comerciais:

```powershell
Set-Location apps/app_prototipo
flutter build web --release
```
Os arquivos gerados em `apps/app_prototipo/build/web` podem ser publicados diretamente no **Vercel**, **Firebase Hosting** ou **GitHub Pages**.

---

## 6. Pipeline de CI/CD (GitHub Actions Automatizado)

Para automatizar a validação e compilação de todo o monorepo a cada Pull Request ou commit na branch `main`, adicione o arquivo [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

```yaml
name: CI/CD Pipeline - Pé na Areia

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  backend-test:
    name: Backend (Java 21 & Spring Boot)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('backend/**/*.gradle*') }}
      - name: Run Backend Tests and JaCoCo Verification
        working-directory: backend
        run: ./gradlew check jacocoTestReport

  web-test:
    name: Web Portal (React 19 & TypeScript)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Install dependencies & Test
        working-directory: web
        run: |
          npm ci
          npm run lint
          npm test
          npm run build

  mobile-test:
    name: Mobile Ecosystem (Flutter 3.29)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.0'
          channel: 'stable'
          cache: true
      - name: Test Core Shared
        working-directory: packages/core_shared
        run: |
          flutter pub get
          flutter test
          flutter analyze
      - name: Test App Cliente
        working-directory: apps/app_cliente
        run: |
          flutter pub get
          flutter test
          flutter analyze
      - name: Test App Entregador
        working-directory: apps/app_entregador
        run: |
          flutter pub get
          flutter test
          flutter analyze
      - name: Test App Prototipo
        working-directory: apps/app_prototipo
        run: |
          flutter pub get
          flutter test
          flutter analyze
```

---

## 7. Checklist Final de Go-Live e Segurança

Antes de abrir a plataforma para clientes e parceiros reais na praia:

- [ ] **Segredo JWT:** Definir `JWT_SECRET` com cadeia criptográfica de 256 bits gerada via `openssl rand -hex 32`.
- [ ] **Certificados SSL/TLS:** Garantir HTTPS com TLS 1.3 obrigatório para todas as APIs (`https://api.penaareia.com.br`) e painel Web.
- [ ] **Configuração de CORS:** Restringir `APP_CORS_ORIGINS` exclusivamente aos domínios web de produção e domínios de homologação autorizados.
- [ ] **Webhook Pix:** Validar que o token `PIX_WEBHOOK_TOKEN` é mantido em cofre de segredos (ex.: AWS Secrets Manager ou Vault).
- [ ] **MongoDB Atlas:** Ativar backups automatizados em point-in-time e habilitar VPC Peering ou IP Access List restrito aos servidores de aplicação.
- [ ] **Políticas da Google Play:** Validar o envio das declarações de localização em segundo plano do `app_entregador`.
- [ ] **Monitoramento e Logs:** Configurar alertas de erro HTTP 5xx e monitorar métricas de consumo de memória da JVM.

