import 'package:flutter/material.dart';

import 'package:core_shared/core_shared.dart';

/// Tela 04 do Design System (`Search Items / Selected Food`):
/// Exibe cards horizontais limpos com miniatura `76×76` em `#EAEEED`,
/// stepper cápsula (`- 2 +`), preços em damasco (`#F59B56`) e painel inferior
/// arredondado (`28px`) `ITENS SELECIONADOS` com CTA cápsula `#8BBFB0`.
class BeachCartScreen extends StatefulWidget {
  const BeachCartScreen({
    super.key,
    required this.kiosk,
    required this.quantities,
    required this.paymentMethod,
    required this.sustainablePackaging,
    required this.onChangeQuantity,
    required this.onClearCart,
    required this.onPaymentMethodChanged,
    required this.onSustainableChanged,
    required this.onContinueCheckout,
    this.offer,
  });

  final Kiosk kiosk;
  final KioskPartnershipOffer? offer;
  final Map<String, int> quantities;
  final PaymentMethod paymentMethod;
  final bool sustainablePackaging;
  final void Function(MenuItem item, int delta) onChangeQuantity;
  final VoidCallback onClearCart;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<bool> onSustainableChanged;
  final Future<void> Function() onContinueCheckout;

  @override
  State<BeachCartScreen> createState() => _BeachCartScreenState();
}

class _BeachCartScreenState extends State<BeachCartScreen> {
  late PaymentMethod _paymentMethod;
  late bool _sustainable;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.paymentMethod;
    _sustainable = widget.sustainablePackaging;
  }

  List<MenuItem> get _selectedItems => widget.kiosk.cardapio
      .where((item) => (widget.quantities[item.id] ?? 0) > 0)
      .toList(growable: false);

  double get _subtotal => _selectedItems.fold<double>(
        0.0,
        (sum, item) => sum + item.preco * (widget.quantities[item.id] ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final items = _selectedItems;
    final subtotal = _subtotal;
    final offer = widget.offer;
    final deliveryFee = offer?.customerDeliveryFee ?? 0.0;
    final timeRange = offer?.estimatedTimeRangeLabel ?? '15 a 25 min';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Sacola na Praia'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Limpar sacola',
              onPressed: () {
                widget.onClearCart();
                setState(() {});
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.ink700,
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.placeholder,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 34,
                        color: AppColors.sage500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sua sacola está vazia',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escolha porções ou bebidas geladas de um quiosque da orla para receber no seu guarda-sol.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // Cabeçalho minimalista do Quiosque e Tempo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.kiosk.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.delivery_dining_rounded,
                              size: 17,
                              color: AppColors.apricot500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeRange,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cards Horizontais de Itens (Tela 04)
                      ...items.map(_buildHorizontalItemCard),

                      if (widget.kiosk.aceitaEmbalagemSustentavel) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final next = !_sustainable;
                            setState(() => _sustainable = next);
                            widget.onSustainableChanged(next);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _sustainable
                                        ? AppColors.sage500
                                        : AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _sustainable
                                          ? AppColors.sage500
                                          : AppColors.lineStrong,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _sustainable
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Preferir Embalagem Sustentável',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Text(
                        'PAGAMENTO ANTECIPADO',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.ink500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPaymentPill(
                            label: 'PIX (Copia e Cola)',
                            icon: Icons.pix_rounded,
                            selected: _paymentMethod == PaymentMethod.pix,
                            onTap: () {
                              setState(
                                () => _paymentMethod = PaymentMethod.pix,
                              );
                              widget.onPaymentMethodChanged(PaymentMethod.pix);
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentPill(
                            label: 'Cartão',
                            icon: Icons.credit_card_rounded,
                            selected: _paymentMethod == PaymentMethod.cartao,
                            onTap: () {
                              setState(
                                () => _paymentMethod = PaymentMethod.cartao,
                              );
                              widget
                                  .onPaymentMethodChanged(PaymentMethod.cartao);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Painel Inferior Arredondado: SELECTED FOOD (Tela 04)
                _buildSelectedFoodSummarySheet(
                  items: items,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                ),
              ],
            ),
    );
  }

  Widget _buildHorizontalItemCard(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasPhoto
                ? Image.network(
                    item.fotoUrl!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbFallback(),
                  )
                : _thumbFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.descricao.isEmpty ? widget.kiosk.nome : item.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Stepper em Pílula Limpa (- 2 +)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.stepperBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              widget.onChangeQuantity(item, -1);
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.remove,
                                size: 15,
                                color: AppColors.ink500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              widget.onChangeQuantity(item, 1);
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.add,
                                size: 15,
                                color: AppColors.ink500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Preço destacado em Warm Apricot (#F59B56)
                    Text(
                      'R\$ ${item.preco.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.apricot400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.sage500 : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.sage500 : AppColors.lineStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.ink700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink700,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSelectedFoodSummarySheet({
    required List<MenuItem> items,
    required double subtotal,
    required double deliveryFee,
  }) {
    final total = subtotal + deliveryFee;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.bottomSheetShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dragHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ITENS SELECIONADOS',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    for (final item in items.take(3)) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.quantities[item.id]}× ${item.nome}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.ink500,
                                ),
                              ),
                            ),
                            Text(
                              'R\$ ${(item.preco * (widget.quantities[item.id] ?? 0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Entrega na areia',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.ink500,
                            ),
                          ),
                          Text(
                            deliveryFee <= 0
                                ? 'Grátis'
                                : 'R\$ ${deliveryFee.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: deliveryFee <= 0
                                  ? AppColors.sage600
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.ink500,
                            ),
                          ),
                          Text(
                            'R\$ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.apricot400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sage500,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _submitting
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          try {
                            Navigator.of(context).pop();
                            await widget.onContinueCheckout();
                          } finally {
                            if (mounted) {
                              setState(() => _submitting = false);
                            }
                          }
                        },
                  child: const Text(
                    'FINALIZAR PEDIDO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.placeholder,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(
            Icons.fastfood_rounded,
            size: 28,
            color: AppColors.sage500,
          ),
        ),
      );
}
