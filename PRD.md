# PRD — Pé na Areia

**Versão:** 1.0  
**Data:** 17 de outubro de 2026  
**Status:** MVP em desenvolvimento

## 1. Resumo do produto

Pé na Areia é um aplicativo de pedidos e entregas pensado para praias urbanas,
começando pela orla de Santos. O cliente compra itens de quiosques participantes
e informa seu ponto exato na praia por meio de um pin no mapa, complementado
por um posto de referência, descrição e foto opcional. O entregador recebe o
destino no mapa, executa a entrega e confirma a conclusão com geolocalização.

O produto busca tornar possível receber um pedido em locais onde um endereço
postal convencional não identifica suficientemente o ponto de encontro, como
uma faixa de areia.

## 2. Problema e oportunidade

Pedidos feitos na praia têm dificuldade para comunicar com precisão o local de
entrega. Referências textuais podem ser ambíguas, o que aumenta o esforço para
cliente e entregador e pode causar atrasos ou entregas no ponto errado.

O Pé na Areia usa coordenadas, postos de referência próximos e informações
complementares para identificar o destino. Também aproxima a operação dos
quiosques e entregadores por meio de um fluxo de pedido e entrega dedicado à
orla.

## 3. Visão e objetivos

**Visão:** permitir que pessoas peçam de estabelecimentos da orla e recebam
diretamente no ponto em que estão na praia, com uma localização clara e
verificável.

### Objetivos do MVP

1. Permitir que o cliente descubra quiosques e itens disponíveis.
2. Capturar e persistir um destino de entrega preciso, ajustável no mapa.
3. Disponibilizar esse mesmo destino ao entregador responsável.
4. Criar uma sequência de estados do pedido com regras de acesso e transição.
5. Confirmar a entrega apenas quando o entregador estiver próximo ao pin.
6. Oferecer uma infraestrutura local reproduzível para desenvolver e validar o
   app e a API.

### Fora dos objetivos do MVP

- Processamento, captura ou estorno de pagamentos.
- Rastreamento contínuo do entregador ou atualização de status em tempo real.
- Chat cliente-entregador e sinal de emergência/ajuda.
- Operação de despacho avançada, otimização de rotas ou múltiplas paradas.
- Garantia de disponibilidade comercial, cobertura operacional ou SLA de
  entrega.

## 4. Usuários e necessidades

### Cliente na praia

- Quer encontrar opções de alimentação próximas.
- Precisa marcar seu ponto com mais precisão do que um endereço.
- Quer reconhecer e acompanhar o pedido até a entrega.
- Pode precisar complementar o pin com uma descrição ou foto.

### Entregador

- Precisa consultar pedidos que pode aceitar e os que já estão sob sua
  responsabilidade.
- Precisa identificar o pin e as instruções de localização sem ambiguidade.
- Precisa de um mecanismo confiável para registrar a chegada e confirmar a
  entrega no destino.

### Operador de quiosque (usuário indireto do MVP)

- Precisa manter quiosques, itens, preços e disponibilidade no backend.
- A interface de administração do catálogo não faz parte do app atual.

## 5. Escopo funcional

### 5.1 Conta e sessão

- Cadastro e login para os perfis `CLIENT` e `COURIER`.
- Autenticação da API com JWT.
- Armazenamento seguro do token no dispositivo e encerramento de sessão.

**Critérios de aceite**

- Um usuário autenticado como cliente chega ao fluxo de compras; um entregador
  chega ao painel de entregas.
- Endpoints protegidos exigem token válido e aplicam autorização por perfil e
  propriedade do pedido.

### 5.2 Catálogo e carrinho

- Carregar quiosques ativos e seus cardápios.
- Selecionar um quiosque, incluir/remover itens e ajustar quantidades.
- Selecionar a forma registrada no pedido (`PIX` ou `CARTAO`).
- Informar preferência por embalagem sustentável quando aceita pelo quiosque.
- Mostrar subtotal estimado; o backend é a fonte de verdade para o valor final.

**Critérios de aceite**

- Não é possível enviar um pedido sem ao menos um item.
- O backend rejeita itens indisponíveis, quantidades inválidas e quiosques
  inativos.
- O preço total é calculado no servidor, sem confiar em valores enviados pelo
  app.

### 5.3 Seleção do local de entrega

- Mostrar Google Maps centrado na posição atual do dispositivo ou em uma
  posição de fallback se a localização não estiver disponível.
- Permitir mover o destino tocando no mapa ou arrastando o marcador.
- Buscar postos de referência próximos ao pin e permitir escolher um.
- Permitir descrever o local (até 140 caracteres) e anexar uma foto opcional.
- Devolver as coordenadas, referência e instruções para a criação do pedido.

**Critérios de aceite**

- O pin confirmado corresponde às coordenadas enviadas no pedido.
- O pedido inclui o ID do posto selecionado; o backend valida que o pin fica a
  até 500 m desse posto.
- Se a localização do aparelho estiver indisponível, o cliente ainda pode
  selecionar manualmente o ponto no mapa.
- Se a chave ou os serviços do Google Maps não estiverem configurados, o app
  deve informar a limitação; os tiles dependem de chave válida, SDK habilitado e
  faturamento configurado no Google Cloud.

### 5.4 Criação e acompanhamento do pedido

- Criar o pedido autenticado, com cliente, quiosque, itens, forma registrada,
  preferência de embalagem e dados do local.
- Exibir o pedido criado, valor, estado, instruções e pin de entrega.
- Permitir consultar novamente o estado pela ação de atualizar.

**Critérios de aceite**

- O pedido pertence ao cliente autenticado.
- O cliente só consulta pedidos dos quais é dono.
- A resposta da API mantém as coordenadas do pin no formato geográfico
  armazenado pelo MongoDB e o app converte latitude/longitude corretamente.
- A tela deixa claro que a atualização de estado é manual nesta versão.

### 5.5 Operação do entregador

- Exibir pedidos disponíveis e entregas atribuídas ao entregador autenticado.
- Exibir o ponto de entrega no mapa com marcador amarelo e sua descrição.
- Permitir aceitar um pedido, marcar chegada e confirmar entrega.
- Usar a localização GPS atual no momento da confirmação.

**Critérios de aceite**

- Ao aceitar um pedido, o backend associa o entregador e muda seu estado
  operacional para em rota.
- Somente o entregador atribuído pode avançar os estados de entrega.
- A confirmação final é rejeitada fora do raio configurado (60 m por padrão).
- Após confirmar a entrega, o pedido passa a `ENTREGUE` e o entregador volta a
  ficar disponível.

### 5.6 Estados do pedido

O fluxo esperado pela API é:

`CRIADO → PAGO → EM_PREPARO → A_CAMINHO → CHEGOU_NO_LOCAL → ENTREGUE`

Cancelamento é permitido antes do início da entrega, conforme as regras do
backend. O pedido é criado atualmente já marcado como pago e em preparo; isso
**não significa que houve cobrança**.

## 6. Jornadas principais

### Jornada do cliente

1. Criar conta ou entrar como cliente.
2. Escolher quiosque e itens.
3. Selecionar opções do pedido.
4. Ajustar o pin no mapa, escolher posto de referência e informar detalhes.
5. Confirmar a criação do pedido.
6. Consultar o status e o destino no cartão de acompanhamento.

### Jornada do entregador

1. Criar conta ou entrar como entregador.
2. Consultar pedidos disponíveis e seus destinos.
3. Aceitar um pedido e iniciar a entrega.
4. Consultar novamente a entrega ativa, chegar ao local e confirmar a chegada.
5. Confirmar a entrega quando estiver próximo do pin.

## 7. Requisitos não funcionais

- **Segurança:** autenticação JWT; autorização no servidor; tokens armazenados
  com armazenamento seguro; segredos e chaves de API não devem ser versionados.
- **Integridade:** servidor valida permissões, disponibilidade, preço,
  coordenadas e transições de estado.
- **Privacidade:** localização do cliente é usada para atender e validar o
  pedido; limitar seu acesso ao cliente dono e ao entregador atribuído.
- **Resiliência:** erros de rede, permissões de GPS e ausência de localização
  devem ser comunicados sem apresentar ações como concluídas quando falharem.
- **Compatibilidade:** app Flutter para Android e iOS; API Spring Boot com
  MongoDB.
- **Configuração local:** Docker Compose para executar API e MongoDB; endpoints
  e passos de execução no README.
- **Mapas:** chave separada por plataforma, restrita conforme as recomendações
  do Google Cloud; API de mapas requer conectividade.

## 8. Métricas de sucesso sugeridas

As metas quantitativas devem ser acordadas antes de qualquer piloto:

- Taxa de pedidos criados sem erro sobre tentativas válidas.
- Percentual de pedidos com coordenadas e posto de referência válidos.
- Taxa de entregas confirmadas dentro do raio definido.
- Tempo entre aceitação pelo entregador e confirmação da entrega.
- Incidentes de localização incorreta ou necessidade de contato adicional.
- Erros de carregamento do catálogo, API e tiles do mapa.

## 9. Estado atual e lacunas

| Capacidade | Estado atual |
|---|---|
| Protótipo navegável com mapa dos fluxos e abas de cliente/entregador | Demonstração local |
| Cadastro/login de cliente e entregador | Integrado à API |
| Catálogo, seleção de itens e criação de pedido | Integrado à API |
| Pin interativo, posto de referência e instruções do local | Integrado; Google Maps requer chave válida |
| Anexo de foto do local | Integrado ao endpoint de upload; requer configuração Cloudinary |
| Mapa com destino no cliente e no entregador | Integrado aos fluxos reais |
| Atualização do status do pedido | Consulta manual; sem tempo real |
| Confirmação de entrega por GPS | Integrada e validada pelo backend |
| Cobrança PIX/cartão | Não implementada |
| Chat e sinal de ajuda | Apenas demonstração no protótipo |
| Administração de quiosques/cardápios | Não incluída no app |

## 10. Próximas etapas sugeridas

1. Executar testes em dispositivos Android e iOS com chaves de mapa válidas e
   permissões reais de localização.
2. Validar o fluxo completo com cliente e entregador em aparelhos separados.
3. Definir provedor e fluxo de pagamento antes de apresentar o pedido como
   efetivamente cobrado.
4. Definir a necessidade de atualização em tempo real e escolher mecanismo
   (por exemplo, WebSocket ou notificações).
5. Especificar requisitos, moderação, segurança e UX para chat e sinal de
   ajuda antes de conectá-los.
6. Planejar uma interface ou processo operacional para gestão do catálogo,
   disponibilidade e quiosques.

## 11. Dependências e riscos

- Disponibilidade e custo dos serviços Google Maps e Cloudinary.
- Qualidade do GPS em áreas abertas e precisão das coordenadas na praia.
- Adoção por quiosques e disponibilidade de entregadores na área.
- Conectividade móvel intermitente na orla.
- Risco de confusão entre forma de pagamento selecionada e pagamento realmente
  processado; a interface deve manter essa distinção explícita.
