/// Canal de venda ativo disponibilizado pela API.
class Partnership {
  const Partnership({
    required this.id,
    required this.name,
    required this.channel,
  });

  final String id;
  final String name;
  final String channel;

  factory Partnership.fromJson(Map<String, dynamic> json) => Partnership(
        id: json['id'] as String,
        name: json['name'] as String,
        channel: json['channel'] as String,
      );
}

/// Oferta e regras operacionais de um quiosque em uma parceria (`GET /kiosks/{id}/partnerships`).
class KioskPartnershipOffer {
  const KioskPartnershipOffer({
    required this.partnershipId,
    required this.name,
    required this.channel,
    this.active = true,
    this.deliveryFee = 0,
    this.deliveryFeePayer = 'CLIENT',
    this.minimumOrder = 0,
    this.maxItemsPerOrder = 20,
    this.acceptFrom = '08:00',
    this.acceptUntil = '22:00',
    this.prepMinutes = 20,
  });

  final String partnershipId;
  final String name;
  final String channel;
  final bool active;
  final double deliveryFee;
  final String deliveryFeePayer;
  final double minimumOrder;
  final int maxItemsPerOrder;
  final String acceptFrom;
  final String acceptUntil;
  final int prepMinutes;

  /// Taxa efetivamente cobrada do cliente (`0` quando o quiosque absorve a taxa).
  double get customerDeliveryFee =>
      deliveryFeePayer.toUpperCase() == 'KIOSK' ? 0.0 : deliveryFee;

  bool get isFreeDelivery => customerDeliveryFee <= 0.0;

  /// Faixa estimada de tempo de entrega na areia baseada em [prepMinutes].
  String get estimatedTimeRangeLabel {
    final min = prepMinutes.clamp(10, 90);
    final max = min + 10;
    return '$min a $max min';
  }

  factory KioskPartnershipOffer.fromJson(Map<String, dynamic> json) =>
      KioskPartnershipOffer(
        partnershipId: json['partnershipId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        channel: json['channel'] as String? ?? 'APP',
        active: json['active'] as bool? ?? true,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
        deliveryFeePayer: json['deliveryFeePayer'] as String? ?? 'CLIENT',
        minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0.0,
        maxItemsPerOrder: (json['maxItemsPerOrder'] as num?)?.toInt() ?? 20,
        acceptFrom: json['acceptFrom']?.toString() ?? '08:00',
        acceptUntil: json['acceptUntil']?.toString() ?? '22:00',
        prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 20,
      );
}
