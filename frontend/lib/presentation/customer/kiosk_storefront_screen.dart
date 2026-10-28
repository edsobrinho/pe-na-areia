import 'package:flutter/material.dart';

import '../../domain/models/kiosk.dart';
import '../../domain/models/partnership.dart';
import '../theme/app_colors.dart';

/// Tela 4 (v2.1): Loja / Cardápio Dedicado do Quiosque (Storefront View).
///
/// Apresenta métricas operacionais em 3 colunas (tempo estimado, taxa de entrega,
/// entrega na faixa de areia), abas de categoria, carrossel horizontal de
/// "Mais vendidos / Destaques do Quiosque", lista vertical e barra fixa de
/// Pedido Mínimo / Sacola.
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
  String _selectedTab = 'Destaques';
  String _searchQuery = '';
  bool _searching = false;
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
    return _availableItems.take(5).toList(growable: false);
  }

  List<String> get _tabs {
    final cats = <String>{'Destaques', 'Escolhidos na Praia'};
    cats.addAll(widget.kiosk.categoriasDisponiveis);
    if (_availableItems.any((i) => i.returnablePackaging)) {
      cats.add('Retornáveis ♻️');
    }
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
      if (_selectedTab == 'Destaques' || _selectedTab == 'Escolhidos na Praia') {
        return true;
      }
      if (_selectedTab == 'Retornáveis ♻️') {
        return item.returnablePackaging;
      }
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

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final minimumOrder = offer?.minimumOrder ?? 15.0;
    final subtotal = _cartSubtotal;
    final totalUnits = _cartTotalUnits;
    final fee = offer?.customerDeliveryFee ?? 0.0;
    final timeRange = offer?.estimatedTimeRangeLabel ?? '20 a 30 min';
    final categoriesSubtitle = widget.kiosk.categoriasDisponiveis.isEmpty
        ? 'Culinária Praiana, Bebidas'
        : widget.kiosk.categoriasDisponiveis.join(', ');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar no cardápio do quiosque...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Compartilhar quiosque',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link de ${widget.kiosk.nome} copiado!'),
                ),
              );
            },
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Favoritar quiosque',
            onPressed: () {
              setState(() => _favorite = !_favorite);
              widget.onToggleFavorite?.call();
            },
            icon: Icon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              color: _favorite ? AppColors.brandRed : AppColors.ink,
            ),
          ),
          IconButton(
            tooltip: 'Buscar no cardápio',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchQuery = '';
            }),
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Cabeçalho do Quiosque
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.sand50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sand100),
                ),
                child: widget.kiosk.logoUrl != null &&
                        widget.kiosk.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          widget.kiosk.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.beach_access,
                            color: AppColors.ocean700,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.beach_access,
                        color: AppColors.ocean700,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.kiosk.nome,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            categoriesSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.destination,
                        ),
                        Text(
                          widget.kiosk.avaliacaoMedia.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bloco de Métricas Operacionais em 3 Colunas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn(
                  title: timeRange,
                  subtitle: 'Tempo na areia',
                ),
                _buildMetricColumn(
                  title: fee <= 0
                      ? 'R\$ 0'
                      : 'R\$ ${fee.toStringAsFixed(2)}',
                  subtitle: 'Taxa de entrega',
                  icon: Icons.directions_walk,
                ),
                _buildMetricColumn(
                  title: 'No Guarda-Sol',
                  subtitle: 'Entrega no Pin >',
                ),
              ],
            ),
          ),

          if (widget.kiosk.aceitaEmbalagemSustentavel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sand50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sand100),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.recycling,
                    color: AppColors.seafoam500,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiosque Praia Limpa · Embalagem Retornável',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.seafoam500,
                          ),
                        ),
                        Text(
                          'Itens sustentáveis entregues direto na sua barraca',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Barra de Abas por Categoria
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final active = _selectedTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tab,
                        style: TextStyle(
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 14,
                          color: active ? AppColors.ink : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        width: active ? 42 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.ocean700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 12),

          // Carrossel Horizontal: Destaques / Mais pedidos no Quiosque
          if (_featuredItems.isNotEmpty && _searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Mais pedidos na areia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 205,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildFeaturedSquareCard(_featuredItems[index]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Lista Vertical: Escolhidos para a Praia
          Text(
            _selectedTab == 'Destaques' ? 'Escolhido a dedo' : _selectedTab,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (_filteredVerticalItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Nenhum produto encontrado nesta seção.'),
              ),
            )
          else
            ..._filteredVerticalItems.map(_buildVerticalMenuRow),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: _buildBottomMinimumOrderBar(
          subtotal: subtotal,
          minimumOrder: minimumOrder,
          totalUnits: totalUnits,
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String title,
    required String subtitle,
    IconData? icon,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppColors.ink),
                const SizedBox(width: 3),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      );

  Widget _buildFeaturedSquareCard(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            height: 122,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasPhoto
                      ? Image.network(
                          item.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
                if (item.returnablePackaging)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.seafoam500,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '♻️ Retornável',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Material(
                    color: AppColors.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _handleUpdateQuantity(item, 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          qty > 0 ? '+ ($qty)' : '+',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Text(
            'R\$ ${item.preco.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.seafoam500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalMenuRow(MenuItem item) {
    final qty = widget.quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.destaque || item.returnablePackaging)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item.destaque
                            ? '🔥 Mais pedido na praia'
                            : '♻️ Embalagem retornável',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mango500,
                        ),
                      ),
                    ),
                  Text(
                    item.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (item.descricao.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'R\$ ${item.preco.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasPhoto
                      ? Image.network(
                          item.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Material(
                    color: AppColors.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: qty == 0
                        ? InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _handleUpdateQuantity(item, 1),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add, size: 18),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _handleUpdateQuantity(item, -1),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              InkWell(
                                onTap: () => _handleUpdateQuantity(item, 1),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMinimumOrderBar({
    required double subtotal,
    required double minimumOrder,
    required int totalUnits,
  }) {
    final reachedMinimum = subtotal >= minimumOrder && totalUnits > 0;
    if (!reachedMinimum) {
      final missing = (minimumOrder - subtotal).clamp(0.0, minimumOrder);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.sand50,
          border: Border(top: BorderSide(color: AppColors.sand100)),
        ),
        child: Text(
          subtotal <= 0
              ? 'Pedido mínimo R\$ ${minimumOrder.toStringAsFixed(2)}'
              : 'Pedido mínimo R\$ ${minimumOrder.toStringAsFixed(2)} '
                  '(faltam R\$ ${missing.toStringAsFixed(2)})',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.ink,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mango500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.of(context).pop();
          widget.onOpenCart();
        },
        icon: const Icon(Icons.shopping_bag_outlined),
        label: Text(
          'Ver sacola ($totalUnits ${totalUnits == 1 ? 'item' : 'itens'}) · R\$ ${subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }

  Widget _photoFallback() => Container(
        color: AppColors.sand50,
        child: const Center(
          child: Text('🍽️', style: TextStyle(fontSize: 30)),
        ),
      );
}

