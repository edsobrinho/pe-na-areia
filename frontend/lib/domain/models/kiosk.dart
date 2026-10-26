import 'geo_point.dart';

/// Item do cardapio de um quiosque.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.nome,
    this.descricao = '',
    required this.preco,
    this.disponivel = true,
    this.category = 'Outros',
    this.returnablePackaging = false,
  });

  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final bool disponivel;
  final String category;
  final bool returnablePackaging;
}

/// Quiosque/restaurante parceiro da orla.
class Kiosk {
  const Kiosk({
    required this.id,
    required this.nome,
    this.pontoReferenciaId = '',
    this.localizacao,
    this.cardapio = const [],
    this.aceitaEmbalagemSustentavel = true,
    this.ativo = true,
  });

  final String id;
  final String nome;

  /// Id do posto de referencia mais proximo deste quiosque.
  final String pontoReferenciaId;

  final GeoPoint? localizacao;
  final List<MenuItem> cardapio;
  final bool aceitaEmbalagemSustentavel;
  final bool ativo;
}
