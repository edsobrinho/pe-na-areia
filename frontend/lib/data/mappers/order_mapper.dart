import '../../domain/models/order.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/order_status.dart';
import '../../domain/models/payment_method.dart';
import 'geo_json_mapper.dart';
import 'json_helpers.dart';
import 'order_location_mapper.dart';

/// Mapeamento JSON explicito de [Order] (resposta de `POST /orders` e
/// `GET /orders/{id}`).
abstract final class OrderMapper {
  static Order fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        kioskId: json['kioskId'] as String? ?? '',
        partnershipId: json['partnershipId'] as String? ?? '',
        courierId: json['courierId'] as String?,
        itens: (json['itens'] as List<dynamic>? ?? const [])
            .map((item) => _itemFromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
        embalagemSustentavel: json['embalagemSustentavel'] as bool? ?? false,
        // Tolerante a backends antigos: o contrato atual sempre envia a forma.
        formaPagamento: json['formaPagamento'] == null
            ? PaymentMethod.pix
            : PaymentMethod.fromWire(json['formaPagamento'] as String),
        pago: json['pago'] as bool? ?? false,
        pixTxId: json['pixTxId'] as String?,
        pixCopiaECola: json['pixCopiaECola'] as String?,
        pixQrCodeBase64: json['pixQrCodeBase64'] as String?,
        pixExpiracao: dateTimeFromJson(json['pixExpiracao']),
        localizacao: OrderLocationMapper.tryFromOrderJson(json),
        localizacaoEntregador:
            GeoJsonMapper.geoPointFromJson(json['localizacaoEntregador']),
        atualizadoEntregadorEm:
            dateTimeFromJson(json['atualizadoEntregadorEm']),
        alertaProximidadeEnviado:
            json['alertaProximidadeEnviado'] as bool? ?? false,
        mensagens: (json['mensagens'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_messageFromJson)
            .toList(growable: false),
        status: OrderStatus.fromWire(
          json['status'] as String? ?? OrderStatus.criado.wireValue,
        ),
        timeline: OrderTimelineMapper.fromJson(json['timeline']),
      );

  /// Corpo JSON de `POST /orders`, conforme contrato compartilhado com o backend.
  static Map<String, dynamic> toCreateOrderJson({
    required String userId,
    required String kioskId,
    required String partnershipId,
    required List<OrderItemRequest> itens,
    required PaymentMethod formaPagamento,
    required OrderLocation localizacao,
    bool embalagemSustentavel = false,
  }) =>
      {
        'userId': userId,
        'kioskId': kioskId,
        'partnershipId': partnershipId,
        'itens': itens
            .map((item) => {
                  'menuItemId': item.menuItemId,
                  'quantidade': item.quantidade,
                })
            .toList(growable: false),
        'formaPagamento': formaPagamento.wireValue,
        ...OrderLocationMapper.toOrderFields(localizacao),
        'embalagemSustentavel': embalagemSustentavel,
      };

  static OrderItem _itemFromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId'] as String? ?? '',
        nome: json['nome'] as String? ?? '',
        quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
        precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0,
      );

  static OrderMessage _messageFromJson(Map<String, dynamic> json) =>
      OrderMessage(
        senderId: json['senderId'] as String? ?? '',
        senderRole: json['senderRole'] as String? ?? 'CLIENT',
        texto: json['texto'] as String? ?? '',
        enviadoEm: dateTimeFromJson(json['enviadoEm']),
      );
}

/// Mapeamento JSON explicito de [OrderTimeline].
abstract final class OrderTimelineMapper {
  static OrderTimeline fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const OrderTimeline();
    }
    return OrderTimeline(
      criadoEm: dateTimeFromJson(value['criadoEm']),
      pagoEm: dateTimeFromJson(value['pagoEm']),
      emPreparoEm: dateTimeFromJson(value['emPreparoEm']),
      aCaminhoEm: dateTimeFromJson(value['aCaminhoEm']),
      chegouNoLocalEm: dateTimeFromJson(value['chegouNoLocalEm']),
      entregueEm: dateTimeFromJson(value['entregueEm']),
    );
  }
}
