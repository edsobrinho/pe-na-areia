import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/routes.dart';
import '../../data/http/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/geo.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/kiosk.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/order_status.dart';
import '../../domain/models/partnership.dart';
import '../../domain/models/payment_method.dart';
import '../beacon/signal_beacon_screen.dart';
import '../location_selection/location_selection_controller.dart';
import '../theme/app_colors.dart';
import 'beach_cart_screen.dart';
import 'beach_spot_form_screen.dart';
import 'kiosk_storefront_screen.dart';
import 'popular_kiosks_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.session,
    required this.authRepository,
    required this.catalogRepository,
    required this.orderRepository,
    required this.locationSelectionController,
  });

  final AuthSession session;
  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final OrderRepository orderRepository;
  final LocationSelectionController Function() locationSelectionController;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const List<String> _quickClientMessages = [
    'A maré subiu, mudei alguns metros para trás',
    'Estou de guarda-sol azul levantando o sinalizador',
    'Estou próximo ao posto selecionado',
  ];

  static const List<({String id, String label, IconData icon, Color bg})>
      _beachCategories = [
    (
      id: 'Porções',
      label: 'Porções',
      icon: Icons.restaurant_menu,
      bg: AppColors.sand100,
    ),
    (
      id: 'Frutos do Mar',
      label: 'Frutos do Mar',
      icon: Icons.set_meal_outlined,
      bg: AppColors.sand50,
    ),
    (
      id: 'Bebidas',
      label: 'Bebidas',
      icon: Icons.local_drink_outlined,
      bg: AppColors.sand100,
    ),
    (
      id: 'Lanches',
      label: 'Lanches',
      icon: Icons.lunch_dining_outlined,
      bg: AppColors.sand50,
    ),
    (
      id: 'Açaí & Gelados',
      label: 'Açaí & Gelados',
      icon: Icons.icecream_outlined,
      bg: AppColors.sand100,
    ),
    (
      id: 'RETORNABLE',
      label: 'Retornáveis',
      icon: Icons.recycling,
      bg: Color(0xFFE0F2FE),
    ),
    (
      id: 'TOP',
      label: 'Bem avaliados',
      icon: Icons.workspace_premium_outlined,
      bg: Color(0xFFFEF3C7),
    ),
    (
      id: 'Sobremesas',
      label: 'Doces',
      icon: Icons.cake_outlined,
      bg: AppColors.sand50,
    ),
    (
      id: 'FREE_DELIVERY',
      label: 'Entrega Grátis',
      icon: Icons.directions_walk,
      bg: Color(0xFFDCFCE7),
    ),
    (
      id: 'ALL',
      label: 'Todos',
      icon: Icons.beach_access_outlined,
      bg: AppColors.sand100,
    ),
  ];

  int _currentTabIndex = 0;

  List<Kiosk> _kiosks = const [];
  List<Partnership> _partnerships = const [];
  final Map<String, KioskPartnershipOffer> _offersByKioskId = {};
  final Set<String> _favoriteKioskIds = {};
  final List<OrderLocation> _savedBeachSpots = [];

  Partnership? _selectedPartnership;
  Kiosk? _selectedKiosk;
  OrderLocation? _currentBeachSpot;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'ALL';
  bool _onlyReturnableFilter = false;
  bool _onlyFreeDeliveryFilter = false;
  String _sortMode = 'DEFAULT';

  final Map<String, int> _quantities = {};
  PaymentMethod _paymentMethod = PaymentMethod.pix;
  bool _sustainablePackaging = false;
  bool _loadingCatalog = true;
  bool _submittingOrder = false;
  bool _refreshingOrder = false;
  String? _error;
  Order? _order;
  int _catalogRequestId = 0;

  int get _totalCartUnits =>
      _quantities.values.fold<int>(0, (sum, qty) => sum + qty);

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog({Partnership? selectedPartnership}) async {
    final requestId = ++_catalogRequestId;
    setState(() {
      _loadingCatalog = true;
      _error = null;
    });
    try {
      final partnerships = await widget.catalogRepository.fetchPartnerships();
      final partnership = selectedPartnership ??
          _selectedPartnership ??
          (partnerships.isEmpty ? null : partnerships.first);
      final kiosks = partnership == null
          ? <Kiosk>[]
          : await widget.catalogRepository.fetchKiosks(
              partnershipId: partnership.id,
            );

      final offersMap = <String, KioskPartnershipOffer>{};
      for (final kiosk in kiosks) {
        try {
          final offers =
              await widget.catalogRepository.fetchKioskOffers(kiosk.id);
          final matching = offers.where(
            (o) => partnership == null || o.partnershipId == partnership.id,
          );
          if (matching.isNotEmpty) {
            offersMap[kiosk.id] = matching.first;
          } else if (offers.isNotEmpty) {
            offersMap[kiosk.id] = offers.first;
          }
        } catch (_) {
          // Segue com valores padrão se o quiosque ainda não retornar ofertas detalhadas.
        }
      }

      if (!mounted || requestId != _catalogRequestId) return;
      setState(() {
        _partnerships = partnerships;
        _selectedPartnership = partnership;
        _kiosks = kiosks;
        _offersByKioskId
          ..clear()
          ..addAll(offersMap);
        _selectedKiosk = kiosks.isEmpty ? null : kiosks.first;
        _loadingCatalog = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _catalogRequestId) return;
      setState(() {
        _error = error.message;
        _loadingCatalog = false;
      });
    }
  }

  void _selectKiosk(Kiosk kiosk) {
    setState(() {
      if (_selectedKiosk?.id != kiosk.id) {
        _selectedKiosk = kiosk;
        _quantities.clear();
        _sustainablePackaging = false;
      }
    });
  }

  void _changeQuantity(MenuItem item, int delta) {
    setState(() {
      final quantity = (_quantities[item.id] ?? 0) + delta;
      if (quantity <= 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = quantity;
      }
    });
  }

  Future<OrderLocation?> _openBeachSpotForm() async {
    final location = await Navigator.of(context).push<OrderLocation>(
      MaterialPageRoute(
        builder: (_) => BeachSpotFormScreen(
          controllerFactory: widget.locationSelectionController,
          initialLocation: _currentBeachSpot,
          defaultContactName: widget.session.name,
        ),
      ),
    );
    if (!mounted || location == null) return null;
    setState(() {
      _currentBeachSpot = location;
      _savedBeachSpots.removeWhere(
        (s) => s.etiquetaLocal == location.etiquetaLocal,
      );
      _savedBeachSpots.insert(0, location);
    });
    return location;
  }

  void _openPopularKiosksScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PopularKiosksScreen(
          kiosks: _kiosks,
          offersByKioskId: _offersByKioskId,
          customerPin: _currentBeachSpot == null
              ? null
              : GeoPoint(
                  latitude: _currentBeachSpot!.latitude,
                  longitude: _currentBeachSpot!.longitude,
                ),
          onSelectKiosk: (kiosk) {
            _selectKiosk(kiosk);
            _openKioskStorefront(kiosk);
          },
        ),
      ),
    );
  }

  void _openKioskStorefront(Kiosk kiosk) {
    _selectKiosk(kiosk);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KioskStorefrontScreen(
          kiosk: kiosk,
          offer: _offersByKioskId[kiosk.id],
          quantities: _quantities,
          onChangeQuantity: _changeQuantity,
          onOpenCart: _openBeachCart,
          isFavorite: _favoriteKioskIds.contains(kiosk.id),
          onToggleFavorite: () {
            setState(() {
              if (_favoriteKioskIds.contains(kiosk.id)) {
                _favoriteKioskIds.remove(kiosk.id);
              } else {
                _favoriteKioskIds.add(kiosk.id);
              }
            });
          },
        ),
      ),
    );
  }

  void _openBeachCart() {
    final kiosk = _selectedKiosk;
    if (kiosk == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeachCartScreen(
          kiosk: kiosk,
          offer: _offersByKioskId[kiosk.id],
          quantities: _quantities,
          paymentMethod: _paymentMethod,
          sustainablePackaging: _sustainablePackaging,
          onChangeQuantity: _changeQuantity,
          onClearCart: () => setState(_quantities.clear),
          onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
          onSustainableChanged: (v) =>
              setState(() => _sustainablePackaging = v),
          onContinueCheckout: _checkout,
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    final kiosk = _selectedKiosk;
    final partnership = _selectedPartnership;
    final items = _quantities.entries
        .map((entry) => OrderItemRequest(
              menuItemId: entry.key,
              quantidade: entry.value,
            ))
        .toList(growable: false);
    if (kiosk == null ||
        partnership == null ||
        items.isEmpty ||
        _submittingOrder) {
      return;
    }

    setState(() {
      _submittingOrder = true;
      _error = null;
    });
    try {
      final location = _currentBeachSpot ?? await _openBeachSpotForm();
      if (!mounted || location == null) return;
      final order = await widget.orderRepository.createOrder(
        userId: widget.session.userId,
        kioskId: kiosk.id,
        partnershipId: partnership.id,
        itens: items,
        formaPagamento: _paymentMethod,
        localizacao: location,
        embalagemSustentavel: _sustainablePackaging,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _quantities.clear();
        _currentTabIndex = 1; // Vai para a aba Pedidos acompanhar ao vivo
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submittingOrder = false);
    }
  }

  Future<void> _refreshOrder() async {
    final order = _order;
    if (order == null || _refreshingOrder) return;
    setState(() {
      _refreshingOrder = true;
      _error = null;
    });
    try {
      final latest = await widget.orderRepository.fetchOrderById(order.id);
      if (mounted) setState(() => _order = latest);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _refreshingOrder = false);
    }
  }

  Future<void> _sendQuickClientMessage(String text) async {
    final order = _order;
    if (order == null || _refreshingOrder) return;
    setState(() {
      _refreshingOrder = true;
      _error = null;
    });
    try {
      final updated = await widget.orderRepository.sendOrderMessage(
        orderId: order.id,
        texto: text,
      );
      if (mounted) setState(() => _order = updated);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _refreshingOrder = false);
    }
  }

  Future<void> _copyPixCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código Pix Copia e Cola copiado!')),
    );
  }

  Future<void> _logout() async {
    await widget.authRepository.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  List<Kiosk> get _filteredKiosks {
    final q = _searchQuery.trim().toLowerCase();
    var list = _kiosks.where((kiosk) {
      if (q.isNotEmpty) {
        final matchKiosk = kiosk.nome.toLowerCase().contains(q) ||
            (kiosk.descricaoCurta?.toLowerCase().contains(q) ?? false);
        final matchItem = kiosk.cardapio.any(
          (i) =>
              i.disponivel &&
              (i.nome.toLowerCase().contains(q) ||
                  i.descricao.toLowerCase().contains(q)),
        );
        if (!matchKiosk && !matchItem) return false;
      }
      if (_onlyReturnableFilter && !kiosk.aceitaEmbalagemSustentavel) {
        return false;
      }
      if (_onlyFreeDeliveryFilter) {
        final offer = _offersByKioskId[kiosk.id];
        if (offer != null && !offer.isFreeDelivery) return false;
      }
      if (_selectedCategoryFilter != 'ALL') {
        if (_selectedCategoryFilter == 'RETORNABLE') {
          return kiosk.aceitaEmbalagemSustentavel;
        }
        if (_selectedCategoryFilter == 'FREE_DELIVERY') {
          final offer = _offersByKioskId[kiosk.id];
          return offer == null || offer.isFreeDelivery;
        }
        if (_selectedCategoryFilter == 'TOP') {
          return kiosk.avaliacaoMedia >= 4.5;
        }
        return kiosk.categoriasDisponiveis.contains(_selectedCategoryFilter);
      }
      return true;
    }).toList();

    list.sort((a, b) {
      final offerA = _offersByKioskId[a.id];
      final offerB = _offersByKioskId[b.id];
      switch (_sortMode) {
        case 'TEMPO':
          return (offerA?.prepMinutes ?? 20)
              .compareTo(offerB?.prepMinutes ?? 20);
        case 'TAXA':
          return (offerA?.customerDeliveryFee ?? 0)
              .compareTo(offerB?.customerDeliveryFee ?? 0);
        default:
          return b.avaliacaoMedia.compareTo(a.avaliacaoMedia);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _totalCartUnits;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildDiscoveryTab(totalUnits),
                _buildOrdersTab(),
                _buildAccountTab(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.sand100,
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.ocean900),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _order != null,
              label: const Text('1'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(
              Icons.receipt_long,
              color: AppColors.ocean900,
            ),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.ocean900),
            label: 'Conta',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ABA 1: INÍCIO — VITRINE PRINCIPAL DE DESCOBERTA DA ORLA (TELA 2)
  // ===========================================================================
  Widget _buildDiscoveryTab(int totalUnits) {
    final filteredKiosks = _filteredKiosks;
    final popularKiosks =
        _kiosks.where((k) => k.destaquePopular).toList(growable: false);

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Costeiro (Localização + Sacola + Busca + Banner Praia Limpa)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.ocean900, AppColors.ocean700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha superior: Ponto na Praia + Ícone da Sacola com Badge
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.destination,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: _openBeachSpotForm,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _currentBeachSpot != null
                                    ? '${_currentBeachSpot!.etiquetaAmigavel} · ${_currentBeachSpot!.pontoReferenciaId.toUpperCase()}'
                                    : 'Escolher meu ponto na areia · Santos, SP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir sacola',
                      onPressed: _openBeachCart,
                      icon: Badge(
                        isLabelVisible: totalUnits > 0,
                        backgroundColor: AppColors.mango500,
                        label: Text('$totalUnits'),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Barra de Busca Instantânea
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Porções, água de coco, açaí ou quiosque...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Banner Sustentável / Identidade Pé na Areia
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.ocean500.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mango500,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ENTREGA NO GUARDA-SOL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Olá, ${widget.session.name}! Peça com Embalagem Retornável na orla.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sand100,
                          foregroundColor: AppColors.ocean900,
                        ),
                        onPressed: _openBeachSpotForm,
                        child: const Text(
                          'Marcar Pin',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  _errorCard(_error!),
                  const SizedBox(height: 12),
                ],

                // Seletor compacto de Canal de Venda (Parceria)
                if (_partnerships.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.ocean700,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Canal de venda:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<Partnership>(
                          value: _selectedPartnership,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _partnerships
                              .map(
                                (partnership) => DropdownMenuItem(
                                  value: partnership,
                                  child: Text(partnership.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _loadingCatalog
                              ? null
                              : (partnership) {
                                  if (partnership != null &&
                                      partnership.id !=
                                          _selectedPartnership?.id) {
                                    _loadCatalog(
                                      selectedPartnership: partnership,
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Grade de 10 Categorias Praianas (2 linhas x 5 colunas)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _beachCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _beachCategories[index];
                    final selected = _selectedCategoryFilter == cat.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _selectedCategoryFilter =
                            selected ? 'ALL' : cat.id;
                      }),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.ocean700 : cat.bg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              cat.icon,
                              color: selected
                                  ? Colors.white
                                  : AppColors.ocean900,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Seção Horizontal: Quiosques Populares na Orla
                if (popularKiosks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quiosques populares na orla',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ver todos os quiosques populares',
                        onPressed: _openPopularKiosksScreen,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularKiosks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final kiosk = popularKiosks[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openKioskStorefront(kiosk),
                          child: Container(
                            width: 78,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.ocean900,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.beach_access,
                                  color: AppColors.destination,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kiosk.nome,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Barra de Chips de Filtro e Ordenação
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (v) => setState(() => _sortMode = v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'DEFAULT',
                            child: Text('Melhor avaliação'),
                          ),
                          PopupMenuItem(
                            value: 'TEMPO',
                            child: Text('Menor tempo na areia'),
                          ),
                          PopupMenuItem(
                            value: 'TAXA',
                            child: Text('Menor taxa de entrega'),
                          ),
                        ],
                        child: Chip(
                          backgroundColor: AppColors.surface,
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ordenar'),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('♻️ Embalagem Retornável'),
                        selected: _onlyReturnableFilter,
                        onSelected: (val) =>
                            setState(() => _onlyReturnableFilter = val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('🏃 Entrega grátis'),
                        selected: _onlyFreeDeliveryFilter,
                        onSelected: (val) =>
                            setState(() => _onlyFreeDeliveryFilter = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Lista de Quiosques da Orla
                Text(
                  'Quiosques',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                if (filteredKiosks.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhum quiosque está disponível para este filtro.',
                      ),
                    ),
                  )
                else ...[
                  ...filteredKiosks.map(_buildDiscoveryKioskCard),
                  const SizedBox(height: 16),
                  _buildKioskSelector(),
                  if (_selectedKiosk case final kiosk?) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Cardápio rápido de ${kiosk.nome}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openKioskStorefront(kiosk),
                          icon: const Icon(Icons.storefront, size: 16),
                          label: const Text('Abrir loja completa'),
                        ),
                      ],
                    ),
                    if (kiosk.cardapio.isEmpty)
                      const ListTile(
                        title: Text(
                          'Este quiosque não possui itens no cardápio.',
                        ),
                      )
                    else
                      ...kiosk.cardapio
                          .where((item) => item.disponivel)
                          .map(_buildMenuItem),
                    if (kiosk.aceitaEmbalagemSustentavel)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Embalagem sustentável'),
                        value: _sustainablePackaging,
                        onChanged: (value) =>
                            setState(() => _sustainablePackaging = value),
                      ),
                    const SizedBox(height: 8),
                    _buildCheckout(kiosk),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryKioskCard(Kiosk kiosk) {
    final offer = _offersByKioskId[kiosk.id];
    final imageUrl = kiosk.imagemDestaqueUrl;
    final fee = offer?.customerDeliveryFee ?? 0.0;
    final timeRange = offer?.estimatedTimeRangeLabel ?? '20 a 30 min';
    final distKm = _currentBeachSpot != null && kiosk.localizacao != null
        ? distanceMeters(
              GeoPoint(
                latitude: _currentBeachSpot!.latitude,
                longitude: _currentBeachSpot!.longitude,
              ),
              kiosk.localizacao!,
            ) /
            1000.0
        : 0.4;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openKioskStorefront(kiosk),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _kioskThumbFallback(),
                      )
                    : _kioskThumbFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kiosk.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.destination,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          kiosk.avaliacaoMedia.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fee <= 0 ? 'R\$ 0' : 'R\$ ${fee.toStringAsFixed(2)}'} · $timeRange · ${distKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sand100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kiosk.aceitaEmbalagemSustentavel
                            ? '♻️ Embalagem Retornável na Areia'
                            : '🏖️ Entrega no Pin da Praia',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ocean900,
                        ),
                      ),
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

  Widget _kioskThumbFallback() => Container(
        width: 84,
        height: 84,
        color: AppColors.sand50,
        child: const Center(
          child: Icon(Icons.beach_access, color: AppColors.ocean700, size: 32),
        ),
      );

  // ===========================================================================
  // ABA 2: PEDIDOS — LIVE TRACKING, PIX COPIA E COLA, FAROL VISUAL E MENSAGENS
  // ===========================================================================
  Widget _buildOrdersTab() {
    final order = _order;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      children: [
        const Text(
          'Meus Pedidos na Praia',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (order == null)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.beach_access_outlined,
                    size: 48,
                    color: AppColors.ocean700,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Você ainda não tem um pedido em andamento na praia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mango500,
                    ),
                    onPressed: () => setState(() => _currentTabIndex = 0),
                    child: const Text('Explorar quiosques na orla'),
                  ),
                ],
              ),
            ),
          )
        else
          _buildOrderTracking(order),
      ],
    );
  }

  // ===========================================================================
  // ABA 3: CONTA — PERFIL DO BANHISTA E SINALIZADOR SOLAR (TELA 6)
  // ===========================================================================
  Widget _buildAccountTab() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          // Cabeçalho com Nome do Cliente e Botão de Suporte
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.session.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Suporte na praia',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Suporte Pé na Areia ativo para a Orla de Santos!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card de Acesso Rápido em 3 Colunas
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAccountQuickAction(
                  icon: Icons.pin_drop_outlined,
                  label: 'Ponto na Areia',
                  subtitle: _currentBeachSpot?.etiquetaAmigavel ?? 'Definir',
                  onTap: _openBeachSpotForm,
                ),
                _buildAccountQuickAction(
                  icon: Icons.pix_outlined,
                  label: 'Pagamento',
                  subtitle:
                      _paymentMethod == PaymentMethod.pix ? 'PIX' : 'Cartão',
                  onTap: () {
                    setState(() {
                      _paymentMethod = _paymentMethod == PaymentMethod.pix
                          ? PaymentMethod.cartao
                          : PaymentMethod.pix;
                    });
                  },
                ),
                _buildAccountQuickAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Pedidos',
                  subtitle: _order != null ? '1 ativo' : 'Ver histórico',
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Banner Educativo: Conheça o Sinalizador Solar (Farol de Tela Cheia)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sand50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sand100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flashlight_on_rounded,
                  size: 38,
                  color: AppColors.mango500,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farol Visual na Faixa de Areia',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Levante o celular para o entregador te avistar no guarda-sol',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ocean900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignalBeaconScreen(
                          orderId: _order?.id ?? 'DEMO01',
                          descricaoLocal:
                              _currentBeachSpot?.descricaoLocal ??
                              'Guarda-sol de demonstração no Posto 4',
                        ),
                      ),
                    );
                  },
                  child: const Text('Testar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Menu de Opções em Lista
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card_outlined),
                  title: const Text('Formas de pagamento'),
                  subtitle: Text(
                    _paymentMethod == PaymentMethod.pix
                        ? 'Padrão: PIX Antecipado (Zero dinheiro na areia)'
                        : 'Padrão: Cartão',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _paymentMethod = _paymentMethod == PaymentMethod.pix
                          ? PaymentMethod.cartao
                          : PaymentMethod.pix;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Pontos de entrega na praia'),
                  subtitle: Text(
                    _savedBeachSpots.isEmpty
                        ? 'Toque para cadastrar seu guarda-sol e posto'
                        : '${_savedBeachSpots.length} ponto(s) salvo(s) na orla',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openBeachSpotForm,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Quiosques favoritos'),
                  subtitle: Text(
                    '${_favoriteKioskIds.length} quiosque(s) favoritado(s)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openPopularKiosksScreen,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.seafoam500,
                  ),
                  title: const Text('Entrega Garantida no Pin (Raio 60m)'),
                  subtitle: const Text(
                    'Validação por GPS e Bússola Pedestre na Areia',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Código e Sinalizador de entrega'),
                  subtitle: Text(
                    _order != null
                        ? 'Pedido ativo #${_order!.id}'
                        : 'Disponível quando houver entrega em rota',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.brandRed,
                  ),
                  title: const Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildAccountQuickAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              Icon(icon, color: AppColors.mango500, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      );

  // ===========================================================================
  // WIDGETS COMPARTILHADOS DE SELEÇÃO E ACOMPANHAMENTO DO PEDIDO
  // ===========================================================================
  Widget _buildKioskSelector() => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _kiosks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final kiosk = _kiosks[index];
            return ChoiceChip(
              label: Text(kiosk.nome),
              selected: _selectedKiosk?.id == kiosk.id,
              onSelected: (_) => _selectKiosk(kiosk),
            );
          },
        ),
      );

  Widget _buildMenuItem(MenuItem item) {
    final quantity = _quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasPhoto
                  ? Image.network(
                      item.fotoUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _menuItemPlaceholder(),
                    )
                  : _menuItemPlaceholder(),
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
                          item.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.returnablePackaging)
                        const Tooltip(
                          message: 'Embalagem retornável',
                          child: Text('🌱', style: TextStyle(fontSize: 15)),
                        ),
                    ],
                  ),
                  if (item.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.descricao,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'R\$ ${item.preco.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remover ${item.nome}',
                        onPressed: quantity == 0
                            ? null
                            : () => _changeQuantity(item, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Adicionar ${item.nome}',
                        onPressed: () => _changeQuantity(item, 1),
                        icon: const Icon(Icons.add_circle_outline),
                        visualDensity: VisualDensity.compact,
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

  Widget _menuItemPlaceholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('🍽️', style: TextStyle(fontSize: 28)),
        ),
      );

  Widget _buildCheckout(Kiosk kiosk) {
    final total = kiosk.cardapio.fold<double>(
      0,
      (sum, item) => sum + item.preco * (_quantities[item.id] ?? 0),
    );
    final hasItems = _quantities.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasItems ? _openBeachCart : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text('Ver sacola ($_totalCartUnits)'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mango500,
              foregroundColor: Colors.white,
            ),
            onPressed: hasItems && !_submittingOrder ? _checkout : null,
            icon: _submittingOrder
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_on_outlined),
            label: Text(
              _submittingOrder
                  ? 'Finalizando pedido...'
                  : 'Escolher local · R\$ ${total.toStringAsFixed(2)}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTracking(Order order) {
    final location = order.localizacao;
    final distMetros = order.distanciaEntregadorMetros;
    final canActivateBeacon = order.podeAtivarSinalizador;
    final isCourierOnRoute = order.status == OrderStatus.aCaminho ||
        order.status == OrderStatus.chegouNoLocal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Acompanhe seu pedido',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar status',
                  onPressed: _refreshingOrder ? null : _refreshOrder,
                  icon: _refreshingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            Text('Pedido ${order.id} · ${_statusLabel(order.status)}'),
            if (distMetros != null && isCourierOnRoute)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📍 Entregador a ${distMetros.round()} m de distância na praia',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (order.pago)
                  const Chip(
                    avatar:
                        Icon(Icons.check_circle, color: AppColors.positive),
                    label: Text('Pago (Zero dinheiro na areia)'),
                  ),
              ],
            ),
            if (order.pixCopiaECola != null &&
                order.pixCopiaECola!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPixPaymentBox(order),
            ],
            if (location != null) ...[
              const SizedBox(height: 8),
              _locationMap(order, location),
              if (location.descricaoLocal.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Ponto escolhido: ${location.descricaoLocal}'),
                ),
              if (location.contatoNome != null &&
                  location.contatoNome!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Recebedor: ${location.contatoNome} (${location.etiquetaAmigavel})',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
            if (canActivateBeacon) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF7A3D)),
                ),
                child: const Text(
                  '🏖️ Seu entregador está a menos de 60m na areia! Saia do mar e ative o Sinalizador para ser visto.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A3D),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SignalBeaconScreen(
                      orderId: order.id,
                      descricaoLocal: order.localizacao?.descricaoLocal,
                    ),
                  ),
                ),
                icon: const Icon(Icons.flashlight_on_outlined),
                label: const Text('🔦 Ativar Sinalizador na Praia'),
              ),
            ],
            if (isCourierOnRoute) ...[
              const SizedBox(height: 12),
              _buildClientQuickMessages(order),
            ],
            const SizedBox(height: 8),
            const Text(
              'O status e a posição do entregador são atualizados em tempo real.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixPaymentBox(Order order) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pix, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pix Antecipado · TxID: ${order.pixTxId ?? 'PNA'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyPixCode(order.pixCopiaECola!),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar Pix'),
                ),
              ],
            ),
            Text(
              order.pixCopiaECola!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      );

  Widget _buildClientQuickMessages(Order order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contato rápido de emergência na areia:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickClientMessages
                .map(
                  (msg) => ActionChip(
                    avatar: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: Text(msg, style: const TextStyle(fontSize: 11)),
                    onPressed: _refreshingOrder
                        ? null
                        : () => _sendQuickClientMessage(msg),
                  ),
                )
                .toList(growable: false),
          ),
          if (order.mensagens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.mensagens.reversed
                    .take(3)
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${m.senderRole == 'CLIENT' ? 'Você' : 'Entregador'}: ${m.texto}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      );

  Widget _locationMap(Order order, OrderLocation location) {
    final position = LatLng(location.latitude, location.longitude);
    final courier = order.localizacaoEntregador;
    final courierLatLng = courier != null
        ? LatLng(courier.latitude, courier.longitude)
        : null;

    return SizedBox(
      height: 190,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 16),
          markers: {
            Marker(
              markerId: const MarkerId('destino-pedido'),
              position: position,
              infoWindow: InfoWindow(
                title: location.descricaoLocal.isEmpty
                    ? 'Local de entrega'
                    : location.descricaoLocal,
              ),
            ),
            if (courierLatLng != null)
              Marker(
                markerId: const MarkerId('entregador-pedido'),
                position: courierLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: const InfoWindow(title: 'Entregador na praia'),
              ),
          },
          polylines: {
            if (courierLatLng != null)
              Polyline(
                polylineId: const PolylineId('rota-areia'),
                points: [courierLatLng, position],
                color: const Color(0xFFFF7A3D),
                width: 4,
              ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _errorCard(String message) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message),
        ),
      );

  String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.criado => 'Pedido criado',
        OrderStatus.pago => 'Pago',
        OrderStatus.emPreparo => 'Em preparo',
        OrderStatus.aCaminho => 'A caminho',
        OrderStatus.chegouNoLocal => 'Entregador chegou',
        OrderStatus.entregue => 'Entregue',
        OrderStatus.cancelado => 'Cancelado',
        OrderStatus.naoEncontrado => 'Não encontrado na praia',
        OrderStatus.desconhecido => 'Status atualizado',
      };
}
