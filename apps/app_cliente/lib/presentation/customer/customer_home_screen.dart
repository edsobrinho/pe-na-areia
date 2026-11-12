import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/routes.dart';
import 'package:core_shared/core_shared.dart';
import '../beacon/signal_beacon_screen.dart';
import '../location_selection/location_selection_controller.dart';
import 'beach_cart_screen.dart';
import 'beach_spot_form_screen.dart';
import 'kiosk_storefront_screen.dart';
import 'menu_item_details_sheet.dart';
import 'popular_kiosks_screen.dart';
import 'order_details_sheet.dart';
import 'order_review_dialog.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.session,
    required this.authRepository,
    required this.catalogRepository,
    required this.orderRepository,
    required this.locationSelectionController,
    this.initialOrder,
  });

  final AuthSession session;
  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final OrderRepository orderRepository;
  final LocationSelectionController Function() locationSelectionController;
  final Order? initialOrder;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const List<String> _quickClientMessages = [
    'A maré subiu, mudei alguns metros para trás',
    'Estou de guarda-sol azul levantando o sinalizador',
    'Estou próximo ao posto selecionado',
  ];

  static const List<({String id, String label})> _beachCategories = [
    (id: 'ALL', label: 'Todos'),
    (id: 'SUSTENTAVEL', label: 'Sustentáveis'),
    (id: 'FREE_DELIVERY', label: 'Entrega Grátis'),
    (id: 'Porções', label: 'Porções'),
    (id: 'Frutos do Mar', label: 'Frutos do Mar'),
    (id: 'Bebidas', label: 'Bebidas'),
    (id: 'Lanches', label: 'Lanches'),
    (id: 'Açaí & Gelados', label: 'Açaí & Gelados'),
    (id: 'TOP', label: 'Destaques'),
    (id: 'Sobremesas', label: 'Doces'),
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
  final bool _onlyReturnableFilter = false;
  final bool _onlyFreeDeliveryFilter = false;
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
  Timer? _orderTimer;
  Timer? _liveTrackingTimer;
  GoogleMapController? _mapController;

  int get _totalCartUnits =>
      _quantities.values.fold<int>(0, (sum, qty) => sum + qty);

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _currentTabIndex = 1; // Seleciona automaticamente a aba de Acompanhamento do Pedido
    }
    _loadCatalog();
    _startOrderLiveTracking();
    _orderTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _order != null && _order!.isActive) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    _liveTrackingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startOrderLiveTracking() {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _order != null && _order!.isActive && !_refreshingOrder) {
        _refreshOrder();
      }
    });
  }

  void _updateMapCamera() {
    final order = _order;
    if (order == null || _mapController == null) return;
    final location = order.localizacao;
    final courier = order.localizacaoEntregador;
    if (location == null || courier == null) return;

    final south = location.latitude < courier.latitude
        ? location.latitude
        : courier.latitude;
    final north = location.latitude > courier.latitude
        ? location.latitude
        : courier.latitude;
    final west = location.longitude < courier.longitude
        ? location.longitude
        : courier.longitude;
    final east = location.longitude > courier.longitude
        ? location.longitude
        : courier.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    try {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (_) {
      // Tolera caso a view ainda não tenha dimensões calculadas
    }
  }

  void _openChat(Order order) {
    OrderChatBottomSheet.show(
      context,
      order: order,
      orderRepository: widget.orderRepository,
      currentUserRole: 'CLIENT',
      onOrderUpdated: (updated) {
        if (mounted) {
          setState(() => _order = updated);
          _updateMapCamera();
        }
      },
    );
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

  void _openItemDetails(MenuItem item) {
    final current = _quantities[item.id] ?? 0;
    MenuItemDetailsSheet.show(
      context,
      item: item,
      currentQuantity: current,
      onAddQuantity: (targetQty) {
        final delta = targetQty - current;
        if (delta != 0) {
          _changeQuantity(item, delta);
        } else if (current == 0) {
          _changeQuantity(item, 1);
        }
      },
    );
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
        _currentTabIndex = 1;
      });
      _startOrderLiveTracking();
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
      if (mounted) {
        final wasDelivered = _order?.status == OrderStatus.entregue;
        setState(() => _order = latest);
        _updateMapCamera();
        if (!wasDelivered && latest.status == OrderStatus.entregue && latest.avaliacao == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openReviewDialog(latest);
          });
        }
      }
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
        if (_selectedCategoryFilter == 'SUSTENTAVEL') {
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage500),
            )
          : IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildDiscoveryTab(totalUnits),
                _buildOrdersTab(),
                _buildAccountTab(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTheme.bottomSheetShadow,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  tooltip: 'Início',
                ),
                _buildBottomNavAction(
                  icon: Icons.search_rounded,
                  tooltip: 'Quiosques populares',
                  onTap: _openPopularKiosksScreen,
                ),
                _buildBottomNavItem(
                  index: 1,
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  tooltip: 'Pedidos',
                  badgeCount: _order != null ? 1 : totalUnits,
                ),
                _buildBottomNavItem(
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  tooltip: 'Conta',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String tooltip,
    int badgeCount = 0,
  }) {
    final selected = _currentTabIndex == index;
    final iconWidget = Icon(
      selected ? activeIcon : icon,
      size: 25,
      color: selected ? AppColors.sage500 : AppColors.ink400,
    );
    return IconButton(
      tooltip: tooltip,
      onPressed: () => setState(() => _currentTabIndex = index),
      icon: badgeCount > 0
          ? Badge(
              backgroundColor: AppColors.apricot500,
              label: Text('$badgeCount'),
              child: iconWidget,
            )
          : iconWidget,
    );
  }

  Widget _buildBottomNavAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 25, color: AppColors.ink400),
      );

  // ===========================================================================
  // ABA 1: INÍCIO — TELA 01 (`Home`: Header Claro + Promo #8BBFB0 + Inset Cards)
  // ===========================================================================
  Widget _buildDiscoveryTab(int totalUnits) {
    final filteredKiosks = _filteredKiosks;
    final popularKiosks =
        _kiosks.where((k) => k.destaquePopular).toList(growable: false);
    final userInitial = widget.session.name.trim().isEmpty
        ? 'P'
        : widget.session.name.trim()[0].toUpperCase();

    return RefreshIndicator(
      color: AppColors.sage500,
      onRefresh: _loadCatalog,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Top Bar Minimalista Clara (Padrão Exato da Tela 01 `Home`)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Definir ponto na areia',
                    onPressed: _openBeachSpotForm,
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.ink,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openBeachSpotForm,
                      child: Column(
                        children: [
                          const Text(
                            'Início',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: AppColors.apricot500,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _currentBeachSpot != null
                                      ? '${_currentBeachSpot!.etiquetaAmigavel} · ${_currentBeachSpot!.pontoReferenciaId.toUpperCase()}'
                                      : 'Marcar guarda-sol · Orla de Santos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (totalUnits > 0)
                    IconButton(
                      tooltip: 'Abrir sacola',
                      onPressed: _openBeachCart,
                      icon: Badge(
                        backgroundColor: AppColors.apricot500,
                        label: Text('$totalUnits'),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _currentTabIndex = 2),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.placeholder,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra de Busca Branca Flutuante (`Search` - Tela 01)
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
                hintText: 'Buscar porções, água de coco ou quiosque...',
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

          const SizedBox(height: 20),

          if (_error != null) ...[
            _errorCard(_error!),
            const SizedBox(height: 16),
          ],

          // Seção SPECIAL FOR YOU + Card Promocional Sage Mint (#8BBFB0 - Tela 01)
          const Text(
            'ESPECIAL PARA VOCÊ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sage500,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrega Sustentável na Faixa de Areia',
                        style: TextStyle(
                          color: AppColors.sage100,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Olá, ${widget.session.name.split(' ').first}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '0%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'plástico descartável',
                            style: TextStyle(
                              color: AppColors.sage100,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _openBeachSpotForm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sage300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _currentBeachSpot == null
                                ? 'MARCAR GUARDA-SOL'
                                : 'ALTERAR PONTO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 104,
                  height: 116,
                  decoration: BoxDecoration(
                    color: AppColors.sage200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.beach_access_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Indicadores de paginação do carrossel (exatos da Tela 01)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.sage500,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              for (var i = 0; i < 4; i++)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.sage200,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Seletor compacto de Canal de Venda (Parceria)
          if (_partnerships.length > 1) ...[
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 17,
                  color: AppColors.sage600,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Canal:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<Partnership>(
                    key: ValueKey(_selectedPartnership?.id ?? 'all'),
                    initialValue: _selectedPartnership,
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
                                partnership.id != _selectedPartnership?.id) {
                              _loadCatalog(selectedPartnership: partnership);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Carrossel de Pílulas de Categoria (Padrão Tela 02: All, Discount, Snack...)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _beachCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _beachCategories[index];
                final selected = _selectedCategoryFilter == cat.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() {
                    _selectedCategoryFilter = selected ? 'ALL' : cat.id;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.sage500 : AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? AppColors.sage500 : AppColors.line,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.ink500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Cabeçalho da Seção RESTAURANT / QUIOSQUES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUIOSQUES NA ORLA',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppColors.ink,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Ordenar quiosques',
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Ordenar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink700,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.ink700,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (popularKiosks.isNotEmpty)
                    TextButton(
                      onPressed: _openPopularKiosksScreen,
                      child: const Text('Ver todos'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (filteredKiosks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                'Nenhum quiosque está disponível para este filtro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.ink500),
              ),
            )
          else ...[
            ...filteredKiosks.map(_buildDiscoveryKioskCard),
            const SizedBox(height: 20),
            _buildKioskSelector(),
            if (_selectedKiosk case final kiosk?) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CARDÁPIO DE ${kiosk.nome.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openKioskStorefront(kiosk),
                    child: const Text('Ver vitrine'),
                  ),
                ],
              ),
              if (kiosk.cardapio.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Este quiosque não possui itens no cardápio.',
                    style: TextStyle(color: AppColors.ink500),
                  ),
                )
              else
                ...kiosk.cardapio
                    .where((item) => item.disponivel)
                    .map(_buildMenuItem),
              if (kiosk.aceitaEmbalagemSustentavel) ...[
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(
                    () => _sustainablePackaging = !_sustainablePackaging,
                  ),
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
                            color: _sustainablePackaging
                                ? AppColors.sage500
                                : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _sustainablePackaging
                                  ? AppColors.sage500
                                  : AppColors.lineStrong,
                              width: 1.5,
                            ),
                          ),
                          child: _sustainablePackaging
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
                            'Embalagem Sustentável',
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
              _buildCheckout(kiosk),
            ],
          ],
        ],
      ),
    );
  }

  /// Card Inset de Quiosque (Padrão Exato das Telas 01 e 02):
  /// Fundo `#FFFFFF`, borda `20px`, padding interno `12px` ao redor da foto
  /// arredondada (`14px`), subtítulo sutil + tag à direita, título forte `#292728`,
  /// estrelas `★★★★★` em damasco `#FF9749` e entregador + distância/tempo à direita.
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
    final subtitle = kiosk.categoriasDisponiveis.isEmpty
        ? 'Orla de Santos - Culinária Praiana'
        : '${kiosk.pontoReferenciaId.isEmpty ? 'Orla de Santos' : kiosk.pontoReferenciaId.toUpperCase()} - ${kiosk.categoriasDisponiveis.first}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          onTap: () => _openKioskStorefront(kiosk),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 156,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _kioskBannerFallback(),
                          )
                        : _kioskBannerFallback(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
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
                const SizedBox(height: 3),
                Text(
                  kiosk.nome,
                  style: const TextStyle(
                    fontSize: 15.5,
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
                        size: 14.5,
                        color: AppColors.apricot500,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      kiosk.avaliacaoMedia.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11.5,
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

  Widget _kioskBannerFallback() => Container(
        color: AppColors.placeholder,
        child: const Center(
          child: Icon(
            Icons.beach_access_rounded,
            color: AppColors.sage500,
            size: 40,
          ),
        ),
      );

  // ===========================================================================
  // ABA 2: PEDIDOS — TELA 05 (`Order Details`: Mapa #EAEEED + Cards Flutuantes)
  // ===========================================================================
  Widget _buildOrdersTab() {
    final order = _order;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voltar ao início',
                  onPressed: () => setState(() => _currentTabIndex = 0),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.ink,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Detalhes do Pedido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar status',
                  onPressed:
                      order == null || _refreshingOrder ? null : _refreshOrder,
                  icon: _refreshingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.sage500,
                          ),
                        )
                      : const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.ink,
                        ),
                ),
              ],
            ),
          ),
        ),
        if (order == null)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.placeholder,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.beach_access_outlined,
                    size: 32,
                    color: AppColors.sage500,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nenhum pedido em andamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha seu quiosque favorito na orla e acompanhe o entregador até o seu guarda-sol.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => setState(() => _currentTabIndex = 0),
                  child: const Text('EXPLORAR QUIOSQUES'),
                ),
              ],
            ),
          )
        else
          _buildOrderTracking(order),
      ],
    );
  }

  // ===========================================================================
  // ABA 3: CONTA — PERFIL MINIMALISTA DO BANHISTA
  // ===========================================================================
  Widget _buildAccountTab() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.placeholder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.ink700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const Text(
                          'Banhista · Orla de Santos',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.ink500,
                          ),
                        ),
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
                    icon: const Icon(
                      Icons.support_agent_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card de Acesso Rápido em 3 Colunas
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
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
                  subtitle: _order != null ? '1 ativo' : 'Histórico',
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Banner Educativo: Sinalizador Solar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.apricot100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flashlight_on_rounded,
                    size: 24,
                    color: AppColors.apricot500,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farol Visual na Areia',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Levante o celular para o entregador ver seu guarda-sol',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignalBeaconScreen(
                          orderId: _order?.id ?? 'DEMO01',
                          codigoEntrega: _order?.codigoEntrega ?? '4819',
                          descricaoLocal:
                              _currentBeachSpot?.descricaoLocal ??
                              'Guarda-sol de demonstração no Posto 4',
                        ),
                      ),
                    );
                  },
                  child: const Text('TESTAR'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu de Opções em Lista
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                ListTile(
                  leading: const Icon(
                    Icons.credit_card_outlined,
                    color: AppColors.sage600,
                  ),
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
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.sage600,
                  ),
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
                  leading: const Icon(
                    Icons.favorite_outline,
                    color: AppColors.apricot500,
                  ),
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
                    Icons.logout_rounded,
                    color: AppColors.danger500,
                  ),
                  title: const Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: AppColors.danger500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.placeholder,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.sage600, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.ink500),
              ),
            ],
          ),
        ),
      );

  // ===========================================================================
  // WIDGETS COMPARTILHADOS DE SELEÇÃO E ACOMPANHAMENTO (TELAS 04 E 05)
  // ===========================================================================
  Widget _buildKioskSelector() => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _kiosks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final kiosk = _kiosks[index];
            final selected = _selectedKiosk?.id == kiosk.id;
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _selectKiosk(kiosk),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.sage500 : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.sage500 : AppColors.line,
                  ),
                ),
                child: Text(
                  kiosk.nome,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.ink500,
                  ),
                ),
              ),
            );
          },
        ),
      );

  /// Card Horizontal de Item do Cardápio (Padrão Tela 04 + Toque abre Tela 03)
  Widget _buildMenuItem(MenuItem item) {
    final quantity = _quantities[item.id] ?? 0;
    final hasPhoto = item.fotoUrl != null && item.fotoUrl!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                        errorBuilder: (_, __, ___) => _menuItemPlaceholder(),
                      )
                    : _menuItemPlaceholder(),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (item.returnablePackaging)
                          const Tooltip(
                            message: 'Embalagem Sustentável',
                            child: Icon(
                              Icons.recycling_rounded,
                              size: 16,
                              color: AppColors.sage600,
                            ),
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
                            color: AppColors.ink500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                              IconButton(
                                tooltip: 'Remover ${item.nome}',
                                onPressed: quantity == 0
                                    ? null
                                    : () => _changeQuantity(item, -1),
                                icon: const Icon(
                                  Icons.remove,
                                  size: 15,
                                  color: AppColors.ink500,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Adicionar ${item.nome}',
                                onPressed: () => _changeQuantity(item, 1),
                                icon: const Icon(
                                  Icons.add,
                                  size: 15,
                                  color: AppColors.ink500,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
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
        ),
      ),
    );
  }

  Widget _menuItemPlaceholder() => Container(
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

  Widget _buildCheckout(Kiosk kiosk) {
    final total = kiosk.cardapio.fold<double>(
      0,
      (sum, item) => sum + item.preco * (_quantities[item.id] ?? 0),
    );
    final hasItems = _quantities.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL ($_totalCartUnits)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.ink500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.apricot400,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: hasItems && !_submittingOrder ? _openBeachCart : null,
              child: Text(
                _submittingOrder ? 'FINALIZANDO...' : 'REVISAR SACOLA',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rastreamento ao Vivo inspirado diretamente na Tela 05 (`Order Details`):
  /// Mapa em moldura `#EAEEED`, Card Flutuante do Entregador com 2 botões
  /// circulares em `#8BBFB0` (Mensagem e Telefone) e Card `PEDIDO` com caixas
  /// de ícone `38×38` em `#EAEEED` (`Endereço na Areia` e `Previsão`).
  Widget _buildOrderTracking(Order order) {
    final location = order.localizacao;
    final distMetros = order.distanciaEntregadorMetros;
    final canActivateBeacon = order.podeAtivarSinalizador;
    final isCourierOnRoute = order.status == OrderStatus.aCaminho ||
        order.status == OrderStatus.chegouNoLocal;
    final etaMinutes = distMetros != null ? (distMetros / 80).ceil() : 12;
    final etaFormatted =
        '${etaMinutes.toString().padLeft(2, '0')}:00 min · ${_statusLabel(order.status)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Mapa em Moldura #EAEEED (Tela 05)
        if (location != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.placeholder,
              borderRadius: BorderRadius.circular(24),
            ),
            child: _locationMap(order, location),
          ),
          const SizedBox(height: 14),
        ],

        // 2. Card Flutuante do Entregador (Tela 05 - "Natalya Undergrowth")
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.dragHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.placeholder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: AppColors.sage600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.courierNome?.isNotEmpty == true
                              ? order.courierNome!
                              : isCourierOnRoute
                                  ? 'Runner de Praia'
                                  : 'Aguardando Runner',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.courierVeiculoLabel.isNotEmpty
                              ? '${_statusLabel(order.status)} · ${order.courierVeiculoLabel}'
                              : _statusLabel(order.status),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão Circular Sage Mint: Mensagem Rápida
                  _buildCircularSageButton(
                    icon: Icons.mail_outline_rounded,
                    tooltip: 'Enviar aviso ao entregador',
                    onTap: () => _sendQuickClientMessage(
                      _quickClientMessages.first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão Circular Sage Mint: Telefone
                  _buildCircularSageButton(
                    icon: Icons.phone_outlined,
                    tooltip: 'Contato do entregador',
                    onTap: () {
                      final tel = order.courierTelefone ?? 'indisponível';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Telefone do entregador: $tel'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Card ORDER (Tela 05 - Endereço & Tempo + Botão Cápsula #8BBFB0)
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dragHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'PEDIDO ${order.codigoFormatado}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: order.isDelayed()
                              ? const Color(0xFFFFE4E6)
                              : AppColors.sage100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 13,
                              color: order.isDelayed()
                                  ? AppColors.danger500
                                  : AppColors.sage700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.formatElapsed(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: order.isDelayed()
                                    ? AppColors.danger500
                                    : AppColors.sage700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'R\$ ${order.valorTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.apricot400,
                    ),
                  ),
                ],
              ),
              if (order.isDelayed()) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.danger500.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger500,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pedido em atraso (${order.formatElapsed()} decorridos) — passou de 28 min. O restaurante e o entregador foram alertados.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildOrderInfoTile(
                icon: Icons.location_on_outlined,
                label: 'Ponto de Entrega na Areia',
                value: location != null && location.descricaoLocal.isNotEmpty
                    ? location.descricaoLocal
                    : 'Orla de Santos · Guarda-sol marcado no Pin',
              ),
              const SizedBox(height: 10),
              _buildOrderInfoTile(
                icon: Icons.access_time_rounded,
                label: 'Previsão e Status',
                value: etaFormatted,
              ),
              if (order.pixCopiaECola != null &&
                  order.pixCopiaECola!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPixPaymentBox(order),
              ],
              if (canActivateBeacon) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.apricot100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.apricot500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    '🏖️ Entregador a menos de 60m! Ative o Sinalizador de tela cheia para ser visto na areia.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.apricot600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.apricot500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignalBeaconScreen(
                          orderId: order.id,
                          descricaoLocal: order.localizacao?.descricaoLocal,
                          codigoEntrega: order.codigoEntrega,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.flashlight_on_outlined, size: 18),
                    label: const Text('ATIVAR SINALIZADOR NA PRAIA'),
                  ),
                ),
              ],
              if (isCourierOnRoute) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openChat(order),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.sage700,
                  ),
                  label: Text(
                    'CHAT COM O ENTREGADOR${order.mensagens.isNotEmpty ? " (${order.mensagens.length})" : ""}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sage700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildClientQuickMessages(order),
              ],
              if (order.codigoEntrega != null &&
                  order.codigoEntrega!.isNotEmpty &&
                  order.status != OrderStatus.entregue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.apricot100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.apricot500.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_outlined, color: AppColors.apricot600, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PIN DE ENTREGA (4 DÍGITOS)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.apricot700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'PIN DE ENTREGA: ${order.codigoEntrega!}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.apricot700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Fale este código ao entregador no momento da entrega',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.apricot700,
                        ),
                        onPressed: () => OrderDetailsSheet.show(
                          context,
                          order: order,
                          onReviewTap: () => _openReviewDialog(order),
                        ),
                        child: const Text('DETALHES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.status == OrderStatus.entregue) ...[
                const SizedBox(height: 12),
                if (order.avaliacao != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sage100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sage600.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.sage700, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Pedido Entregue e Avaliado ⭐',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.sage700),
                          ),
                        ),
                        TextButton(
                          onPressed: () => OrderDetailsSheet.show(
                            context,
                            order: order,
                            onReviewTap: () => _openReviewDialog(order),
                          ),
                          child: const Text('VER NOTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _openReviewDialog(order),
                      icon: const Icon(Icons.star_rounded, size: 20),
                      label: const Text('AVALIAR PEDIDO E ENTREGA (1 A 5 ★)'),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => OrderDetailsSheet.show(
                        context,
                        order: order,
                        onReviewTap: () => _openReviewDialog(order),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('DETALHES'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _refreshingOrder ? null : _refreshOrder,
                      child: Text(
                        _refreshingOrder
                            ? 'ATUALIZANDO...'
                            : 'ATUALIZAR',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openReviewDialog(Order order) {
    OrderReviewDialog.show(
      context,
      orderId: order.id,
      orderRepository: widget.orderRepository,
      onReviewSubmitted: (updated) {
        if (mounted) {
          setState(() => _order = updated);
        }
      },
    );
  }

  Widget _buildCircularSageButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.sage500,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      );

  Widget _buildOrderInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.placeholder,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: AppColors.ink700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPixPaymentBox(Order order) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sage100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sage300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pix, size: 18, color: AppColors.sage700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pix Antecipado · TxID: ${order.pixTxId ?? 'PNA'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyPixCode(order.pixCopiaECola!),
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copiar Pix'),
                ),
              ],
            ),
            Text(
              order.pixCopiaECola!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.ink500),
            ),
          ],
        ),
      );

  Widget _buildClientQuickMessages(Order order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVISOS RÁPIDOS NA AREIA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickClientMessages
                .map(
                  (msg) => ActionChip(
                    avatar: const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: AppColors.sage600,
                    ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink700,
                          ),
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

    if (!GoogleMapsChecker.isReady) {
      final dist = order.distanciaEntregadorMetros;
      final isNearby = dist != null && dist <= 60.0;
      final etaMinutes = dist != null ? (dist / 75.0).ceil() : null;
      final compassInstruction = (courier != null)
          ? BeachCompass.formatRadarInstruction(
              courierLat: courier.latitude,
              courierLng: courier.longitude,
              pinLat: location.latitude,
              pinLng: location.longitude,
            )
          : null;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isNearby ? AppColors.sage500 : AppColors.line,
            width: isNearby ? 1.5 : 1.0,
          ),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isNearby ? AppColors.sage100 : AppColors.apricot100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.beach_access_rounded,
                    color: isNearby ? AppColors.sage700 : AppColors.apricot600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ponto na Areia (Santos - SP)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.ink800,
                        ),
                      ),
                      Text(
                        location.descricaoLocal.isEmpty
                            ? 'Localização do guarda-sol'
                            : location.descricaoLocal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isNearby)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '≤ 60m (Próximo)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sage700,
                      ),
                    ),
                  ),
              ],
            ),
            if (dist != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isNearby ? AppColors.sage100 : AppColors.apricot100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          size: 16,
                          color: isNearby
                              ? AppColors.sage700
                              : AppColors.apricot700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Distância: ${dist.round()}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isNearby
                                ? AppColors.sage700
                                : AppColors.apricot700,
                          ),
                        ),
                      ],
                    ),
                    if (etaMinutes != null)
                      Text(
                        'Chegada em ~$etaMinutes min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isNearby
                              ? AppColors.sage700
                              : AppColors.apricot700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (compassInstruction != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined,
                        size: 16, color: AppColors.sage600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        compassInstruction,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.ink700,
                    ),
                  ),
                  const Text(
                    'Orla da Praia',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sage700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 215,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 16),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            _updateMapCamera();
          },
          markers: {
            Marker(
              markerId: const MarkerId('destino-pedido'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
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
                  BitmapDescriptor.hueCyan,
                ),
                infoWindow: const InfoWindow(title: 'Entregador na praia'),
              ),
          },
          polylines: {
            if (courierLatLng != null)
              Polyline(
                polylineId: const PolylineId('rota-areia'),
                points: [courierLatLng, position],
                color: AppColors.sage500,
                width: 4,
              ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _errorCard(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danger500.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.criado => 'Pedido criado',
        OrderStatus.pago => 'Pagamento confirmado',
        OrderStatus.emPreparo => 'Em preparo no restaurante',
        OrderStatus.prontoEntrega =>
          'O pedido está sendo retirado do local de entrega',
        OrderStatus.aCaminho => 'Entregador a caminho',
        OrderStatus.chegouNoLocal => 'Entregador chegou no local',
        OrderStatus.entregue => 'Pedido entregue',
        OrderStatus.cancelado => 'Pedido cancelado',
        OrderStatus.naoEncontrado => 'Não encontrado na praia',
        OrderStatus.desconhecido => 'Status atualizado',
      };
}
