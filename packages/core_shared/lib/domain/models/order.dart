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
    this.prontoEntregaEm,
    this.aCaminhoEm,
    this.chegouNoLocalEm,
    this.entregueEm,
  });

  final DateTime? criadoEm;
  final DateTime? pagoEm;
  final DateTime? emPreparoEm;
  final DateTime? prontoEntregaEm;
  final DateTime? aCaminhoEm;
  final DateTime? chegouNoLocalEm;
  final DateTime? entregueEm;
}

/// Avaliação de satisfação feita pelo cliente após a entrega do pedido (1 a 5 estrelas).
class OrderReview {
  const OrderReview({
    required this.notaPedido,
    required this.notaEntrega,
    this.comentario,
    this.avaliadoEm,
  })  : assert(notaPedido >= 1 && notaPedido <= 5, 'notaPedido deve estar entre 1 e 5'),
        assert(notaEntrega >= 1 && notaEntrega <= 5, 'notaEntrega deve estar entre 1 e 5');

  final int notaPedido;
  final int notaEntrega;
  final String? comentario;
  final DateTime? avaliadoEm;
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
    this.codigoEntrega,
    this.avaliacao,
    this.codigoPedido,
    this.numeroPedidoDiario,
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

  /// Código numérico de 4 dígitos para confirmação falada na areia.
  final String? codigoEntrega;

  /// Avaliação do cliente (1 a 5 estrelas) após a conclusão.
  final OrderReview? avaliacao;

  /// Código sequencial diário do pedido formatado (ex.: "#0001" a "#9999").
  final String? codigoPedido;

  /// Número sequencial diário do pedido (ex.: 1 a 9999).
  final int? numeroPedidoDiario;

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

  /// Indica se o pedido ainda está em andamento (não finalizado).
  bool get isActive =>
      status != OrderStatus.entregue &&
      status != OrderStatus.cancelado &&
      status != OrderStatus.naoEncontrado;

  /// Tempo decorrido desde a criação do pedido até a entrega ou instante atual.
  Duration elapsedDuration([DateTime? now]) {
    final start = timeline.criadoEm;
    if (start == null) return Duration.zero;
    final end = timeline.entregueEm ?? (now ?? DateTime.now());
    final diff = end.difference(start);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Cronômetro formatado em `mm:ss` para exibição em tempo real.
  String formatElapsed([DateTime? now]) {
    final d = elapsedDuration(now);
    final totalMinutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Indica se o pedido em andamento ultrapassou o limite de 28 minutos.
  bool isDelayed([DateTime? now]) =>
      isActive && elapsedDuration(now).inMinutes >= 28;

  /// Código numérico limpo do pedido (sem exibir a chave hexadecimal do banco).
  /// NUNCA inspeciona ou retorna o [codigoEntrega].
  String get codigoCurtoPedido {
    if (codigoPedido != null && codigoPedido!.trim().isNotEmpty) {
      return codigoPedido!.replaceAll('#', '').trim();
    }
    if (id.isEmpty) return '0000';
    final hash = id.codeUnits.fold<int>(
      0,
      (acc, unit) => ((acc * 31) + unit) & 0x7fffffff,
    );
    return (1000 + (hash % 9000)).toString();
  }

  /// Código sequencial formatado para exibição nas telas (ex.: "#0001").
  String get codigoFormatado => (codigoPedido != null && codigoPedido!.trim().isNotEmpty)
      ? (codigoPedido!.startsWith('#') ? codigoPedido! : '#${codigoPedido!.trim()}')
      : '#$codigoCurtoPedido';

  /// Indica se o chat em tempo real está ativo para troca de mensagens.
  bool get isChatActive =>
      status == OrderStatus.prontoEntrega ||
      status == OrderStatus.aCaminho ||
      status == OrderStatus.chegouNoLocal;

  /// Indica se a sessão de chat está expirada (pedido finalizado ou cancelado).
  bool get isChatExpired =>
      status == OrderStatus.entregue ||
      status == OrderStatus.cancelado ||
      status == OrderStatus.naoEncontrado;

  /// Cria uma cópia com campos atualizados.
  Order copyWith({
    String? id,
    String? userId,
    String? kioskId,
    String? partnershipId,
    String? courierId,
    String? courierNome,
    String? courierTelefone,
    String? courierVeiculo,
    List<OrderItem>? itens,
    double? valorTotal,
    bool? embalagemSustentavel,
    PaymentMethod? formaPagamento,
    bool? pago,
    String? pixTxId,
    String? pixCopiaECola,
    String? pixQrCodeBase64,
    DateTime? pixExpiracao,
    OrderLocation? localizacao,
    GeoPoint? localizacaoEntregador,
    DateTime? atualizadoEntregadorEm,
    bool? alertaProximidadeEnviado,
    List<OrderMessage>? mensagens,
    OrderStatus? status,
    OrderTimeline? timeline,
    String? codigoEntrega,
    OrderReview? avaliacao,
    String? codigoPedido,
    int? numeroPedidoDiario,
  }) =>
      Order(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        kioskId: kioskId ?? this.kioskId,
        partnershipId: partnershipId ?? this.partnershipId,
        courierId: courierId ?? this.courierId,
        courierNome: courierNome ?? this.courierNome,
        courierTelefone: courierTelefone ?? this.courierTelefone,
        courierVeiculo: courierVeiculo ?? this.courierVeiculo,
        itens: itens ?? this.itens,
        valorTotal: valorTotal ?? this.valorTotal,
        embalagemSustentavel: embalagemSustentavel ?? this.embalagemSustentavel,
        formaPagamento: formaPagamento ?? this.formaPagamento,
        pago: pago ?? this.pago,
        pixTxId: pixTxId ?? this.pixTxId,
        pixCopiaECola: pixCopiaECola ?? this.pixCopiaECola,
        pixQrCodeBase64: pixQrCodeBase64 ?? this.pixQrCodeBase64,
        pixExpiracao: pixExpiracao ?? this.pixExpiracao,
        localizacao: localizacao ?? this.localizacao,
        localizacaoEntregador:
            localizacaoEntregador ?? this.localizacaoEntregador,
        atualizadoEntregadorEm:
            atualizadoEntregadorEm ?? this.atualizadoEntregadorEm,
        alertaProximidadeEnviado:
            alertaProximidadeEnviado ?? this.alertaProximidadeEnviado,
        mensagens: mensagens ?? this.mensagens,
        status: status ?? this.status,
        timeline: timeline ?? this.timeline,
        codigoEntrega: codigoEntrega ?? this.codigoEntrega,
        avaliacao: avaliacao ?? this.avaliacao,
        codigoPedido: codigoPedido ?? this.codigoPedido,
        numeroPedidoDiario: numeroPedidoDiario ?? this.numeroPedidoDiario,
      );

  /// Rótulo em texto livre do veículo do entregador (nunca constante).
  String get courierVeiculoLabel {
    switch ((courierVeiculo ?? '').toUpperCase().trim()) {
      case 'BICICLETA':
      case 'BIKE':
        return 'De bicicleta';
      case 'A_PE':
      case 'PE':
        return 'A pé';
      default:
        return '';
    }
  }
}
