import '../../domain/models/order.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/order_status.dart';
import '../../domain/models/payment_method.dart';
import '../http/api_client.dart';
import '../http/api_exception.dart';
import '../mappers/order_mapper.dart';

/// Criacao e leitura de pedidos.
class OrderRepository {
  OrderRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/orders';

  Future<List<Order>> fetchAvailableOrders() =>
      _fetchOrderList('$_basePath/available');

  Future<List<Order>> fetchActiveCourierOrders() =>
      _fetchOrderList('$_basePath/courier/active');

  /// Busca os dados mais recentes de um pedido para seu acompanhamento.
  Future<Order> fetchOrderById(String orderId) async {
    final path = '$_basePath/$orderId';
    final json = await _apiClient.getJsonMap(path);
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }

  Future<List<Order>> _fetchOrderList(String path) async {
    final uri = _apiClient.resolve(path);
    final json = await _apiClient.getJsonList(path);
    try {
      return json
          .map((item) => OrderMapper.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on TypeError catch (error) {
      throw ApiParsingException(uri, error);
    }
  }

  /// Cria um pedido com pin de localizacao (`POST /orders`).
  /// O backend responde 201 com o pedido criado (status CRIADO, timeline, etc).
  Future<Order> createOrder({
    required String userId,
    required String kioskId,
    required String partnershipId,
    required List<OrderItemRequest> itens,
    required PaymentMethod formaPagamento,
    required OrderLocation localizacao,
    bool embalagemSustentavel = false,
  }) async {
    final body = OrderMapper.toCreateOrderJson(
      userId: userId,
      kioskId: kioskId,
      partnershipId: partnershipId,
      itens: itens,
      formaPagamento: formaPagamento,
      localizacao: localizacao,
      embalagemSustentavel: embalagemSustentavel,
    );
    final json = await _apiClient.postJson(
      _basePath,
      body,
      expectedStatuses: const {201},
    );
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(_basePath), error);
    }
  }

  /// Atualiza o status de um pedido conforme a máquina de transições do backend.
  Future<Order> updateStatus(String orderId, OrderStatus status) async {
    if (status == OrderStatus.desconhecido) {
      throw ArgumentError.value(status, 'status', 'Status de pedido inválido.');
    }
    final path = '$_basePath/$orderId/status';
    final json = await _apiClient.patchJson(path, {'status': status.wireValue});
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }

  /// Atualiza a localização GPS em tempo real do entregador na areia (`PATCH /orders/{id}/courier-location`).
  Future<Order> updateCourierLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    final path = '$_basePath/$orderId/courier-location';
    final json = await _apiClient.patchJson(path, {
      'latitude': latitude,
      'longitude': longitude,
    });
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }

  /// Envia uma mensagem rápida no pedido (`POST /orders/{id}/messages`).
  Future<Order> sendOrderMessage({
    required String orderId,
    required String texto,
  }) async {
    final path = '$_basePath/$orderId/messages';
    final json = await _apiClient.postJson(path, {'texto': texto});
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }

  /// Confirma a entrega com a posição GPS atual do entregador.
  Future<Order> confirmDelivery({
    required String orderId,
    required String courierId,
    required double latitude,
    required double longitude,
  }) async {
    final path = '$_basePath/$orderId/confirm-delivery';
    final json = await _apiClient.postJson(path, {
      'courierId': courierId,
      'courierLocation': {'lat': latitude, 'lng': longitude},
    });
    try {
      return OrderMapper.fromJson(json);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }
}
