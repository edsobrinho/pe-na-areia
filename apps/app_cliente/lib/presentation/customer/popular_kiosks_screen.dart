import 'package:flutter/material.dart';

import 'package:core_shared/core_shared.dart';

/// Vitrine de Quiosques Populares unificada ao Design System da Tela 02
/// (`Restaurant Details`): cabeçalho claro centralizado, pílulas em Sage Mint
/// (`#8BBFB0`) e cards com imagem inset (`#EAEEED`) + estrelas/entregador `#FF9749`.
class PopularKiosksScreen extends StatefulWidget {
  const PopularKiosksScreen({
    super.key,
    required this.kiosks,
    required this.offersByKioskId,
    required this.onSelectKiosk,
    this.customerPin,
  });

  final List<Kiosk> kiosks;
  final Map<String, KioskPartnershipOffer> offersByKioskId;
  final ValueChanged<Kiosk> onSelectKiosk;
  final GeoPoint? customerPin;

  @override
  State<PopularKiosksScreen> createState() => _PopularKiosksScreenState();
}

class _PopularKiosksScreenState extends State<PopularKiosksScreen> {
  String _sortBy = 'POPULAR';
  String _selectedCategory = 'Todas';
  String _searchQuery = '';

  List<String> get _allCategories {
    final cats = <String>{'Todas'};
    for (final k in widget.kiosks) {
      cats.addAll(k.categoriasDisponiveis);
    }
    return cats.toList(growable: false);
  }

  List<Kiosk> get _filteredKiosks {
    final q = _searchQuery.trim().toLowerCase();
    var list = widget.kiosks.where((k) {
      if (q.isNotEmpty && !k.nome.toLowerCase().contains(q)) {
        return false;
      }
      if (_selectedCategory == 'Todas') return true;
      return k.categoriasDisponiveis.contains(_selectedCategory);
    }).toList();

    list.sort((a, b) {
      final offerA = widget.offersByKioskId[a.id];
      final offerB = widget.offersByKioskId[b.id];
      switch (_sortBy) {
        case 'TAXA':
          final feeA = offerA?.customerDeliveryFee ?? 0;
          final feeB = offerB?.customerDeliveryFee ?? 0;
          return feeA.compareTo(feeB);
        case 'TEMPO':
          final prepA = offerA?.prepMinutes ?? 20;
          final prepB = offerB?.prepMinutes ?? 20;
          return prepA.compareTo(prepB);
        case 'DISTANCIA':
          final distA = _distanceKm(a) ?? 99.0;
          final distB = _distanceKm(b) ?? 99.0;
          return distA.compareTo(distB);
        default:
          return b.avaliacaoMedia.compareTo(a.avaliacaoMedia);
      }
    });
    return list;
  }

  double? _distanceKm(Kiosk kiosk) {
    final pin = widget.customerPin;
    final loc = kiosk.localizacao;
    if (pin == null || loc == null) return null;
    return distanceMeters(pin, loc) / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredKiosks;
    final categories = _allCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Quiosques na Orla'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Ordenar',
            onSelected: (val) => setState(() => _sortBy = val),
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'POPULAR', child: Text('Mais bem avaliados')),
              PopupMenuItem(value: 'TEMPO', child: Text('Menor tempo na areia')),
              PopupMenuItem(value: 'TAXA', child: Text('Menor taxa de entrega')),
              PopupMenuItem(value: 'DISTANCIA', child: Text('Mais próximos')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // Barra de Busca Branca (Tela 02)
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
                hintText: 'Buscar quiosques na praia...',
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

          // Pílulas de Categoria em Sage Mint (#8BBFB0 - Tela 02)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final active = _selectedCategory == cat;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _selectedCategory = cat),
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
                      cat,
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
          const SizedBox(height: 18),

          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Nenhum quiosque encontrado para este filtro.',
                  style: TextStyle(color: AppColors.ink500),
                ),
              ),
            )
          else
            ...filtered.map((kiosk) => _buildInsetKioskCard(context, kiosk)),
        ],
      ),
    );
  }

  Widget _buildInsetKioskCard(BuildContext context, Kiosk kiosk) {
    final offer = widget.offersByKioskId[kiosk.id];
    final imageUrl = kiosk.imagemDestaqueUrl;
    final distKm = _distanceKm(kiosk) ?? 0.6;
    final timeRange = offer?.estimatedTimeRangeLabel ?? '15 a 25 min';
    final fee = offer?.customerDeliveryFee ?? 0.0;
    final categoriesLabel = kiosk.categoriasDisponiveis.isEmpty
        ? 'Orla de Santos - Praia'
        : '${kiosk.pontoReferenciaId.isEmpty ? 'Orla de Santos' : kiosk.pontoReferenciaId.toUpperCase()} - ${kiosk.categoriasDisponiveis.first}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).pop();
            widget.onSelectKiosk(kiosk);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverFallback(),
                          )
                        : _coverFallback(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        categoriesLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.ink500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fee <= 0
                          ? 'Entrega Grátis'
                          : kiosk.aceitaEmbalagemSustentavel
                              ? 'Embalagem Sustentável ♻️'
                              : 'Taxa R\$ ${fee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: fee <= 0 || kiosk.aceitaEmbalagemSustentavel
                            ? AppColors.sage600
                            : AppColors.ink700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  kiosk.nome,
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
                      kiosk.avaliacaoMedia.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.delivery_dining_rounded,
                      size: 16,
                      color: AppColors.apricot500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${distKm.toStringAsFixed(1)}Km - $timeRange',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() => Container(
        color: AppColors.placeholder,
        child: const Center(
          child: Icon(
            Icons.beach_access_rounded,
            size: 46,
            color: AppColors.sage500,
          ),
        ),
      );
}
