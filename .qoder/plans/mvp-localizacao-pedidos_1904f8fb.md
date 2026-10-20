# MVP inicial do Pé na Areia

## Escopo e decisões

- Preservar a separação atual entre `backend` e `frontend` e remover apenas os diretórios vazios gerados com nomes literais de chaves.
- Manter no backend as camadas `controller`, `service`, `repository`, `dto`, `model`, `config` e `seed`.
- Organizar o Flutter em `data`, `domain` e `presentation`, migrando os arquivos existentes sem duplicar responsabilidades.
- Usar Cloudinary para gerar uma URL persistente da foto; credenciais ficam somente em variáveis de ambiente do backend.
- Implementar nesta etapa os quatro entregáveis solicitados. JWT, FCM, rastreamento e confirmação de entrega serão pontos de extensão documentados, sem implementação incompleta ou segurança simulada.

## Backend e documentos MongoDB

- Revisar `backend/src/main/java/com/penaareia/model` e completar `User`, `Courier`, `Kiosk`, `ReferencePoint` e `Order`, preservando `GeoJsonPoint` e índices `2dsphere`.
- Manter o histórico do usuário derivado por consulta de pedidos, evitando duplicar IDs de pedidos no documento `users`.
- Representar valores monetários com `BigDecimal` nos documentos, DTOs e cálculos.
- Completar enums e subdocumentos para veículo, disponibilidade, pagamento, status, itens e timeline.
- Garantir que `Order` exponha pin, posto, descrição, foto, embalagem sustentável, entregador e timestamps necessários no contrato de resposta.
- Manter o seed idempotente dos postos e sinalizar os dados aproximados que ainda precisam de validação oficial; não sobrescrever uma coleção já populada.

## Endpoints iniciais

- Consolidar `POST /orders` com validação em cascata dos itens, quantidade positiva, coordenadas válidas, descrição de até 140 caracteres, usuário existente, quiosque ativo, posto ativo e item disponível.
- Calcular preços e total exclusivamente no servidor, persistindo coordenadas na ordem longitude e latitude.
- Consolidar `GET /reference-points`, incluindo consulta opcional por proximidade e filtragem somente de pontos ativos.
- Consolidar `GET /kiosks`, retornando parceiros ativos e preservando a consulta por posto de referência.
- Padronizar respostas e erros por meio do `GlobalExceptionHandler`, sem expor detalhes internos.
- Atualizar anotações Swagger/OpenAPI e exemplos de payload para refletir os contratos reais.

## Upload da foto

- Adicionar configuração Cloudinary por `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` e `CLOUDINARY_API_SECRET`.
- Criar `POST /uploads/location-photo` como multipart, aceitando apenas imagens, com limite de tamanho e resposta contendo `secureUrl`.
- Encapsular o SDK em um serviço próprio para que o controller não dependa diretamente do provedor.
- Persistir somente a URL retornada no pedido; nenhuma credencial Cloudinary será enviada ao Flutter ou versionada.

## Flutter em arquitetura por camadas

- Criar modelos de domínio imutáveis para usuário, entregador, quiosque, item, posto, localização do pedido, pedido, timeline, status e pagamento.
- Criar modelos de dados com conversão JSON explícita e repositórios para catálogo, pontos de referência, pedidos e upload.
- Tornar o cliente HTTP injetável, adicionar timeout, erros tipados e suporte futuro a bearer token sem ativar autenticação falsa.
- Migrar a tela para `presentation/location`, separando estado e regras de busca da composição visual.
- Remover o teste legado incompatível e adicionar testes dos modelos, repositório e estado da tela.

## Tela de seleção de localização

- Exibir Google Maps com localização inicial do dispositivo e fallback seguro para a orla de Santos.
- Manter pin arrastável e também permitir reposicionamento por toque no mapa.
- Consultar o posto ativo mais próximo após estabilização da posição, cancelando ou ignorando respostas antigas para evitar seleção obsoleta.
- Exibir posto sugerido, distância, descrição limitada a 140 caracteres e captura opcional por câmera ou galeria.
- Fazer upload da foto ao confirmar; bloquear a confirmação enquanto localização, posto ou upload obrigatório em andamento não estiverem válidos.
- Retornar um `OrderLocation` completo, incluindo coordenadas, posto, descrição e URL da foto, para consumo posterior pelo checkout.
- Tornar a tela navegável a partir de uma rota intermediária válida, evitando executar `pop` na tela raiz.

## Configuração Android e iOS

- Configurar permissões de internet, localização e câmera no Android e as descrições equivalentes no iOS.
- Injetar a chave do Google Maps por propriedades locais no Android e configuração não versionada no iOS, sem incluir chave real no repositório.
- Inicializar o SDK do Google Maps nas duas plataformas e documentar somente os nomes das variáveis necessárias.
- Manter URLs locais de desenvolvimento configuráveis para emulador Android, simulador iOS e dispositivo físico.

## Testes e validação

- Criar testes unitários do `OrderService` para criação válida, cálculo do total, GeoJSON, referências inexistentes, entidades inativas, item indisponível e quantidade inválida.
- Criar teste de controller para resposta 201 e contrato de `POST /orders`, isolando MongoDB Atlas e o seeder.
- Testar serialização dos endpoints de quiosques e postos ativos.
- No Flutter, executar análise estática e testes de modelos, repositórios e comportamento da seleção de localização com dependências simuladas.
- Executar `mvn test`, `flutter analyze` e `flutter test` e corrigir todas as falhas relacionadas às alterações.
- Fazer verificação em navegador somente se houver uma execução Flutter Web disponível; a validação principal dos mapas será por build e configuração Android/iOS, pois o Google Maps SDK solicitado é móvel.

## Fora desta etapa

- Autenticação JWT operacional e derivação do usuário autenticado.
- Firebase Cloud Messaging e registro de tokens.
- Rastreamento em tempo real, chat, pagamento real, rota do entregador e confirmação geográfica de entrega.
- Esses itens permanecerão compatíveis com os contratos e a estrutura desta etapa, sem stubs que aparentem funcionalidade pronta.