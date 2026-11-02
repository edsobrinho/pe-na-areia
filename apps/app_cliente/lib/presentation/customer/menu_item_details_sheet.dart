import 'package:flutter/material.dart';

import 'package:core_shared/core_shared.dart';

/// Tela 03 do Design System (`Details`):
/// Exibe foto hero com moldura interna (inset), avaliação ★ 5.0 em damasco,
/// descrição limpa, lista de preferências com checkboxes circulares em Sage Mint
/// (`#8BBFB0`) e rodapé fixo com `TOTAL` (`#F59B56`) + CTA cápsula `ADICIONAR`.
class MenuItemDetailsSheet extends StatefulWidget {
  const MenuItemDetailsSheet({
    super.key,
    required this.item,
    required this.initialQuantity,
    required this.onAddQuantity,
  });

  final MenuItem item;
  final int initialQuantity;
  final ValueChanged<int> onAddQuantity;

  static Future<void> show(
    BuildContext context, {
    required MenuItem item,
    required int currentQuantity,
    required ValueChanged<int> onAddQuantity,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: MenuItemDetailsSheet(
            item: item,
            initialQuantity: currentQuantity > 0 ? currentQuantity : 1,
            onAddQuantity: onAddQuantity,
          ),
        ),
      ),
    );
  }

  @override
  State<MenuItemDetailsSheet> createState() => _MenuItemDetailsSheetState();
}

class _MenuItemDetailsSheetState extends State<MenuItemDetailsSheet> {
  static const List<String> _preferenceOptions = [
    'Gelo e limão à parte',
    'Sem molho apimentado',
    'Guardanapos e palitos extras',
    'Embalagem vedada contra areia',
  ];

  final Set<int> _selectedModifiers = {0, 3};
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(1, 99);
  }

  void _toggleModifier(int index) {
    setState(() {
      if (_selectedModifiers.contains(index)) {
        _selectedModifiers.remove(index);
      } else if (_selectedModifiers.length < 4) {
        _selectedModifiers.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;
    final total = item.preco * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
        ),
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            tooltip: 'Mais opções',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Card Principal com Foto Inset (Tela 03)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 205,
                    width: double.infinity,
                    child: hasPhoto
                        ? Image.network(
                            item.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _heroPlaceholder(),
                          )
                        : _heroPlaceholder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.apricot500,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      '5.0 (120+)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.descricao.isEmpty
                      ? 'Preparado na hora pelo quiosque com ingredientes frescos e entregue direto no seu guarda-sol na faixa de areia.'
                      : item.descricao,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.ink500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.returnablePackaging)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '♻️ Embalagem Retornável',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sage700,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    _buildCapsuleStepper(),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Seção de Preferências / Modificadores com Checkboxes Circulares (Tela 03)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERSONALIZAR',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Escolha até 4',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              children: List.generate(_preferenceOptions.length, (index) {
                final checked = _selectedModifiers.contains(index);
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: index == 0
                            ? const Radius.circular(18)
                            : Radius.zero,
                        bottom: index == _preferenceOptions.length - 1
                            ? const Radius.circular(18)
                            : Radius.zero,
                      ),
                      onTap: () => _toggleModifier(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: checked
                                    ? AppColors.sage500
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: checked
                                      ? AppColors.sage500
                                      : AppColors.lineStrong,
                                  width: 1.5,
                                ),
                              ),
                              child: checked
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _preferenceOptions[index],
                                style: const TextStyle(
                                  fontSize: 13.5,
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
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTheme.bottomSheetShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: AppColors.ink500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.apricot400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sage500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      widget.onAddQuantity(_quantity);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'ADICIONAR À SACOLA',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleStepper() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.remove, size: 16, color: AppColors.ink500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _quantity++),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.add, size: 16, color: AppColors.ink500),
              ),
            ),
          ],
        ),
      );

  Widget _heroPlaceholder() => Container(
        color: AppColors.placeholder,
        child: const Center(
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: 52,
            color: AppColors.sage500,
          ),
        ),
      );
}

