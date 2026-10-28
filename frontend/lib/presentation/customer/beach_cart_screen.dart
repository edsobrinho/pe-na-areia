import 'package:flutter/material.dart';

import '../../domain/models/kiosk.dart';
import '../../domain/models/partnership.dart';
import '../../domain/models/payment_method.dart';
import '../theme/app_colors.dart';

/// Tela 5 (v2.1): Sacola / Carrinho Detalhado na Praia (`BeachCartScreen`).
///
/// Exibe os itens selecionados do quiosque com miniatura da foto, controle de
/// quantidade (`- 1 +`), selo de tempo estimado na areia, opção de embalagem
/// sustentável, escolha da forma de pagamento (PIX ou Cartão) e botão "Continuar".
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
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(
          'Carrinho',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sua sacola está vazia. Escolha porções ou bebidas de um quiosque da orla!',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do Card do Quiosque
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.kiosk.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.bolt,
                            color: AppColors.positive,
                            size: 18,
                          ),
                          Text(
                            timeRange,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Limpar sacola',
                            onPressed: () {
                              widget.onClearCart();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Itens da sacola
                      ...items.map(_buildCartItemRow),

                      const Divider(height: 24),

                      if (widget.kiosk.aceitaEmbalagemSustentavel)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: AppColors.seafoam500,
                          title: const Text(
                            '♻️ Preferir embalagem retornável / sustentável',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          value: _sustainable,
                          onChanged: (val) {
                            setState(() => _sustainable = val);
                            widget.onSustainableChanged(val);
                          },
                        ),

                      const SizedBox(height: 6),
                      const Text(
                        'Forma de pagamento antecipado (Zero dinheiro na areia)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('💠 PIX (Copia e Cola)'),
                            selected: _paymentMethod == PaymentMethod.pix,
                            onSelected: (_) {
                              setState(
                                () => _paymentMethod = PaymentMethod.pix,
                              );
                              widget.onPaymentMethodChanged(PaymentMethod.pix);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('💳 Cartão'),
                            selected: _paymentMethod == PaymentMethod.cartao,
                            onSelected: (_) {
                              setState(
                                () => _paymentMethod = PaymentMethod.cartao,
                              );
                              widget
                                  .onPaymentMethodChanged(PaymentMethod.cartao);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rodapé com Total + Botão Continuar
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'R\$ ${(subtotal + deliveryFee).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  deliveryFee <= 0
                                      ? 'Entrega na areia: Grátis'
                                      : 'Entrega na areia: R\$ ${deliveryFee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (_sustainable)
                                  const Text(
                                    'Selo Praia Limpa ativado ♻️',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.seafoam500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.mango500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
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
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
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

  Widget _buildCartItemRow(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasPhoto
                ? Image.network(
                    item.fotoUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbFallback(),
                  )
                : _thumbFallback(),
          ),
          const SizedBox(width: 12),
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
                if (item.descricao.isNotEmpty)
                  Text(
                    item.descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'R\$ ${item.preco.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.seafoam500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              widget.onChangeQuantity(item, -1);
                              setState(() {});
                            },
                            icon: const Icon(Icons.remove, size: 16),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              widget.onChangeQuantity(item, 1);
                              setState(() {});
                            },
                            icon: const Icon(Icons.add, size: 16),
                          ),
                        ],
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

  Widget _thumbFallback() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.sand50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('🍽️', style: TextStyle(fontSize: 24)),
        ),
      );
}

