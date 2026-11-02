import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:core_shared/core_shared.dart';

/// Painel de "Radar Pedestre / Bússola na Areia" integrado ao Design System
/// "Brisa Minimalista — Sage & Apricot" (Tela 05).
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
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.apricot100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.apricot500.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.apricot500,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: ((bearing ?? 0.0) * math.pi) / 180.0,
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 24,
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.apricot600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instruction ??
                          'Toque em "Atualizar GPS" para calcular direção e distância',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (dist != null && dist <= 60)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(
                          '🔦 Cliente notificado para levantar o Sinalizador!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.sage700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onUpdateGps != null)
                IconButton(
                  tooltip: 'Atualizar meu GPS na areia',
                  onPressed: onUpdateGps,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.apricot600,
                  ),
                ),
            ],
          ),
          if (pin.descricaoLocal.isNotEmpty || hasPhoto) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhoto) ...[
                  GestureDetector(
                    onTap: () => _showPhotoZoom(context, pin.fotoLocalUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        pin.fotoLocalUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.placeholder,
                          child: const Icon(
                            Icons.beach_access_rounded,
                            color: AppColors.sage500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referência visual do cliente:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pin.descricaoLocal.isEmpty
                            ? 'Sem descrição adicional'
                            : pin.descricaoLocal,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (hasPhoto)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '🔍 Toque na foto do guarda-sol para ampliar',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.ink500,
                            ),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
