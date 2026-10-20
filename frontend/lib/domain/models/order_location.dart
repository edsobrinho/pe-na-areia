/// Localizacao escolhida pelo cliente na tela de pin do mapa.
///
/// Este e o resultado devolvido pela selecao de localizacao para o fluxo de
/// checkout e o trecho de localizacao do corpo de `POST /orders`.
class OrderLocation {
  const OrderLocation({
    required this.latitude,
    required this.longitude,
    required this.pontoReferenciaId,
    required this.descricaoLocal,
    this.fotoLocalUrl,
  }) : assert(
          descricaoLocal.length <= maxDescricaoLength,
          'descricaoLocal deve ter no maximo $maxDescricaoLength caracteres',
        );

  /// Limite de caracteres da descricao do local (contrato com o backend).
  static const int maxDescricaoLength = 140;

  final double latitude;
  final double longitude;
  final String pontoReferenciaId;
  final String descricaoLocal;

  /// URL publica da foto do local ja enviada para o storage (opcional).
  final String? fotoLocalUrl;
}
