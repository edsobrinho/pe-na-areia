import '../utils/beach_compass.dart';
import 'geo_point.dart';
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

/// Mensagem rápida trocada entre cliente e entregador durante a entrega na praia.
class OrderMessage {
  const OrderMessage({
    required this.senderId,
    required this.senderRole,
    required this.texto,
    this.enviadoEm,
  });

  final String senderId;
  final String senderRole;
  final String texto;
  final DateTime? enviadoEm;
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
    this.partnershipId = '',
    this.courierId,
    this.itens = const [],
    required this.valorTotal,
    this.embalagemSustentavel = false,
    required this.formaPagamento,
    this.pago = false,
    this.pixTxId,
    this.pixCopiaECola,
    this.pixQrCodeBase64,
    this.pixExpiracao,
    this.localizacao,
    this.localizacaoEntregador,
    this.atualizadoEntregadorEm,
    this.alertaProximidadeEnviado = false,
    this.mensagens = const [],
    this.status = OrderStatus.criado,
    this.timeline = const OrderTimeline(),
    this.courierNome,
    this.courierTelefone,
    this.courierVeiculo,
  });

  final String id;
  final String userId;
  final String kioskId;
  final String partnershipId;

  /// Nulo ate um entregador aceitar o pedido.
  final String? courierId;
  final String? courierNome;
  final String? courierTelefone;
  final String? courierVeiculo;

  final List<OrderItem> itens;
  final double valorTotal;
  final bool embalagemSustentavel;
  final PaymentMethod formaPagamento;
  final bool pago;

  final String? pixTxId;
  final String? pixCopiaECola;
  final String? pixQrCodeBase64;
  final DateTime? pixExpiracao;

  /// Pin e referencia escolhidos pelo cliente (nulo apenas em payloads
  /// incompletos; o contrato atual sempre preenche).
  final OrderLocation? localizacao;

  /// Coordenada em tempo real do entregador na rota.
  final GeoPoint? localizacaoEntregador;
  final DateTime? atualizadoEntregadorEm;
  final bool alertaProximidadeEnviado;

  /// Mensagens rápidas trocadas entre cliente e entregador.
  final List<OrderMessage> mensagens;

  final OrderStatus status;
  final OrderTimeline timeline;

  String get descricaoLocal => localizacao?.descricaoLocal ?? '';
  String get fotoLocalUrl => localizacao?.fotoLocalUrl ?? '';

  /// Distância atual em metros entre o entregador e o pin do cliente na areia.
  double? get distanciaEntregadorMetros {
    final pin = localizacao;
    final courier = localizacaoEntregador;
    if (pin == null || courier == null) return null;
    return BeachCompass.distanceMeters(
      courier.latitude,
      courier.longitude,
      pin.latitude,
      pin.longitude,
    );
  }

  /// Regra de negócio (Item A): O cliente pode ativar o Sinalizador quando
  /// o status for CHEGOU_NO_LOCAL ou quando estiver A_CAMINHO a <= 60m.
  bool get podeAtivarSinalizador {
    if (status == OrderStatus.chegouNoLocal) return true;
    if (status == OrderStatus.aCaminho) {
      if (alertaProximidadeEnviado) return true;
      final dist = distanciaEntregadorMetros;
      if (dist != null && dist <= 60.0) return true;
    }
    return false;
  }
}
