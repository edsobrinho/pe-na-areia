import 'package:flutter/material.dart';

import '../../domain/geo.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/kiosk.dart';
import '../../domain/models/partnership.dart';
import '../theme/app_colors.dart';

/// Tela 3 (v2.1): Vitrine Temática — "Quiosques Populares na Orla".
///
/// Exibe cards fotográficos amplos (16:9) dos quiosques em destaque na orla de Santos,
/// com filtros de ordenação/categoria, avaliação, taxa de entrega, tempo e distância.
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

  List<String> get _allCategories {
    final cats = <String>{'Todas'};
    for (final k in widget.kiosks) {
      cats.addAll(k.categoriasDisponiveis);
    }
    return cats.toList(growable: false);
  }

  List<Kiosk> get _filteredKiosks {
    var list = widget.kiosks.where((k) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 165,
            pinned: true,
            backgroundColor: AppColors.ocean900,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Quiosques Populares',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ocean900, AppColors.ocean500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -12,
                      bottom: -18,
                      child: Icon(
                        Icons.beach_access,
                        size: 140,
                        color: Colors.white12,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 68, 20, 16),
                      child: Text(
                        'Os favoritos dos banhistas na orla de Santos',
                        style: TextStyle(
                          color: AppColors.sand100,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildSortChip(),
                  _buildCategoryChip(),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Nenhum quiosque encontrado para este filtro.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) =>
                    _buildLargeKioskCard(context, filtered[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortChip() => PopupMenuButton<String>(
        onSelected: (val) => setState(() => _sortBy = val),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'POPULAR', child: Text('Mais bem avaliados')),
          PopupMenuItem(value: 'TEMPO', child: Text('Menor tempo na areia')),
          PopupMenuItem(value: 'TAXA', child: Text('Menor taxa de entrega')),
          PopupMenuItem(value: 'DISTANCIA', child: Text('Mais próximos de mim')),
        ],
        child: Chip(
          backgroundColor: AppColors.surface,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                switch (_sortBy) {
                  'TEMPO' => 'Ordenar: Tempo',
                  'TAXA' => 'Ordenar: Taxa',
                  'DISTANCIA' => 'Ordenar: Distância',
                  _ => 'Ordenar',
                },
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      );

  Widget _buildCategoryChip() => PopupMenuButton<String>(
        onSelected: (val) => setState(() => _selectedCategory = val),
        itemBuilder: (_) => _allCategories
            .map((cat) => PopupMenuItem(value: cat, child: Text(cat)))
            .toList(growable: false),
        child: Chip(
          backgroundColor: AppColors.surface,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedCategory == 'Todas'
                    ? 'Categorias'
                    : 'Cat: $_selectedCategory',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      );

  Widget _buildLargeKioskCard(BuildContext context, Kiosk kiosk) {
    final offer = widget.offersByKioskId[kiosk.id];
    final imageUrl = kiosk.imagemDestaqueUrl;
    final distKm = _distanceKm(kiosk);
    final timeRange = offer?.estimatedTimeRangeLabel ?? '15 a 25 min';
    final fee = offer?.customerDeliveryFee ?? 0.0;
    final categoriesLabel = kiosk.categoriasDisponiveis.isEmpty
        ? 'Porções, Bebidas, Praia'
        : kiosk.categoriasDisponiveis.join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).pop();
        widget.onSelectKiosk(kiosk);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 185,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverFallback(),
                          )
                        : _coverFallback(),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ocean900.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront,
                            color: AppColors.sand100,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            kiosk.pontoReferenciaId.isEmpty
                                ? 'Orla de Santos'
                                : kiosk.pontoReferenciaId.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kiosk.aceitaEmbalagemSustentavel)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.seafoam500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '♻️ Embalagem Retornável',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kiosk.nome} - Praia de Santos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.destination,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            kiosk.avaliacaoMedia.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Text(
                        fee <= 0
                            ? '· Entrega Grátis'
                            : '· Entrega R\$ ${fee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: fee <= 0
                              ? AppColors.positive
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        '· $timeRange',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (distKm != null)
                        Text(
                          '· ${distKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      Text(
                        '· $categoriesLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback() => Container(
        color: AppColors.sand100,
        child: const Center(
          child: Icon(
            Icons.beach_access_outlined,
            size: 54,
            color: AppColors.ocean700,
          ),
        ),
      );
}

