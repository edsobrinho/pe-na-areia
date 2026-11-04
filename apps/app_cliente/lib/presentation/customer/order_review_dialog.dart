import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

/// Diálogo de avaliação 1 a 5 estrelas para o cliente avaliar o quiosque e a entrega.
class OrderReviewDialog extends StatefulWidget {
  const OrderReviewDialog({
    super.key,
    required this.orderId,
    required this.orderRepository,
    this.onReviewSubmitted,
  });

  final String orderId;
  final OrderRepository orderRepository;
  final void Function(Order updatedOrder)? onReviewSubmitted;

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required OrderRepository orderRepository,
    void Function(Order updatedOrder)? onReviewSubmitted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderReviewDialog(
        orderId: orderId,
        orderRepository: orderRepository,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<OrderReviewDialog> createState() => _OrderReviewDialogState();
}

class _OrderReviewDialogState extends State<OrderReviewDialog> {
  int _notaPedido = 5;
  int _notaEntrega = 5;
  final _comentarioController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await widget.orderRepository.reviewOrder(
        orderId: widget.orderId,
        notaPedido: _notaPedido,
        notaEntrega: _notaEntrega,
        comentario: _comentarioController.text.trim(),
      );

      if (mounted) {
        widget.onReviewSubmitted?.call(updated);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obrigado pela sua avaliação! ⭐'),
            backgroundColor: AppColors.sage700,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Falha ao enviar avaliação: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.apricot100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.apricot600, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avaliar Pedido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink900,
                  ),
                ),
                Text(
                  'Como foi sua experiência na praia?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
              ),
            ],

            // 1. Nota do Pedido / Quiosque
            const Text(
              '🍽️ Qualidade do Pedido / Quiosque',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            _buildInteractiveStars(_notaPedido, (val) => setState(() => _notaPedido = val)),

            const SizedBox(height: 18),

            // 2. Nota da Entrega na Areia
            const Text(
              '🧭 Atendimento da Entrega na Areia',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            _buildInteractiveStars(_notaEntrega, (val) => setState(() => _notaEntrega = val)),

            const SizedBox(height: 18),

            // 3. Comentário Opcional
            const Text(
              '💬 Deixe um comentário (opcional)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Ex.: A porção de camarão estava deliciosa e o entregador achou rápido o guarda-sol!',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.ink500),
                filled: true,
                fillColor: AppColors.sand100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('DEPOIS', style: TextStyle(color: AppColors.ink500)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sage700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _loading ? null : _submitReview,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('ENVIAR AVALIAÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInteractiveStars(int currentRating, ValueChanged<int> onSelect) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= currentRating;
        return IconButton(
          iconSize: 32,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
            color: isSelected ? Colors.amber : AppColors.sand200,
          ),
          onPressed: () => onSelect(starValue),
        );
      }),
    );
  }
}

