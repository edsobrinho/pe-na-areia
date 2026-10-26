# Pé na Areia · Portal Web (React)

Portal web do ecossistema **Pé na Areia**, desenvolvido em **React 19**, **TypeScript** e **Vite**. A aplicação atende clientes que realizam pedidos diretamente na areia da praia de Santos, operadores de quiosques que configuram taxas e cardápios, e administradores que gerenciam os canais de parceria da plataforma.

---

## 📌 Sumário

- [Visão Geral e Funcionalidades](#-visão-geral-e-funcionalidades)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração de Ambiente](#-configuração-de-ambiente)
- [Como Executar a Aplicação](#-como-executar-a-aplicação)
  - [1. Instalar as dependências](#1-instalar-as-dependências)
  - [2. Subir em modo de desenvolvimento](#2-subir-em-modo-de-desenvolvimento)
  - [3. Gerar build para produção](#3-gerar-build-para-produção)
  - [4. Visualizar o build de produção (Preview)](#4-visualizar-o-build-de-produção-preview)
  - [5. Análise estática de código (Lint)](#5-análise-estática-de-código-lint)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Perfis de Acesso](#-perfis-de-acesso)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Integração com o Backend e CORS](#-integração-com-o-backend-e-cors)
- [Resolução de Problemas](#-resolução-de-problemas)

---

## 🎯 Visão Geral e Funcionalidades

O portal web complementa o aplicativo mobile (Flutter) e oferece três interfaces principais baseadas nas permissões do usuário autenticado:

1. **Área do Cliente (Pedir)**:
   - Navegação por canais de venda e parcerias ativas.
   - Consulta ao cardápio de quiosques parceiros com suporte a produtos com embalagens sustentáveis/retornáveis.
   - Carrinho de compras com validação de regras de pedido mínimo e horários de atendimento.
   - **Localização interativa via Google Maps**: seleção de pin na praia com detecção automática do posto de salvamento/referência mais próximo na orla de Santos.
   - Envio de foto do local (upload integrado via Cloudinary no backend) e instruções descritivas.
   - Registro de pedido com seleção de pagamento (PIX ou Cartão).

2. **Área do Operador (Meu Quiosque)**:
   - Disponível para usuários com a role `KIOSK_OPERATOR`.
   - Parametrização por canal de venda: comissão, taxa de entrega e definição do pagador (cliente ou quiosque).
   - Configuração de pedido mínimo, limite de itens, horário de abertura/fechamento e tempo estimado de preparo.
   - Ativação/desativação de itens do cardápio e aplicação de filtros por categoria.
   - **Simulador de repasse**: cálculo prévio de comissões e valores líquidos do quiosque.

3. **Área Administrativa (Administração)**:
   - Disponível para usuários com a role `ADMIN`.
   - Criação e ativação de novos canais de parcerias globais.
   - Vinculação de contas de usuários como operadores responsáveis por quiosques específicos.

---

## 💻 Tecnologias Utilizadas

- **[React 19](https://react.dev/)** — Biblioteca para construção de interfaces reativas.
- **[TypeScript](https://www.typescriptlang.org/)** — Tipagem estática e segurança em tempo de desenvolvimento.
- **[Vite 8](https://vite.dev/)** — Ferramenta de build e servidor de desenvolvimento ultrarrápido com Hot Module Replacement (HMR).
- **[@googlemaps/js-api-loader](https://www.npmjs.com/package/@googlemaps/js-api-loader)** — Carregamento dinâmico e otimizado da Google Maps JavaScript API.
- **[Oxlint](https://oxc.rs/)** — Linter de alto desempenho focado em JavaScript/TypeScript e boas práticas com React.

---

## 📋 Pré-requisitos

Antes de iniciar, certifique-se de possuir instalado em sua máquina:

- **Node.js**: versão `18.x`, `20.x` ou superior (recomendado `20.x` LTS ou mais recente).
- **Gerenciador de pacotes**: `npm` (incluído com o Node.js), `pnpm` ou `yarn`.
- **Backend Pé na Areia** em execução (Spring Boot API em `http://localhost:8080`). Consulte o [README principal](../README.md) para subir via Docker Compose.
- **Chave de API do Google Maps** *(opcional para navegação básica, obrigatória para confirmação de pedidos via mapa)*.

---

## ⚙️ Configuração de Ambiente

Na pasta `web`, crie o arquivo `.env.local` a partir do modelo existente `.env.example`:

### No Windows (PowerShell):
```powershell
Set-Location web
if (-not (Test-Path .env.local)) { Copy-Item .env.example .env.local }
```

### No Linux / macOS (Bash):
```bash
cd web
cp -n .env.example .env.local
```

Edite o arquivo `.env.local` conforme as suas necessidades:

```env
# URL base da API Spring Boot do Pé na Areia
VITE_API_BASE_URL=http://localhost:8080

# Chave da Google Maps JavaScript API (necessária para marcação do pin de entrega)
VITE_GOOGLE_MAPS_API_KEY=sua_chave_google_maps_aqui
```

> [!TIP]
> Se você não possuir uma chave do Google Maps imediatamente, ainda poderá navegar pelo catálogo, fazer login e acessar o painel de operador/admin. O mapa exibirá um aviso explicativo e a confirmação de checkout que exige pin ficará suspensa até a configuração da chave.

---

## 🚀 Como Executar a Aplicação

Certifique-se de estar no diretório `web`:

```powershell
cd web
```

### 1. Instalar as dependências

```bash
npm install
```

### 2. Subir em modo de desenvolvimento

Inicie o servidor de desenvolvimento do Vite:

```bash
npm run dev
```

Por padrão, a aplicação estará acessível em:
👉 **[http://localhost:5173](http://localhost:5173)**

O servidor suporta atualização automática em tempo real (HMR) a cada arquivo salvo.

### 3. Gerar build para produção

Para validar os tipos com TypeScript e compilar os arquivos otimizados e minificados para o diretório `dist/`:

```bash
npm run build
```

### 4. Visualizar o build de produção (Preview)

Para testar localmente o resultado compilado exatamente como seria servido em ambiente de produção:

```bash
npm run preview
```

### 5. Análise estática de código (Lint)

Para verificar o código em busca de erros de tipagem, regras do React e problemas de sintaxe usando o Oxlint:

```bash
npm run lint
```

---

## 🔑 Variáveis de Ambiente

| Variável | Obrigatória | Padrão | Descrição |
|---|---|---|---|
| `VITE_API_BASE_URL` | Não | `http://localhost:8080` | Endpoint base da API REST do backend. |
| `VITE_GOOGLE_MAPS_API_KEY` | Sim (p/ checkout) | *(vazio)* | Chave de API da Google Cloud com a **Maps JavaScript API** ativada. |

> [!IMPORTANT]
> - Em produção, restrinja a chave da API do Google Maps por **HTTP referrers (sites)** (por exemplo: `https://seudominio.com/*` ou `http://localhost:5173/*` para testes locais).
> - Nunca versione arquivos `.env` ou `.env.local` contendo credenciais ou chaves reais.

---

## 👤 Perfis de Acesso

O fluxo de autenticação utiliza tokens JWT gerenciados via `sessionStorage`:

- **Cliente (`CLIENT`)**: Pode criar conta livremente na tela inicial através do formulário de cadastro ("Cadastre-se").
- **Operador de Quiosque (`KIOSK_OPERATOR`)**: Não é criado no cadastro público. Deve ser associado a um quiosque por um Administrador.
- **Administrador (`ADMIN`)**: Para cadastrar o primeiro administrador em ambiente local, crie uma conta de cliente comum e altere o atributo `role` para `ADMIN` diretamente no documento correspondente no MongoDB (banco `pe_na_areia`, coleção `users`). Ao fazer login novamente, a interface exibirá a aba **Administração**.

---

## 📂 Estrutura do Projeto

```text
web/
├── public/                # Arquivos públicos estáticos (favicon, ícones SVG)
├── src/
│   ├── assets/            # Imagens e vetores (hero banner, ilustrações)
│   ├── api.ts             # Cliente HTTP, funções da API REST e gerenciamento de sessão
│   ├── App.css            # Estilização completa do portal (design responsivo da praia)
│   ├── App.tsx            # Componente raiz contendo as telas (Pedir, Quiosque, Admin)
│   ├── index.css          # Reset de CSS básico e variáveis de tipografia
│   ├── main.tsx           # Ponto de entrada do React (DOM mount)
│   ├── MapPicker.tsx      # Componente com integração ao Google Maps e postos de referência
│   └── types.ts           # Interfaces e definições de tipos TypeScript do domínio
├── .env.example           # Exemplo de variáveis de ambiente
├── .gitignore             # Arquivos e diretórios ignorados pelo Git
├── .oxlintrc.json         # Configuração de regras do linter Oxlint
├── index.html             # Modelo HTML principal da aplicação Vite
├── package.json           # Dependências e scripts do projeto
├── tsconfig.json          # Configuração base do TypeScript
├── tsconfig.app.json      # Configuração TypeScript para o código da aplicação
└── vite.config.ts         # Configuração do Vite e plugins React
```

---

## 🌐 Integração com o Backend e CORS

Para que o portal web consiga realizar requisições à API Spring Boot sem erros de política de mesma origem (CORS):

1. Certifique-se de que o backend esteja rodando (geralmente via Docker Compose na porta `8080`).
2. Se o backend estiver configurado com a variável de ambiente `APP_CORS_ORIGINS`, inclua a URL do Vite:
   ```text
   APP_CORS_ORIGINS=http://localhost:5173
   ```
3. A documentação OpenAPI interativa do backend pode ser consultada em **`http://localhost:8080/docs`**.

---

## 🛠️ Resolução de Problemas

### 1. `ApiError: Falha na solicitação (403/401)` ou erro de conexão
- Verifique se o container do backend está em execução: `docker ps`.
- Confirme se a URL em `VITE_API_BASE_URL` no arquivo `.env.local` coincide com o endereço e porta da API.

### 2. Mapa do Google Maps não carrega ou exibe tela cinza
- Confirme se você preencheu `VITE_GOOGLE_MAPS_API_KEY` no `.env.local`.
- Lembre-se de reiniciar o servidor do Vite (`npm run dev`) após alterar qualquer variável de ambiente no `.env.local`.
- Verifique no console do navegador (F12) se há mensagens de erro da Google (como `ApiNotActivatedMapError` ou restrições de faturamento/referenciador).

### 3. A aba "Meu quiosque" ou "Administração" não aparece
- Essas abas só são exibidas para usuários autenticados com os perfis `KIOSK_OPERATOR` e `ADMIN`, respectivamente. Faça login com um usuário que possua esses privilégios.
