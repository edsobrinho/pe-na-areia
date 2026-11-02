import 'package:flutter/material.dart';

import 'package:core_shared/core_shared.dart';
import 'menu_item_details_sheet.dart';

/// Tela 02 do Design System (`Restaurant Details`):
/// Cabeçalho claro centralizado, busca arredondada em branco, pílulas de
/// categoria em Sage Mint (`#8BBFB0`), cards com imagem inset (`#EAEEED`),
/// estrelas e entregador em damasco (`#FF9749`), abertura da Tela 03 (`Details`)
/// ao tocar no item e rodapé fixo com `TOTAL` (`#F59B56`) + CTA `#8BBFB0`.
class KioskStorefrontScreen extends StatefulWidget {
  const KioskStorefrontScreen({
    super.key,
    required this.kiosk,
    required this.quantities,
    required this.onChangeQuantity,
    required this.onOpenCart,
    this.offer,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final Kiosk kiosk;
  final KioskPartnershipOffer? offer;
  final Map<String, int> quantities;
  final void Function(MenuItem item, int delta) onChangeQuantity;
  final VoidCallback onOpenCart;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  State<KioskStorefrontScreen> createState() => _KioskStorefrontScreenState();
}

class _KioskStorefrontScreenState extends State<KioskStorefrontScreen> {
  String _selectedTab = 'Todos';
  String _searchQuery = '';
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = widget.isFavorite;
  }

  List<MenuItem> get _availableItems =>
      widget.kiosk.cardapio.where((i) => i.disponivel).toList(growable: false);

  List<MenuItem> get _featuredItems {
    final explicit = _availableItems.where((i) => i.destaque).toList();
    if (explicit.isNotEmpty) return explicit;
    return _availableItems.take(4).toList(growable: false);
  }

  List<String> get _tabs {
    final cats = <String>{'Todos', 'Destaques'};
    if (_availableItems.any((i) => i.returnablePackaging)) {
      cats.add('Retornáveis');
    }
    cats.addAll(widget.kiosk.categoriasDisponiveis);
    return cats.toList(growable: false);
  }

  List<MenuItem> get _filteredVerticalItems {
    return _availableItems.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.nome.toLowerCase().contains(q);
        final matchDesc = item.descricao.toLowerCase().contains(q);
        if (!matchName && !matchDesc) return false;
      }
      if (_selectedTab == 'Todos') return true;
      if (_selectedTab == 'Destaques') return item.destaque || _featuredItems.contains(item);
      if (_selectedTab == 'Retornáveis') return item.returnablePackaging;
      return item.category == _selectedTab;
    }).toList(growable: false);
  }

  double get _cartSubtotal => _availableItems.fold<double>(
        0.0,
        (sum, item) => sum + item.preco * (widget.quantities[item.id] ?? 0),
      );

  int get _cartTotalUnits => widget.quantities.values.fold<int>(
        0,
        (sum, qty) => sum + qty,
      );

  void _handleUpdateQuantity(MenuItem item, int delta) {
    widget.onChangeQuantity(item, delta);
    setState(() {});
  }

  void _openItemDetails(MenuItem item) {
    final current = widget.quantities[item.id] ?? 0;
    MenuItemDetailsSheet.show(
      context,
      item: item,
      currentQuantity: current,
      onAddQuantity: (targetQty) {
        final delta = targetQty - current;
        if (delta != 0) {
          _handleUpdateQuantity(item, delta);
        } else if (current == 0) {
          _handleUpdateQuantity(item, 1);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final minimumOrder = offer?.minimumOrder ?? 15.0;
    final subtotal = _cartSubtotal;
    final totalUnits = _cartTotalUnits;
    final fee = offer?.customerDeliveryFee ?? 0.0;
    final timeRange = offer?.estimatedTimeRangeLabel ?? '20 a 30 min';
    final categoriesSubtitle = widget.kiosk.categoriasDisponiveis.isEmpty
        ? 'Culinária Praiana · Bebidas'
        : widget.kiosk.categoriasDisponiveis.join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.kiosk.nome),
        actions: [
          IconButton(
            tooltip: 'Favoritar quiosque',
            onPressed: () {
              setState(() => _favorite = !_favorite);
              widget.onToggleFavorite?.call();
            },
            icon: Icon(
              _favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _favorite ? AppColors.apricot500 : AppColors.ink,
            ),
          ),
          IconButton(
            tooltip: 'Compartilhar quiosque',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link de ${widget.kiosk.nome} copiado!'),
                ),
              );
            },
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // Barra de Busca Branca Arredondada (Tela 02)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Buscar pratos ou bebidas...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.ink400,
                  size: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Pílulas Horizontais de Categoria em Sage Mint (#8BBFB0 - Tela 02)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final active = _selectedTab == tab;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _selectedTab = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.sage500 : AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? AppColors.sage500 : AppColors.line,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? Colors.white : AppColors.ink500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Card Inset de Identidade do Quiosque (Padrão Tela 02)
          _buildStorefrontHeroCard(
            categoriesSubtitle: categoriesSubtitle,
            timeRange: timeRange,
            fee: fee,
          ),

          const SizedBox(height: 20),

          // Seção de Pratos em Destaque (Cards Inset da Tela 02)
          if (_featuredItems.isNotEmpty &&
              _searchQuery.isEmpty &&
              (_selectedTab == 'Todos' || _selectedTab == 'Destaques')) ...[
            const Text(
              'ESPECIAL DO QUIOSQUE',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 218,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildFeaturedInsetCard(_featuredItems[index]),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // Lista de Itens do Cardápio (Cards Horizontais da Tela 04 + Toque abre Tela 03)
          Text(
            (_selectedTab == 'Todos' ? 'CARDÁPIO COMPLETO' : _selectedTab)
                .toUpperCase(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (_filteredVerticalItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Nenhum produto encontrado nesta seção.',
                  style: TextStyle(color: AppColors.ink500),
                ),
              ),
            )
          else
            ..._filteredVerticalItems.map(_buildMenuRowCard),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(
        subtotal: subtotal,
        minimumOrder: minimumOrder,
        totalUnits: totalUnits,
      ),
    );
  }

  Widget _buildStorefrontHeroCard({
    required String categoriesSubtitle,
    required String timeRange,
    required double fee,
  }) {
    final cover = widget.kiosk.imagemDestaqueUrl;
    return Container(
      padding: const EdgeInsets.all(12),
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
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: cover != null && cover.isNotEmpty
                  ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _insetPlaceholder(),
                    )
                  : _insetPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoriesSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink500,
                  ),
                ),
              ),
              Text(
                fee <= 0
                    ? 'Entrega Grátis'
                    : 'Taxa R\$ ${fee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fee <= 0 ? AppColors.sage600 : AppColors.ink700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.kiosk.nome,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (_) => const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: AppColors.apricot500,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.kiosk.avaliacaoMedia.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.ink500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.delivery_dining_rounded,
                size: 17,
                color: AppColors.apricot500,
              ),
              const SizedBox(width: 4),
              Text(
                timeRange,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink700,
                ),
              ),
            ],
          ),
          if (widget.kiosk.aceitaEmbalagemSustentavel) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sage100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.recycling_rounded, size: 15, color: AppColors.sage700),
                  SizedBox(width: 6),
                  Text(
                    'Quiosque Praia Limpa · Embalagem Retornável',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sage700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedInsetCard(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openItemDetails(item),
      child: Container(
        width: 164,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 106,
                width: double.infinity,
                child: hasPhoto
                    ? Image.network(
                        item.fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _insetPlaceholder(),
                      )
                    : _insetPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${item.preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.apricot400,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _handleUpdateQuantity(item, 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppColors.sage500 : AppColors.placeholder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      qty > 0 ? '+$qty' : '+',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: qty > 0 ? Colors.white : AppColors.ink,
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

  Widget _buildMenuRowCard(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openItemDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: hasPhoto
                      ? Image.network(
                          item.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _insetPlaceholder(),
                        )
                      : _insetPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (item.returnablePackaging)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.recycling_rounded,
                              size: 15,
                              color: AppColors.sage600,
                            ),
                          ),
                      ],
                    ),
                    if (item.descricao.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
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
                                onTap: qty > 0
                                    ? () => _handleUpdateQuantity(item, -1)
                                    : null,
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.remove,
                                    size: 15,
                                    color: AppColors.ink500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => _handleUpdateQuantity(item, 1),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
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
                        Text(
                          'R\$ ${item.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required double subtotal,
    required double minimumOrder,
    required int totalUnits,
  }) {
    final reachedMinimum = subtotal >= minimumOrder && totalUnits > 0;
    final missing = (minimumOrder - subtotal).clamp(0.0, minimumOrder);

    return Container(
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
                  Text(
                    reachedMinimum
                        ? 'TOTAL ($totalUnits ${totalUnits == 1 ? 'ITEM' : 'ITENS'})'
                        : 'MÍNIMO R\$ ${minimumOrder.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'R\$ ${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.apricot400,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sage500,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: reachedMinimum
                      ? () {
                          Navigator.of(context).pop();
                          widget.onOpenCart();
                        }
                      : null,
                  child: Text(
                    reachedMinimum
                        ? 'VER SACOLA'
                        : 'FALTAM R\$ ${missing.toStringAsFixed(2)}',
                    style: const TextStyle(
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
    );
  }

  Widget _insetPlaceholder() => Container(
        color: AppColors.placeholder,
        child: const Center(
          child: Icon(
            Icons.beach_access_rounded,
            size: 36,
            color: AppColors.sage500,
          ),
        ),
      );
}
