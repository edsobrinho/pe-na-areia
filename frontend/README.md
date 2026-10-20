# Pé na Areia — Frontend

Aplicativo Flutter para pedidos e entregas na orla.

## Executar

Requisitos: Flutter 3.29+, o backend disponível e uma chave Google Maps
configurada para a plataforma desejada.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` aponta para o computador host no emulador Android. No simulador iOS
ou em um dispositivo físico, use o endereço acessível do servidor. Para subir a
API e o MongoDB localmente, consulte o [README da raiz](../README.md).

### Chave do Google Maps

Ative **Maps SDK for Android** e/ou **Maps SDK for iOS** no Google Cloud,
configure faturamento e restrinja a chave aos identificadores dos aplicativos.
Não versione chaves reais.

- **Android:** adicione `MAPS_API_KEY=SUA_CHAVE` ao arquivo
  `android/local.properties` (junto das configurações locais do SDK), ou defina
  a variável de ambiente `MAPS_API_KEY` antes de compilar.
- **iOS:** preencha `GMS_API_KEY = SUA_CHAVE` em
  `ios/Flutter/ApiKeys.xcconfig`; o arquivo é incluído pelos xcconfigs de
  Debug/Release e o AppDelegate passa a chave ao SDK.

Sem chave válida e os SDKs habilitados, a tela abre, mas os tiles do mapa não
carregam.

### Fluxo conectado

Depois do login de cliente, o app carrega `/kiosks`, permite escolher itens e
forma de pagamento, abre a seleção interativa do pin e cria o pedido em
`POST /orders`. O mapa de acompanhamento mostra o destino; use o botão atualizar
para consultar o estado mais recente em `GET /orders/{id}`. O painel do
entregador exibe o mesmo pin nos pedidos disponíveis e ativos. A confirmação
final continua validando a posição GPS do entregador no backend.

As opções de pagamento são dados do pedido: esta versão não processa cobranças.
Chat e sinal de ajuda permanecem apenas no protótipo, pois a API atual não
oferece esses endpoints.

## Protótipo navegável

A tela inicial apresenta três abas:

- **Mapa do fluxo**: telas do cliente e do entregador; nós e setas abrem o passo
  correspondente.
- **Cliente**: quiosque, localização, checkout, acompanhamento e sinal de
  suporte.
- **Entregador**: pedidos, rota, confirmação de entrega e chat.

O protótipo usa conteúdo e ações de demonstração. O botão **Entrar** abre a
autenticação conectada ao backend; catálogo, pedido, pin e rota do entregador
usam a API real pelo fluxo autenticado. A interface usa a paleta visual solicitada, com vermelho,
fundo cinza-claro, cards brancos, verde para estados positivos e amarelo para o
destino no mapa ilustrativo.

## Testes

```powershell
flutter analyze
flutter test
```
