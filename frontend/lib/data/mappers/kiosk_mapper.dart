import '../../domain/models/kiosk.dart';
import 'geo_json_mapper.dart';

/// Mapeamento JSON explicito de [Kiosk] e [MenuItem].
abstract final class KioskMapper {
  static Kiosk fromJson(Map<String, dynamic> json) => Kiosk(
        id: json['id'] as String,
        nome: json['nome'] as String,
        pontoReferenciaId: json['pontoReferenciaId'] as String? ?? '',
        localizacao: GeoJsonMapper.geoPointFromJson(json['localizacao']),
        cardapio: (json['cardapio'] as List<dynamic>? ?? const [])
            .map((item) => MenuItemMapper.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        aceitaEmbalagemSustentavel:
            json['aceitaEmbalagemSustentavel'] as bool? ?? true,
        ativo: json['ativo'] as bool? ?? true,
      );
}

/// Mapeamento JSON explicito de [MenuItem].
abstract final class MenuItemMapper {
  static MenuItem fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String? ?? '',
        preco: (json['preco'] as num).toDouble(),
        disponivel: json['disponivel'] as bool? ?? true,
        category: json['category'] as String? ?? 'Outros',
        returnablePackaging: json['returnablePackaging'] as bool? ?? false,
      );
}
