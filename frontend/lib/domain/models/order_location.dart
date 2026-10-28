/// Localizacao escolhida pelo cliente na tela de pin do mapa / Ponto na Praia.
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
    this.referenciaBarraca,
    this.complementoLocal,
    this.fotoVisaoPostoUrl,
    this.fotoOutroReferencialUrl,
    this.contatoNome,
    this.contatoTelefone,
    this.etiquetaLocal,
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

  /// URL publica da foto principal (Guarda-sol / Barraca) ja enviada para o storage (opcional).
  final String? fotoLocalUrl;

  /// Campos estruturados da Tela 1 — Ponto na Praia (v2.1).
  final String? referenciaBarraca;
  final String? complementoLocal;
  final String? fotoVisaoPostoUrl;
  final String? fotoOutroReferencialUrl;
  final String? contatoNome;
  final String? contatoTelefone;
  final String? etiquetaLocal;

  /// Rótulo amigável da etiqueta salva pelo banhista.
  String get etiquetaAmigavel => switch (etiquetaLocal) {
        'MEU_GUARDA_SOL' => 'Meu Guarda-sol',
        'BARRACA_FAMILIA' => 'Barraca da Família',
        'POINT_SURF' => 'Point do Surf',
        'OUTRO' => 'Outro Ponto',
        _ => 'Ponto na Areia',
      };
}
