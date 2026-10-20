/// Posto de salvamento oficial da orla (dado praticamente estatico, vindo do seed
/// do backend). E a referencia que o cliente escolhe para o entregador encontra-lo.
class ReferencePoint {
  const ReferencePoint({
    required this.id,
    required this.numero,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.trecho = '',
    this.ativo = true,
  });

  final String id;

  /// Numero oficial do posto, ex: 6.
  final int numero;

  /// Nome de exibicao, ex: "Posto 6".
  final String nome;

  final double latitude;
  final double longitude;

  /// Bairro/trecho da orla, ex: "Gonzaga".
  final String trecho;

  final bool ativo;
}
