import '../../domain/models/order_location.dart';
import 'geo_json_mapper.dart';

/// Mapeamento JSON explicito de [OrderLocation].
abstract final class OrderLocationMapper {
  /// Le a localizacao dentro de uma resposta de pedido: aceita `pinCliente` em
  /// GeoJSON (como o Mongo armazena) ou `{latitude, longitude}`. Retorna `null`
  /// quando o payload nao traz o pin.
  static OrderLocation? tryFromOrderJson(Map<String, dynamic> json) {
    final pin = GeoJsonMapper.geoPointFromJson(json['pinCliente']);
    if (pin == null) {
      return null;
    }
    return OrderLocation(
      latitude: pin.latitude,
      longitude: pin.longitude,
      pontoReferenciaId: json['pontoReferenciaId'] as String? ?? '',
      descricaoLocal: json['descricaoLocal'] as String? ?? '',
      fotoLocalUrl: json['fotoLocalUrl'] as String?,
      referenciaBarraca: json['referenciaBarraca'] as String?,
      complementoLocal: json['complementoLocal'] as String?,
      fotoVisaoPostoUrl: json['fotoVisaoPostoUrl'] as String?,
      fotoOutroReferencialUrl: json['fotoOutroReferencialUrl'] as String?,
      contatoNome: json['contatoNome'] as String?,
      contatoTelefone: json['contatoTelefone'] as String?,
      etiquetaLocal: json['etiquetaLocal'] as String?,
    );
  }

  /// Campos de localizacao do corpo de `POST /orders`, conforme contrato
  /// compartilhado com o backend (`pinCliente` como objeto lat/lng).
  static Map<String, dynamic> toOrderFields(OrderLocation localizacao) => {
        'pinCliente': {
          'latitude': localizacao.latitude,
          'longitude': localizacao.longitude,
        },
        'pontoReferenciaId': localizacao.pontoReferenciaId,
        'descricaoLocal': localizacao.descricaoLocal,
        if (localizacao.fotoLocalUrl != null)
          'fotoLocalUrl': localizacao.fotoLocalUrl,
        if (localizacao.referenciaBarraca != null &&
            localizacao.referenciaBarraca!.isNotEmpty)
          'referenciaBarraca': localizacao.referenciaBarraca,
        if (localizacao.complementoLocal != null &&
            localizacao.complementoLocal!.isNotEmpty)
          'complementoLocal': localizacao.complementoLocal,
        if (localizacao.fotoVisaoPostoUrl != null &&
            localizacao.fotoVisaoPostoUrl!.isNotEmpty)
          'fotoVisaoPostoUrl': localizacao.fotoVisaoPostoUrl,
        if (localizacao.fotoOutroReferencialUrl != null &&
            localizacao.fotoOutroReferencialUrl!.isNotEmpty)
          'fotoOutroReferencialUrl': localizacao.fotoOutroReferencialUrl,
        if (localizacao.contatoNome != null &&
            localizacao.contatoNome!.isNotEmpty)
          'contatoNome': localizacao.contatoNome,
        if (localizacao.contatoTelefone != null &&
            localizacao.contatoTelefone!.isNotEmpty)
          'contatoTelefone': localizacao.contatoTelefone,
        if (localizacao.etiquetaLocal != null &&
            localizacao.etiquetaLocal!.isNotEmpty)
          'etiquetaLocal': localizacao.etiquetaLocal,
      };
}
