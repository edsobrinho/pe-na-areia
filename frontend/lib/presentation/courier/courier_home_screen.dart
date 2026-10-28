import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/routes.dart';
import '../../data/http/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/services/location_service.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../theme/app_colors.dart';
import 'beach_radar_widget.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({
    super.key,
    required this.authRepository,
    required this.orderRepository,
    required this.locationService,
  });

  final AuthRepository authRepository;
  final OrderRepository orderRepository;
  final LocationService locationService;

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  static const List<String> _quickCourierMessages = [
    'Estou descendo para a faixa de areia!',
    'Ative o Sinalizador Laranja no celular para eu te ver',
    'Estou próximo ao ponto de referência informado',
  ];

  List<Order> _available = const [];
  List<Order> _active = const [];
  bool _loading = true;
  String? _error;
  double? _courierLat;
  double? _courierLng;
  Timer? _liveTrackingTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _startPeriodicLiveTracking();
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicLiveTracking() {
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_active.isNotEmpty && !_loading) {
        _syncCourierGpsToActiveOrders(silent: true);
      }
    });
  }

  Future<void> _syncCourierGpsToActiveOrders({bool silent = false}) async {
    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _courierLat = pos.latitude;
        _courierLng = pos.longitude;
      });
      for (final order in _active) {
        if (order.status == OrderStatus.aCaminho ||
            order.status == OrderStatus.chegouNoLocal) {
          await widget.orderRepository.updateCourierLocation(
            orderId: order.id,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }
      }
      if (!silent) {
        await _refresh();
      }
    } catch (error) {
      if (!silent && mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.orderRepository.fetchAvailableOrders(),
        widget.orderRepository.fetchActiveCourierOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0];
        _active = results[1];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(Order order) async {
    await _runAction(() => widget.orderRepository.updateStatus(
          order.id,
          OrderStatus.aCaminho,
        ));
    await _syncCourierGpsToActiveOrders(silent: true);
  }

  Future<void> _markArrived(Order order) async {
    await _runAction(() => widget.orderRepository.updateStatus(
          order.id,
          OrderStatus.chegouNoLocal,
        ));
  }

  Future<void> _sendQuickMessage(Order order, String text) async {
    await _runAction(() => widget.orderRepository.sendOrderMessage(
          orderId: order.id,
          texto: text,
        ));
  }

  Future<void> _confirmDelivery(Order order) async {
    try {
      final courierId = order.courierId;
      if (courierId == null || courierId.isEmpty) {
        throw const FormatException(
          'O pedido não está associado a um entregador autenticado.',
        );
      }
      final position = await widget.locationService.getCurrentPosition();
      await _runAction(() => widget.orderRepository.confirmDelivery(
            orderId: order.id,
            courierId: courierId,
            latitude: position.latitude,
            longitude: position.longitude,
          ));
    } on LocationServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _runAction(Future<Order> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
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
          title: const Text('Entregas disponíveis'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _loading && _available.isEmpty && _active.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!),
                        ),
                      ),
                    Text('Minhas entregas',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (_active.isEmpty)
                      const ListTile(title: Text('Você não tem entregas em rota.'))
                    else
                      ..._active.map(_buildActiveOrder),
                    const SizedBox(height: 16),
                    Text('Pedidos prontos',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (_available.isEmpty)
                      const ListTile(
                          title: Text('Nenhum pedido disponível no momento.'))
                    else
                      ..._available.map(_buildAvailableOrder),
                  ],
                ),
              ),
      );

  Widget _buildAvailableOrder(Order order) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Pedido ${order.id} · R\$ ${order.valorTotal.toStringAsFixed(2)}',
                ),
                subtitle: Text(_locationSummary(order)),
                isThreeLine: true,
                trailing: FilledButton(
                  onPressed: _loading ? null : () => _accept(order),
                  child: const Text('Aceitar'),
                ),
              ),
              if (order.localizacao != null) _buildDestinationMap(order),
            ],
          ),
        ),
      );

  Widget _buildActiveOrder(Order order) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Pedido ${order.id}'),
                subtitle: Text(
                  '${_locationSummary(order)}\nStatus: ${order.status.wireValue}',
                ),
                isThreeLine: true,
                trailing: order.status == OrderStatus.aCaminho
                    ? OutlinedButton(
                        onPressed: _loading ? null : () => _markArrived(order),
                        child: const Text('Cheguei'),
                      )
                    : FilledButton(
                        onPressed:
                            _loading ? null : () => _confirmDelivery(order),
                        child: const Text('Confirmar'),
                      ),
              ),
              BeachRadarWidget(
                order: order,
                courierLatitude: _courierLat,
                courierLongitude: _courierLng,
                onUpdateGps: () => _syncCourierGpsToActiveOrders(silent: false),
              ),
              if (order.localizacao != null) _buildDestinationMap(order),
              const SizedBox(height: 10),
              _buildQuickContactSection(order),
            ],
          ),
        ),
      );

  Widget _buildQuickContactSection(Order order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avisos rápidos para o cliente na praia:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickCourierMessages
                .map(
                  (msg) => ActionChip(
                    avatar: const Icon(Icons.send, size: 14),
                    label: Text(msg, style: const TextStyle(fontSize: 11)),
                    onPressed: _loading
                        ? null
                        : () => _sendQuickMessage(order, msg),
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
                          '${m.senderRole == 'COURIER' ? 'Você' : 'Cliente'}: ${m.texto}',
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

  Widget _buildDestinationMap(Order order) {
    final location = order.localizacao!;
    final destination = LatLng(location.latitude, location.longitude);
    final cLat = _courierLat ?? order.localizacaoEntregador?.latitude;
    final cLng = _courierLng ?? order.localizacaoEntregador?.longitude;
    final courierLatLng =
        (cLat != null && cLng != null) ? LatLng(cLat, cLng) : null;

    final markers = <Marker>{
      Marker(
        markerId: MarkerId('destino-${order.id}'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: location.descricaoLocal.isEmpty
              ? 'Local de entrega'
              : location.descricaoLocal,
        ),
      ),
      if (courierLatLng != null)
        Marker(
          markerId: MarkerId('courier-${order.id}'),
          position: courierLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Sua posição na areia'),
        ),
    };

    final polylines = <Polyline>{
      if (courierLatLng != null)
        Polyline(
          polylineId: PolylineId('radar-line-${order.id}'),
          points: [courierLatLng, destination],
          color: const Color(0xFFFF7A3D),
          width: 4,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
        ),
    };

    return SizedBox(
      height: 190,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: destination, zoom: 16),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  String _locationSummary(Order order) {
    final location = order.localizacao;
    if (location == null) return 'Localização indisponível';
    final description = location.descricaoLocal.isEmpty
        ? 'Ponto de entrega'
        : location.descricaoLocal;
    return '$description\n${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }
}
