import 'order_location.dart';
import 'order_status.dart';
import 'payment_method.dart';

/// Item de um pedido exatamente como o backend devolve na resposta.
class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
  });

  final String menuItemId;
  final String nome;
  final int quantidade;
  final double precoUnitario;
}

/// Item enviado na criacao de um pedido (`POST /orders`).
class OrderItemRequest {
  const OrderItemRequest({
    required this.menuItemId,
    required this.quantidade,
  }) : assert(quantidade > 0, 'quantidade deve ser um inteiro positivo');

  final String menuItemId;
  final int quantidade;
}

/// Marcadores de tempo da timeline de status do pedido.
/// Todos opcionais: cada um e preenchido quando o status correspondente ocorre.
class OrderTimeline {
  const OrderTimeline({
    this.criadoEm,
    this.pagoEm,
    this.emPreparoEm,
    this.aCaminhoEm,
    this.chegouNoLocalEm,
    this.entregueEm,
  });

  final DateTime? criadoEm;
  final DateTime? pagoEm;
  final DateTime? emPreparoEm;
  final DateTime? aCaminhoEm;
  final DateTime? chegouNoLocalEm;
  final DateTime? entregueEm;
}

/// Pedido criado pelo cliente. Nasce em `POST /orders` e volta com status,
/// estado de pagamento e timeline de acompanhamento.
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.kioskId,
    this.courierId,
    this.itens = const [],
    required this.valorTotal,
    this.embalagemSustentavel = false,
    required this.formaPagamento,
    this.pago = false,
    this.localizacao,
    this.status = OrderStatus.criado,
    this.timeline = const OrderTimeline(),
  });

  final String id;
  final String userId;
  final String kioskId;

  /// Nulo ate um entregador aceitar o pedido.
  final String? courierId;

  final List<OrderItem> itens;
  final double valorTotal;
  final bool embalagemSustentavel;
  final PaymentMethod formaPagamento;
  final bool pago;

  /// Pin e referencia escolhidos pelo cliente (nulo apenas em payloads
  /// incompletos; o contrato atual sempre preenche).
  final OrderLocation? localizacao;

  final OrderStatus status;
  final OrderTimeline timeline;

  String get descricaoLocal => localizacao?.descricaoLocal ?? '';
  String get fotoLocalUrl => localizacao?.fotoLocalUrl ?? '';
}
