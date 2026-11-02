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
    this.fotoUrl,
    this.destaque = false,
  });

  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final bool disponivel;
  final String category;
  final bool returnablePackaging;
  final String? fotoUrl;
  final bool destaque;
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
    this.fotoCapaUrl,
    this.logoUrl,
    this.descricaoCurta,
    this.avaliacaoMedia = 4.8,
    this.destaquePopular = true,
  });

  final String id;
  final String nome;

  /// Id do posto de referencia mais proximo deste quiosque.
  final String pontoReferenciaId;

  final GeoPoint? localizacao;
  final List<MenuItem> cardapio;
  final bool aceitaEmbalagemSustentavel;
  final bool ativo;

  /// Metadados da vitrine do quiosque no App do Cliente (v2.1).
  final String? fotoCapaUrl;
  final String? logoUrl;
  final String? descricaoCurta;
  final double avaliacaoMedia;
  final bool destaquePopular;

  /// Retorna a foto de capa do quiosque ou a primeira foto disponivel no cardapio.
  String? get imagemDestaqueUrl {
    if (fotoCapaUrl != null && fotoCapaUrl!.trim().isNotEmpty) {
      return fotoCapaUrl;
    }
    for (final item in cardapio) {
      if (item.fotoUrl != null && item.fotoUrl!.trim().isNotEmpty) {
        return item.fotoUrl;
      }
    }
    return null;
  }

  /// Categorias unicas disponiveis no cardapio deste quiosque.
  List<String> get categoriasDisponiveis {
    final seen = <String>{};
    for (final item in cardapio) {
      if (item.disponivel && item.category.trim().isNotEmpty) {
        seen.add(item.category.trim());
      }
    }
    return seen.toList(growable: false);
  }
}
