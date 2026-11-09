/// Ciclo de vida de um pedido, espelhando o enum do backend.
///
/// `desconhecido` existe como fallback defensivo: se o backend evoluir o enum
/// de status antes do app, a leitura de um pedido nao quebra.
enum OrderStatus {
  criado('CRIADO'),
  pago('PAGO'),
  emPreparo('EM_PREPARO'),
  prontoEntrega('PRONTO_ENTREGA'),
  aCaminho('A_CAMINHO'),
  chegouNoLocal('CHEGOU_NO_LOCAL'),
  entregue('ENTREGUE'),
  cancelado('CANCELADO'),
  naoEncontrado('NAO_ENCONTRADO'),
  desconhecido('DESCONHECIDO');

  const OrderStatus(this.wireValue);

  /// Valor exato trafegado na API.
  final String wireValue;

  /// Descrição em texto livre para exibição ao cliente (nunca constante).
  String get customerLabel {
    switch (this) {
      case OrderStatus.criado:
        return 'Aguardando confirmação do pagamento';
      case OrderStatus.pago:
        return 'Pagamento confirmado! Aguardando preparo no restaurante';
      case OrderStatus.emPreparo:
        return 'Seu pedido está sendo preparado no restaurante';
      case OrderStatus.prontoEntrega:
        return 'O pedido está sendo retirado do local de entrega';
      case OrderStatus.aCaminho:
        return 'Entregador a caminho da sua localização na areia';
      case OrderStatus.chegouNoLocal:
        return 'Entregador chegou no local! Acione o sinalizador';
      case OrderStatus.entregue:
        return 'Pedido entregue com sucesso!';
      case OrderStatus.cancelado:
        return 'Pedido cancelado';
      case OrderStatus.naoEncontrado:
        return 'Cliente não encontrado no local';
      case OrderStatus.desconhecido:
        return 'Acompanhando pedido';
    }
  }

  /// Descrição em texto livre para exibição ao entregador (nunca constante).
  String get courierLabel {
    switch (this) {
      case OrderStatus.criado:
        return 'Aguardando pagamento';
      case OrderStatus.pago:
        return 'Pago — aguardando preparo';
      case OrderStatus.emPreparo:
        return 'Em preparo no restaurante';
      case OrderStatus.prontoEntrega:
        return 'Pronto no restaurante para retirada';
      case OrderStatus.aCaminho:
        return 'Em rota de entrega na areia';
      case OrderStatus.chegouNoLocal:
        return 'No local do cliente';
      case OrderStatus.entregue:
        return 'Entregue';
      case OrderStatus.cancelado:
        return 'Cancelado';
      case OrderStatus.naoEncontrado:
        return 'Não encontrado';
      case OrderStatus.desconhecido:
        return 'Em andamento';
    }
  }

  static OrderStatus fromWire(String value) => values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => desconhecido,
      );
}
