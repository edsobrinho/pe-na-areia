# Pé na Areia

Aplicativo de pedidos e entregas para a orla de Santos. O cliente escolhe itens
de quiosques parceiros e marca no mapa o ponto exato da praia onde deseja
receber o pedido; o entregador consulta esse destino e confirma a entrega por
GPS. Este repositório reúne o app Flutter, o portal web React, a API Java e a
infraestrutura local.

Leia o [PRD do Pé na Areia](PRD.md) para conhecer o problema, os usuários,
requisitos, regras de negócio, critérios de aceite e evolução planejada do
produto.

## Estrutura

```text
pe-na-areia/
├── backend/         Java 21, Spring Boot, MongoDB, JWT e Cloudinary
├── frontend/        Flutter para Android e iOS
├── web/             React 19, TypeScript e Vite para clientes e quiosques
└── infrastructure/ Docker Compose e imagem local do backend
```

## Principais funcionalidades

### Para clientes

- Criar conta e entrar como cliente; a sessão JWT é guardada com segurança no
  dispositivo e usada nas chamadas autenticadas.
- Consultar quiosques parceiros e seus cardápios, escolher itens e quantidades,
  selecionar um canal de venda, informar PIX ou cartão como forma registrada e
  optar por embalagem sustentável quando disponível.
- Escolher o ponto de entrega em um mapa Google Maps interativo: tocar no mapa
  ou arrastar o marcador vermelho, consultar postos de referência próximos,
  informar uma descrição e, opcionalmente, anexar uma foto do local.
- Criar o pedido com o destino selecionado e acompanhar status, valor e pin;
  a consulta do status é atualizada manualmente no app.

### Para entregadores

- Criar conta ou entrar com perfil de entregador.
- Consultar pedidos disponíveis e entregas já atribuídas, incluindo o destino
  marcado em amarelo no mapa.
- Aceitar uma entrega, indicar chegada ao local e confirmar a conclusão usando
  a posição GPS atual do dispositivo.

### Regras e serviços do sistema

- O backend calcula o total usando os preços cadastrados no cardápio e valida
  quiosque, usuário, itens, posto de referência e localização.
- Os canais de venda têm ofertas e regras próprias por quiosque; o backend
  valida elegibilidade, horários, pedido mínimo e limite de unidades e grava
  um snapshot imutável da configuração e dos valores no pedido.
- Comissões e taxas são calculadas e registradas para cada pedido, mas não há
  cobrança ou repasse real nesta versão.
- O backend requer Java 21 e habilita virtual threads suportadas pelo Spring
  Boot para o processamento bloqueante das requisições.
- O pin deve estar a até 500 m do posto de referência escolhido.
- A confirmação da entrega só é aceita quando o GPS do entregador está dentro
  do raio configurado (60 m por padrão) do pin do cliente.
- A API usa JWT, MongoDB e armazenamento de fotos no Cloudinary; a
  documentação OpenAPI fica disponível em `/docs`.

### Migração do backend para Java 21

- O backend usa toolchain Java 21 e Gradle Wrapper 9.7.1 (`backend/gradlew`
  ou `backend/gradlew.bat`); o build de contêiner também compila e executa com
  Java 21.
- Virtual threads estão habilitadas por `spring.threads.virtual.enabled`.
  Elas são adequadas ao modelo Spring MVC usado aqui, que realiza chamadas
  bloqueantes a MongoDB e a serviços externos. O código não cria threads
  virtuais manualmente: o Spring gerencia as requisições.
- Os DTOs já usam `record`, e os `switch` existentes já usam expressões e
  sintaxe moderna; essas estruturas foram preservadas.
- Não foram forçados `Sequenced Collections` ou pattern matching para `switch`:
  o backend não tem acessos de coleção primeiro/último nem hierarquias de tipos
  que tornem essas construções mais claras. String Templates e Structured
  Concurrency ainda eram recursos preview no Java 21 e não foram habilitados
  em produção.

### Limites da versão atual

- PIX e cartão são opções registradas no pedido; **não há processamento de
  pagamento**. O backend atual marca o pedido como pago e em preparo ao criá-lo.
- A atualização do status no app é manual; não há atualização em tempo real nem
  rastreamento contínuo da posição do entregador.
- Chat e sinal de ajuda aparecem apenas no protótipo navegável, não como
  serviços reais conectados à API.
- O protótipo inicial usa dados demonstrativos. Para testar os fluxos reais,
  use **Entrar** e autentique uma conta cliente ou entregador.

## Backend e infraestrutura local

Requisitos: Docker com Docker Compose v2. Os comandos abaixo devem ser
executados na raiz do repositório. Copie o exemplo de configuração apenas se
ainda não existir um `.env` local. O Compose sobe o MongoDB como replica set de
nó único e só inicia a API depois que o banco estiver saudável:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose --env-file .env -f infrastructure/docker-compose.yml up --build -d
```

O arquivo `.env` é local e ignorado pelo Git. O valor de `JWT_SECRET` do
exemplo é apenas para desenvolvimento; substitua-o por um segredo forte de pelo
menos 32 caracteres antes de usar em qualquer ambiente compartilhado. As
variáveis `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` e
`CLOUDINARY_API_SECRET` são opcionais para iniciar a API, mas necessárias para
uploads de fotos; sem elas, esse endpoint responde com serviço indisponível.

Confira o estado dos serviços e os logs:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml ps
docker compose --env-file .env -f infrastructure/docker-compose.yml logs -f backend
```

Após a inicialização, a API fica disponível em `http://localhost:8080`, a
documentação em `http://localhost:8080/docs` e o MongoDB em
`mongodb://localhost:27017/pe_na_areia?replicaSet=rs0`. Os dados persistem no
volume Docker `pe-na-areia-mongodb-data`. O seed dos postos de salvamento é
executado automaticamente na inicialização.

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml down
```

O comando `down` mantém os dados do banco; para removê-los também, use
`docker compose --env-file .env -f infrastructure/docker-compose.yml down -v`.

Para desenvolvimento sem Docker, instale Java 21. No PowerShell:

```powershell
Set-Location backend
.\gradlew.bat bootRun
```

No host, o backend usa por padrão
`mongodb://localhost:27017/pe_na_areia?replicaSet=rs0&directConnection=true`.
Para iniciar somente o MongoDB pelo Compose antes do `bootRun`, execute na raiz
do repositório:

```powershell
docker compose --env-file .env -f infrastructure/docker-compose.yml up -d mongodb
```

O Gradle Wrapper do backend e o wrapper Android do frontend usam Gradle 9.7.1.

Para outros ambientes, configure `MONGODB_URI` para um replica set ou cluster
compatível com transações. Em bancos já existentes, crie os novos índices de
paginação com `_id` e remova, após confirmar que os novos foram criados, os
índices antigos `status_created_desc_idx` e
`courier_status_created_desc_idx` da coleção `orders`.

Para rodar os testes:

```powershell
Set-Location backend
.\gradlew.bat test
```

## Frontend

Requisitos: Flutter 3.29+ e uma chave de API do Google Maps configurada para
Android/iOS.

Ao abrir, o app mostra um protótipo navegável com abas para o mapa dos fluxos,
cliente e entregador. **Entrar** abre os fluxos autenticados conectados à API:
o cliente escolhe itens, fixa o pin no Google Maps e cria/acompanhada o pedido;
o entregador consulta o destino no mapa e confirma a entrega por GPS. Pagamentos
reais, chat e sinal de ajuda ainda não são fornecidos pela API. Consulte o
[guia do frontend](frontend/README.md) para configurar a chave do Google Maps.

```powershell
Set-Location frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` aponta para o computador host no emulador Android. No simulador iOS
ou em um dispositivo físico, use o endereço acessível do servidor.

### Portal web

O portal React atende clientes e operadores de quiosque sem substituir o app
Flutter. Requer Node.js compatível com Vite. Copie `web/.env.example` para
`web/.env.local`, configure a URL da API e uma chave restrita do Google Maps
JavaScript API, e então execute:

```powershell
Set-Location web
npm.cmd install
npm.cmd run dev
```

O portal fica em `http://localhost:5173`. Sem `VITE_GOOGLE_MAPS_API_KEY`, o
catálogo e a administração continuam disponíveis, mas o checkout web fica
desabilitado porque não é possível confirmar o pin. Restrinja a chave do Maps
por referenciador HTTP e habilite a Maps JavaScript API; não versione chaves
reais.

Clientes podem criar a própria conta. Contas de operador não são criadas pelo
cadastro público: um administrador autenticado associa uma conta existente a
um quiosque. Para preparar o primeiro administrador, crie uma conta CLIENT e
altere seu campo `role` para `ADMIN` por um processo confiável de administração
do MongoDB; depois, entre novamente para receber um JWT com esse perfil. O
administrador pode criar canais e atribuir operadores pela área
**Administração**. Configure `APP_CORS_ORIGINS` com a lista separada por vírgula
dos domínios web permitidos em cada ambiente.

## Endpoints

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| POST | `/auth/register` | Público | Cadastra CLIENT ou COURIER e retorna JWT |
| POST | `/auth/login` | Público | Autentica e retorna JWT |
| GET | `/partnerships` | Público | Lista canais de venda ativos |
| GET | `/reference-points` | Público | Lista os postos ativos |
| GET | `/reference-points/nearby?lat=&lng=&raioKm=` | Público | Sugere postos próximos (lat -90..90, lng -180..180, raio 0.1..5 km) |
| GET | `/kiosks?partnershipId=` | Público | Lista quiosques e produtos elegíveis no canal |
| GET | `/kiosks/{id}/partnerships` | Público | Lista ofertas, taxas e restrições por quiosque |
| GET | `/kiosk/me/partnerships` | KIOSK_OPERATOR | Lista configurações do quiosque associado |
| PUT | `/kiosk/me/partnerships/{partnershipId}` | KIOSK_OPERATOR | Atualiza produtos, filtros, taxas e restrições |
| POST | `/kiosk/me/partnerships/{partnershipId}/preview` | KIOSK_OPERATOR | Calcula uma prévia sem criar pedido |
| POST | `/admin/partnerships` | ADMIN | Cria canal de venda |
| PUT | `/admin/partnerships/{partnershipId}` | ADMIN | Ativa ou pausa canal global |
| PATCH | `/admin/kiosk-operators` | ADMIN | Associa conta existente a um quiosque |
| GET | `/orders/available?size=50&cursor=` | COURIER | Lista pedidos prontos; usa `X-Next-Cursor` para buscar a próxima página (máximo 100) |
| GET | `/orders/courier/active?size=50&cursor=` | COURIER | Lista entregas em rota; usa `X-Next-Cursor` para buscar a próxima página (máximo 100) |
| POST | `/orders` | CLIENT | Exige `partnershipId`; valida oferta e grava snapshot/preços no servidor |
| GET | `/orders/{id}` | Dono ou entregador atribuído | Consulta o pedido |
| PATCH | `/orders/{id}/status` | Dono ou COURIER atribuído | Avança o status conforme as regras |
| POST | `/orders/{id}/confirm-delivery` | COURIER atribuído | Confirma a entrega dentro do raio GPS |
| POST | `/uploads/location-photo` | Autenticado | Envia foto do local ao Cloudinary |

O pedido é criado como pago e em preparo. O fluxo de status permitido é
`CRIADO → PAGO → EM_PREPARO → A_CAMINHO →
CHEGOU_NO_LOCAL → ENTREGUE`. O pedido só pode ser cancelado antes de sair para
entrega; a confirmação final exige a localização atual do entregador dentro do
raio definido por `app.delivery.confirmation-radius-meters` (60 m por padrão).
O JWT expira em 24 horas por padrão; configure `JWT_EXPIRATION_MS` para alterar
esse prazo.
