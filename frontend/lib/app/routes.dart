/// Nomes das rotas nomeadas do app.
abstract final class AppRoutes {
  /// Protótipo navegável da experiência do cliente e entregador.
  static const String prototype = '/';

  /// Login/cadastro de clientes e entregadores.
  static const String login = '/login';

  /// Catalogo e pedidos do cliente autenticado.
  static const String customerHome = '/cliente';

  /// Painel de pedidos disponíveis e entregas atribuídas ao courier.
  static const String courierHome = '/entregador';

  /// Selecao de localizacao (pin no mapa) do fluxo do cliente.
  static const String locationSelection = '/selecao-local';
}
