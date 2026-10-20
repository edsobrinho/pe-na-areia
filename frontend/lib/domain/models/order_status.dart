/// Ciclo de vida de um pedido, espelhando o enum do backend.
///
/// `desconhecido` existe como fallback defensivo: se o backend evoluir o enum
/// de status antes do app, a leitura de um pedido nao quebra.
enum OrderStatus {
  criado('CRIADO'),
  pago('PAGO'),
  emPreparo('EM_PREPARO'),
  aCaminho('A_CAMINHO'),
  chegouNoLocal('CHEGOU_NO_LOCAL'),
  entregue('ENTREGUE'),
  cancelado('CANCELADO'),
  desconhecido('DESCONHECIDO');

  const OrderStatus(this.wireValue);

  /// Valor exato trafegado na API.
  final String wireValue;

  static OrderStatus fromWire(String value) => values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => desconhecido,
      );
}
