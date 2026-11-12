import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_shared/core_shared.dart';

/// Diálogo modal seguro para confirmação da entrega mediante digitação do PIN de 4 dígitos
/// falado verbalmente pelo cliente na faixa de areia.
///
/// Segue o Design System Sage & Apricot:
/// - O entregador jamais vê o PIN antes da inserção.
/// - Valida exatamente 4 dígitos numéricos.
/// - Captura a coordenada GPS e aciona [OrderRepository.confirmDelivery] com geofencing (60m).
class DeliveryPinConfirmationDialog extends StatefulWidget {
  const DeliveryPinConfirmationDialog({
    super.key,
    required this.order,
    required this.courierId,
    required this.orderRepository,
    required this.locationService,
  });

  final Order order;
  final String courierId;
  final OrderRepository orderRepository;
  final LocationService locationService;

  static Future<bool?> show(
    BuildContext context, {
    required Order order,
    required String courierId,
    required OrderRepository orderRepository,
    required LocationService locationService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeliveryPinConfirmationDialog(
        order: order,
        courierId: courierId,
        orderRepository: orderRepository,
        locationService: locationService,
      ),
    );
  }

  @override
  State<DeliveryPinConfirmationDialog> createState() =>
      _DeliveryPinConfirmationDialogState();
}

class _DeliveryPinConfirmationDialogState
    extends State<DeliveryPinConfirmationDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() {
        _errorMessage = 'Informe exatamente os 4 dígitos do código de entrega.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final position = await widget.locationService.getCurrentPosition();
      await widget.orderRepository.confirmDelivery(
        orderId: widget.order.id,
        courierId: widget.courierId,
        latitude: position.latitude,
        longitude: position.longitude,
        codigoEntrega: pin,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.message;
        });
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Falha no GPS: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Erro ao confirmar entrega: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final reference = order.descricaoLocal.isNotEmpty
        ? order.descricaoLocal
        : 'Guarda-sol na faixa de areia';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge Icon
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.sage100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.sage600,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title and Subtitle
            const Text(
              'Confirmação de Entrega',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Solicite o PIN de 4 dígitos informado verbalmente pelo cliente na areia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.ink500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Order details summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Identificador:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sage100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.codigoFormatado,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sage700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ponto:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reference,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // PIN Input Section
            const Text(
              'DIGITE O PIN DO CLIENTE (4 DÍGITOS)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.ink500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _pinController,
              enabled: !_loading,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: AppColors.ink,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: AppColors.ink400,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.sage300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.sage600,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger500.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger500,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sage600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CONFIRMAR',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
