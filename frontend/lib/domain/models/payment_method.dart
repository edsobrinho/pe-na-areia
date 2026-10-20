/// Forma de pagamento aceita no MVP (contrato fechado com o backend).
/// Pagamento real nao esta implementado no app.
enum PaymentMethod {
  pix('PIX'),
  cartao('CARTAO');

  const PaymentMethod(this.wireValue);

  /// Valor exato trafegado na API.
  final String wireValue;

  static PaymentMethod fromWire(String value) => values.firstWhere(
        (forma) => forma.wireValue == value,
        orElse: () => throw ArgumentError.value(
          value,
          'formaPagamento',
          'Forma de pagamento desconhecida',
        ),
      );
}
