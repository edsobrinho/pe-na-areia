import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/routes.dart';
import '../../data/http/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/kiosk.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/order_status.dart';
import '../../domain/models/partnership.dart';
import '../../domain/models/payment_method.dart';
import '../location_selection/location_selection_controller.dart';
import '../location_selection/location_selection_screen.dart';
import '../theme/app_colors.dart';

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
  List<Kiosk> _kiosks = const [];
  List<Partnership> _partnerships = const [];
  Partnership? _selectedPartnership;
  Kiosk? _selectedKiosk;
  final Map<String, int> _quantities = {};
  PaymentMethod _paymentMethod = PaymentMethod.pix;
  bool _sustainablePackaging = false;
  bool _loadingCatalog = true;
  bool _submittingOrder = false;
  bool _refreshingOrder = false;
  String? _error;
  Order? _order;
  int _catalogRequestId = 0;

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
      if (!mounted || requestId != _catalogRequestId) return;
      setState(() {
        _partnerships = partnerships;
        _selectedPartnership = partnership;
        _kiosks = kiosks;
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
      _selectedKiosk = kiosk;
      _quantities.clear();
      _sustainablePackaging = false;
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

  Future<void> _checkout() async {
    final kiosk = _selectedKiosk;
    final partnership = _selectedPartnership;
    final items = _quantities.entries
        .map((entry) => OrderItemRequest(
              menuItemId: entry.key,
              quantidade: entry.value,
            ))
        .toList(growable: false);
    if (kiosk == null || partnership == null || items.isEmpty || _submittingOrder) return;

    setState(() {
      _submittingOrder = true;
      _error = null;
    });
    try {
      final location = await Navigator.of(context).push<OrderLocation>(
        MaterialPageRoute(
          builder: (_) => LocationSelectionScreen(
            controller: widget.locationSelectionController(),
          ),
        ),
      );
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

  Future<void> _logout() async {
    await widget.authRepository.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.brandRed,
          foregroundColor: Colors.white,
          title: const Text('Pé na Areia'),
          actions: [
            IconButton(
              tooltip: 'Sair',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _loadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCatalog,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Olá, ${widget.session.name}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    const Text('Escolha um quiosque e peça onde estiver.'),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _errorCard(_error!),
                    ],
                    if (_order != null) ...[
                      const SizedBox(height: 20),
                      _buildOrderTracking(_order!),
                    ],
                    const SizedBox(height: 20),
                    if (_partnerships.isNotEmpty) ...[
                      Text('Canal de venda',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Partnership>(
                        value: _selectedPartnership,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        items: _partnerships
                            .map((partnership) => DropdownMenuItem(
                                  value: partnership,
                                  child: Text(partnership.name),
                                ))
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
                      const SizedBox(height: 12),
                    ],
                    Text('Quiosques',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (_kiosks.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nenhum quiosque está disponível. Tente novamente mais tarde.',
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      _buildKioskSelector(),
                      if (_selectedKiosk case final kiosk?) ...[
                        const SizedBox(height: 12),
                        Text('Cardápio de ${kiosk.nome}',
                            style: Theme.of(context).textTheme.titleMedium),
                        if (kiosk.cardapio.isEmpty)
                          const ListTile(
                            title: Text('Este quiosque não possui itens no cardápio.'),
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
                        Text('Forma de pagamento',
                            style: Theme.of(context).textTheme.titleMedium),
                        ...PaymentMethod.values.map(
                          (method) => RadioListTile<PaymentMethod>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(method == PaymentMethod.pix
                                ? 'PIX'
                                : 'Cartão'),
                            value: method,
                            groupValue: _paymentMethod,
                            onChanged: (value) => setState(
                              () => _paymentMethod = value ?? _paymentMethod,
                            ),
                          ),
                        ),
                        _buildCheckout(kiosk),
                      ],
                    ],
                  ],
                ),
              ),
      );

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
    return Card(
      child: ListTile(
        title: Text(item.nome),
        subtitle: Text(
          '${item.descricao.isEmpty ? '' : '${item.descricao}\n'}'
          'R\$ ${item.preco.toStringAsFixed(2)}',
        ),
        isThreeLine: item.descricao.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remover ${item.nome}',
              onPressed: quantity == 0 ? null : () => _changeQuantity(item, -1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$quantity'),
            IconButton(
              tooltip: 'Adicionar ${item.nome}',
              onPressed: () => _changeQuantity(item, 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckout(Kiosk kiosk) {
    final total = kiosk.cardapio.fold<double>(
      0,
      (sum, item) => sum + item.preco * (_quantities[item.id] ?? 0),
    );
    final hasItems = _quantities.isNotEmpty;
    return FilledButton.icon(
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
    );
  }

  Widget _buildOrderTracking(Order order) {
    final location = order.localizacao;
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
            if (order.pago)
              const Chip(
                avatar: Icon(Icons.check_circle, color: AppColors.positive),
                label: Text('Pago'),
              ),
            if (location != null) ...[
              const SizedBox(height: 8),
              _locationMap(location),
              if (location.descricaoLocal.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Ponto escolhido: ${location.descricaoLocal}'),
                ),
            ],
            const SizedBox(height: 8),
            const Text(
              'O status é atualizado ao tocar em atualizar. Pagamentos reais e chat não estão disponíveis nesta versão.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationMap(OrderLocation location) {
    final position = LatLng(location.latitude, location.longitude);
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
        OrderStatus.desconhecido => 'Status atualizado',
      };
}
