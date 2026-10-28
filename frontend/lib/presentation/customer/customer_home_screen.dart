import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../beacon/signal_beacon_screen.dart';
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
  static const List<String> _quickClientMessages = [
    'A maré subiu, mudei alguns metros para trás',
    'Estou de guarda-sol azul levantando o sinalizador',
    'Estou próximo ao posto selecionado',
  ];

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
                        onPressed:
                            quantity == 0 ? null : () => _changeQuantity(item, -1),
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
                    avatar: Icon(Icons.check_circle, color: AppColors.positive),
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
        OrderStatus.desconhecido => 'Status atualizado',
      };
}
