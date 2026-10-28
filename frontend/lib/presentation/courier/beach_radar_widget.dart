import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/order.dart';
import '../../domain/utils/beach_compass.dart';

/// Painel de "Radar Pedestre / Bússola na Areia" para o entregador localizar
/// o guarda-sol do cliente na praia.
class BeachRadarWidget extends StatelessWidget {
  const BeachRadarWidget({
    super.key,
    required this.order,
    this.courierLatitude,
    this.courierLongitude,
    this.onUpdateGps,
  });

  final Order order;
  final double? courierLatitude;
  final double? courierLongitude;
  final VoidCallback? onUpdateGps;

  @override
  Widget build(BuildContext context) {
    final pin = order.localizacao;
    if (pin == null) return const SizedBox.shrink();

    final cLat = courierLatitude ?? order.localizacaoEntregador?.latitude;
    final cLng = courierLongitude ?? order.localizacaoEntregador?.longitude;

    double? dist;
    double? bearing;
    String? instruction;
    if (cLat != null && cLng != null) {
      dist = BeachCompass.distanceMeters(cLat, cLng, pin.latitude, pin.longitude);
      bearing =
          BeachCompass.bearingDegrees(cLat, cLng, pin.latitude, pin.longitude);
      instruction = BeachCompass.formatRadarInstruction(
        courierLat: cLat,
        courierLng: cLng,
        pinLat: pin.latitude,
        pinLng: pin.longitude,
        referenceLabel: pin.pontoReferenciaId.isNotEmpty
            ? 'Posto ${pin.pontoReferenciaId}'
            : null,
      );
    }

    final hasPhoto = pin.fotoLocalUrl != null && pin.fotoLocalUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7A3D).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A3D),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: ((bearing ?? 0.0) * math.pi) / 180.0,
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MODO BÚSSOLA · RADAR NA AREIA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instruction ??
                          'Toque em "Atualizar GPS" para calcular direção e distância',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (dist != null && dist <= 60)
                      const Text(
                        '🔦 Cliente notificado para levantar o Sinalizador Laranja!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onUpdateGps != null)
                IconButton(
                  tooltip: 'Atualizar meu GPS na areia',
                  onPressed: onUpdateGps,
                  icon: const Icon(Icons.my_location, color: Color(0xFFC2410C)),
                ),
            ],
          ),
          if (pin.descricaoLocal.isNotEmpty || hasPhoto) ...[
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhoto) ...[
                  GestureDetector(
                    onTap: () => _showPhotoZoom(context, pin.fotoLocalUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        pin.fotoLocalUrl!,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 68,
                          height: 68,
                          color: Colors.orange.shade100,
                          child: const Icon(Icons.beach_access),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referência visual do cliente:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pin.descricaoLocal.isEmpty
                            ? 'Sem descrição adicional'
                            : pin.descricaoLocal,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasPhoto)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '🔍 Toque na foto do guarda-sol para ampliar',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Não foi possível carregar a foto.'),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}

