# Pé na Areia

Aplicativo de pedidos e entregas para a orla de Santos. O cliente escolhe itens
de quiosques parceiros e marca no mapa o ponto exato da praia onde deseja
receber o pedido; o entregador consulta esse destino e confirma a entrega por
GPS. Este repositório reúne o app Flutter, a API Java e a infraestrutura local.

Leia o [PRD do Pé na Areia](PRD.md) para conhecer o problema, os usuários,
requisitos, regras de negócio, critérios de aceite e evolução planejada do
produto.

## Estrutura

```text
pe-na-areia/
├── backend/         Java 21, Spring Boot, MongoDB, JWT e Cloudinary
├── frontend/        Flutter para Android e iOS
└── infrastructure/ Docker Compose e imagem local do backend
```

## Principais funcionalidades

### Para clientes

- Criar conta e entrar como cliente; a sessão JWT é guardada com segurança no
  dispositivo e usada nas chamadas autenticadas.
- Consultar quiosques parceiros e seus cardápios, escolher itens e quantidades,
  selecionar PIX ou cartão como forma informada e optar por embalagem
  sustentável quando disponível.
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
- O backend requer Java 21 e habilita virtual threads suportadas pelo Spring
  Boot para o processamento bloqueante das requisições.
- O pin deve estar a até 500 m do posto de referência escolhido.
- A confirmação da entrega só é aceita quando o GPS do entregador está dentro
  do raio configurado (60 m por padrão) do pin do cliente.
- A API usa JWT, MongoDB e armazenamento de fotos no Cloudinary; a
  documentação OpenAPI fica disponível em `/docs`.

### Migração do backend para Java 21

- O backend usa toolchain Java 21 e Gradle Wrapper 8.10.2 (`backend/gradlew`
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

Requisitos: Docker com Docker Compose. Para executar a API diretamente no host,
instale Java 21; o Gradle Wrapper incluído no backend fornece o build.

Na raiz do projeto, inicie o MongoDB e a API:

```powershell
docker compose -f infrastructure/docker-compose.yml up --build
```

A API fica disponivel em `http://localhost:8080` e o MongoDB em
`mongodb://localhost:27017/pe_na_areia`. Os dados do banco persistem no volume
Docker `pe-na-areia-mongodb-data`. Para encerrar os servicos, use
`docker compose -f infrastructure/docker-compose.yml down`; para apagar tambem
os dados locais do banco, acrescente `-v`.

O segredo JWT padrao do Compose e apenas para desenvolvimento local; defina a
variavel `JWT_SECRET` com pelo menos 32 caracteres antes de usar outro ambiente.
As variaveis `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` e
`CLOUDINARY_API_SECRET` sao necessarias para upload de fotos; sem elas, o
endpoint responde com servico indisponivel. O seed dos postos de salvamento e
executado automaticamente quando a API inicia.

Alternativamente, rode apenas o banco e inicie a API no host:

```powershell
docker compose -f infrastructure/docker-compose.yml up -d mongodb
Set-Location backend
.\gradlew.bat bootRun
```

O backend local usa `mongodb://localhost:27017/pe_na_areia` por padrao; para
outro banco, configure `MONGODB_URI` e opcionalmente `MONGODB_DATABASE`.

Para rodar os testes:

```powershell
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

## Endpoints

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/auth/register` | Público | Cadastra CLIENT ou COURIER e retorna JWT |
| POST | `/auth/login` | Público | Autentica e retorna JWT |
| GET | `/reference-points` | Público | Lista os postos ativos |
| GET | `/reference-points/nearby?lat=&lng=&raioKm=` | Público | Sugere postos próximos |
| GET | `/kiosks` | Público | Lista quiosques, cardápios e itens |
| GET | `/orders/available` | COURIER | Lista pedidos prontos para entrega |
| GET | `/orders/courier/active` | COURIER | Lista entregas em rota do entregador |
| POST | `/orders` | CLIENT | Cria pedido com preço calculado pelo servidor |
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
