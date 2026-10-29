import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PrototypeScreen extends StatefulWidget {
  const PrototypeScreen({super.key, required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  State<PrototypeScreen> createState() => _PrototypeScreenState();
}

class _PrototypeScreenState extends State<PrototypeScreen>
    with SingleTickerProviderStateMixin {
  static const _customerSteps = [
    'Quiosques',
    'Localização',
    'Checkout',
    'Acompanhamento',
    'Sinal',
  ];
  static const _courierSteps = [
    'Pedidos',
    'Rota',
    'Confirmação',
    'Chat',
  ];
  static const _menuItems = [
    _DemoMenuItem(
      name: 'Água de coco gelada',
      detail: 'Coco fresco · 300 ml',
      price: 12,
      icon: Icons.local_drink_outlined,
    ),
    _DemoMenuItem(
      name: 'Açaí da praia',
      detail: 'Açaí, banana e granola',
      price: 24,
      icon: Icons.icecream_outlined,
    ),
    _DemoMenuItem(
      name: 'Sanduíche natural',
      detail: 'Frango, folhas e pão integral',
      price: 19,
      icon: Icons.lunch_dining_outlined,
    ),
  ];

  late final TabController _tabController;
  final _messageController = TextEditingController();
  int _customerStep = 0;
  int _courierStep = 0;
  final List<int> _cartQuantities = [1, 0, 0];
  int _selectedPayment = 0;
  bool _sustainablePackage = true;
  bool _signalSent = false;
  final List<String> _chatMessages = [
    'Oi! Estou chegando ao seu ponto na praia.',
  ];

  int get _cartCount =>
      _cartQuantities.fold(0, (total, quantity) => total + quantity);

  double get _subtotal => List.generate(
        _menuItems.length,
        (index) => _menuItems[index].price * _cartQuantities[index],
      ).fold(0, (total, price) => total + price);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _openCustomerStep(int step) {
    setState(
        () => _customerStep = step.clamp(0, _customerSteps.length - 1).toInt());
    _tabController.animateTo(1);
  }

  void _openCourierStep(int step) {
    setState(
        () => _courierStep = step.clamp(0, _courierSteps.length - 1).toInt());
    _tabController.animateTo(2);
  }

  void _nextCustomerStep() => _openCustomerStep(_customerStep + 1);

  void _nextCourierStep() => _openCourierStep(_courierStep + 1);

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _chatMessages.add(message);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFlowMap(),
                  _buildCustomerExperience(),
                  _buildCourierExperience(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.ocean900,
              AppColors.ocean800,
              AppColors.ocean700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.beach_access_rounded,
                color: AppColors.mango500,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pé na Areia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'TROPICAL ATLÂNTICO · EXPERIÊNCIA PARCEIRA',
                    style: TextStyle(
                      color: AppColors.ocean100,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: widget.onLoginTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Entrar'),
            ),
          ],
        ),
      );

  Widget _buildTabs() => Material(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.ocean900,
          unselectedLabelColor: AppColors.ink500,
          indicatorColor: AppColors.mango500,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Mapa do fluxo', icon: Icon(Icons.account_tree_outlined)),
            Tab(text: 'Cliente', icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: 'Entregador', icon: Icon(Icons.delivery_dining)),
          ],
        ),
      );

  Widget _buildFlowMap() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Protótipo navegável', style: _headlineStyle),
          const SizedBox(height: 6),
          const Text(
            'Explore os caminhos principais. Toque em uma tela ou em uma seta '
            'para abrir esse ponto do app.',
            style: TextStyle(color: Color(0xFF666666), height: 1.4),
          ),
          const SizedBox(height: 18),
          _buildPartnerCard(),
          const SizedBox(height: 22),
          _buildFlowSection(
            title: 'Fluxo do cliente',
            icon: Icons.shopping_bag_outlined,
            color: AppColors.brandRed,
            steps: _customerSteps,
            onStepTap: _openCustomerStep,
          ),
          const SizedBox(height: 22),
          _buildFlowSection(
            title: 'Fluxo do entregador',
            icon: Icons.delivery_dining,
            color: AppColors.ocean700,
            steps: _courierSteps,
            onStepTap: _openCourierStep,
          ),
          const SizedBox(height: 20),
          const _PrototypeNote(),
        ],
      );

  Widget _buildPartnerCard() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCustomerStep(0),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.ocean900, AppColors.ocean700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.waves_rounded, color: AppColors.mango500, size: 34),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Um dia de praia mais leve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Peça dos quiosques e receba na areia.',
                        style: TextStyle(color: AppColors.ocean100),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFlowSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> steps,
    required ValueChanged<int> onStepTap,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: _sectionStyle),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 760;
              if (horizontal) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var index = 0; index < steps.length; index++) ...[
                      Expanded(
                        child: _FlowNode(
                          index: index,
                          title: steps[index],
                          color: color,
                          onTap: () => onStepTap(index),
                        ),
                      ),
                      if (index < steps.length - 1)
                        IconButton(
                          tooltip: 'Avançar para ${steps[index + 1]}',
                          onPressed: () => onStepTap(index + 1),
                          color: color,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    _FlowNode(
                      index: index,
                      title: steps[index],
                      color: color,
                      onTap: () => onStepTap(index),
                    ),
                    if (index < steps.length - 1)
                      IconButton(
                        tooltip: 'Avançar para ${steps[index + 1]}',
                        onPressed: () => onStepTap(index + 1),
                        color: color,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      );

  Widget _buildCustomerExperience() => _buildExperiencePage(
        steps: _customerSteps,
        activeStep: _customerStep,
        onStepTap: _openCustomerStep,
        child: _buildCustomerStep(),
      );

  Widget _buildCourierExperience() => _buildExperiencePage(
        steps: _courierSteps,
        activeStep: _courierStep,
        onStepTap: _openCourierStep,
        child: _buildCourierStep(),
      );

  Widget _buildExperiencePage({
    required List<String> steps,
    required int activeStep,
    required ValueChanged<int> onStepTap,
    required Widget child,
  }) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < steps.length; index++)
                ChoiceChip(
                  label: Text(steps[index]),
                  selected: activeStep == index,
                  selectedColor: AppColors.brandRed.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: activeStep == index
                        ? AppColors.brandRed
                        : const Color(0xFF555555),
                    fontWeight:
                        activeStep == index ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => onStepTap(index),
                  side: BorderSide(
                    color: activeStep == index
                        ? AppColors.brandRed
                        : const Color(0xFFE5E5E5),
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(activeStep),
              child: child,
            ),
          ),
          const SizedBox(height: 16),
          const _PrototypeNote(),
        ],
      );

  Widget _buildCustomerStep() {
    switch (_customerStep) {
      case 0:
        return _buildKioskScreen();
      case 1:
        return _buildLocationScreen();
      case 2:
        return _buildCheckoutScreen();
      case 3:
        return _buildTrackingScreen();
      case 4:
        return _buildSignalScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildKioskScreen() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('SANTOS · PRAIA DO GONZAGA'),
          const SizedBox(height: 6),
          Text('Olá, praia!', style: _headlineStyle),
          const SizedBox(height: 6),
          const Text(
            'Seu quiosque favorito, com entrega pertinho de você.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFFFF0E8),
                      child: Icon(
                        Icons.beach_access,
                        color: AppColors.brandRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quiosque Maré Boa',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Areia limpa · 15–25 min',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: 'Aberto',
                      color: AppColors.positive,
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ...List.generate(_menuItems.length, _buildMenuItem),
                const SizedBox(height: 14),
                _primaryButton(
                  label:
                      'Continuar · $_cartCount ${_cartCount == 1 ? 'item' : 'itens'} · ${_formatPrice(_subtotal)}',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _nextCustomerStep,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildMenuItem(int index) {
    final item = _menuItems[index];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.brandRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _cartQuantities[index]++),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandRed,
              side: const BorderSide(color: AppColors.brandRed),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationScreen() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('ENTREGA NA AREIA'),
          const SizedBox(height: 6),
          Text('Onde você está?', style: _headlineStyle),
          const SizedBox(height: 6),
          const Text(
            'Mova o pin para marcar o ponto de encontro.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          const _DemoMapCard(
            label: 'Seu ponto de encontro',
            detail: 'Próximo ao Posto 5 · Gonzaga',
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: const Row(
              children: [
                Icon(Icons.place_outlined, color: AppColors.brandRed),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Posto de salvamento 5 · Av. Presidente Wilson',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.positive),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            label: 'Confirmar localização',
            icon: Icons.location_on_outlined,
            onPressed: _nextCustomerStep,
          ),
        ],
      );

  Widget _buildCheckoutScreen() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('REVISÃO DO PEDIDO'),
          const SizedBox(height: 6),
          Text('Quase lá!', style: _headlineStyle),
          const SizedBox(height: 16),
          _sectionCard(
            child: Column(
              children: [
                for (var index = 0; index < _menuItems.length; index++)
                  if (_cartQuantities[index] > 0) ...[
                    if (index > 0) const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_cartQuantities[index]} × ${_menuItems[index].name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _formatPrice(
                            _menuItems[index].price * _cartQuantities[index],
                          ),
                        ),
                      ],
                    ),
                  ],
                const Divider(height: 28),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Embalagem sustentável'),
                  subtitle: const Text('Menos plástico na sua entrega'),
                  activeTrackColor: AppColors.positive,
                  value: _sustainablePackage,
                  onChanged: (value) =>
                      setState(() => _sustainablePackage = value),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Expanded(child: Text('Total do pedido')),
                    Text(
                      _formatPrice(_subtotal),
                      style: const TextStyle(
                        color: AppColors.brandRed,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forma de pagamento',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _paymentChip('Pix', 0, Icons.pix),
                    _paymentChip('Cartão', 1, Icons.credit_card_outlined),
                    _paymentChip('Vale-refeição', 2, Icons.receipt_long),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: 'Confirmar pedido · Pago',
            icon: Icons.lock_outline,
            onPressed: _nextCustomerStep,
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pagamento e pedido ilustrativos neste protótipo.',
              style: TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
          ),
        ],
      );

  Widget _paymentChip(String label, int index, IconData icon) => ChoiceChip(
        avatar: Icon(
          icon,
          size: 17,
          color: _selectedPayment == index ? AppColors.brandRed : null,
        ),
        label: Text(label),
        selected: _selectedPayment == index,
        selectedColor: AppColors.brandRed.withValues(alpha: 0.1),
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedPayment = index),
      );

  Widget _buildTrackingScreen() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PEDIDO #PA-2048'),
          const SizedBox(height: 6),
          Text('Seu pedido está a caminho', style: _headlineStyle),
          const SizedBox(height: 14),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.positive),
                    SizedBox(width: 8),
                    Text(
                      'Pagamento aprovado',
                      style: TextStyle(
                        color: AppColors.positive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _timelineItem('Pedido confirmado', complete: true),
                _timelineItem('Quiosque preparando', complete: true),
                _timelineItem(
                  'Entregador a caminho',
                  complete: false,
                  current: true,
                ),
                _timelineItem('Chegada na areia', complete: false, last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _DemoMapCard(
            label: 'Entregador a caminho',
            detail: 'Ponto de encontro · Posto 5',
            showCourier: true,
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: 'Preciso de ajuda · Sinal',
            icon: Icons.sos_outlined,
            onPressed: _nextCustomerStep,
          ),
        ],
      );

  Widget _timelineItem(
    String title, {
    required bool complete,
    bool current = false,
    bool last = false,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  complete
                      ? Icons.check_circle
                      : current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  size: 20,
                  color: complete || current
                      ? AppColors.positive
                      : const Color(0xFFBDBDBD),
                ),
                if (!last)
                  Container(
                    width: 2,
                    height: 22,
                    color: complete
                        ? AppColors.positive.withValues(alpha: 0.45)
                        : const Color(0xFFE5E5E5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              title,
              style: TextStyle(
                color: complete || current
                    ? const Color(0xFF252525)
                    : const Color(0xFF888888),
                fontWeight:
                    complete || current ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      );

  Widget _buildSignalScreen() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('SEGURANÇA NA PRAIA'),
          const SizedBox(height: 6),
          Text('Precisa de ajuda?', style: _headlineStyle),
          const SizedBox(height: 8),
          const Text(
            'Avise a equipe de apoio sobre seu ponto de encontro. Em uma '
            'emergência, procure o posto de salvamento mais próximo.',
            style: TextStyle(color: Color(0xFF666666), height: 1.45),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            child: Column(
              children: [
                Icon(
                  _signalSent ? Icons.check_circle : Icons.support_agent,
                  size: 52,
                  color: _signalSent ? AppColors.positive : AppColors.brandRed,
                ),
                const SizedBox(height: 10),
                Text(
                  _signalSent ? 'Sinal enviado' : 'Equipe de apoio disponível',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _signalSent
                      ? 'A equipe recebeu seu pedido de contato.'
                      : 'Ponto informado: Posto 5 · Gonzaga',
                  style: const TextStyle(color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: _signalSent ? 'Sinal enviado' : 'Enviar sinal à equipe',
            icon: _signalSent ? Icons.check : Icons.sos_outlined,
            onPressed:
                _signalSent ? null : () => setState(() => _signalSent = true),
            positive: _signalSent,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openCustomerStep(3),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar ao acompanhamento'),
          ),
        ],
      );

  Widget _buildCourierStep() {
    switch (_courierStep) {
      case 0:
        return _buildAvailableOrders();
      case 1:
        return _buildCourierRoute();
      case 2:
        return _buildDeliveryConfirmation();
      case 3:
        return _buildCourierChat();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAvailableOrders() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('ENTREGADOR · SANTOS'),
          const SizedBox(height: 6),
          Text('Pedidos disponíveis', style: _headlineStyle),
          const SizedBox(height: 6),
          const Text(
            'Escolha uma entrega e leve o pedido até a areia.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pedido #PA-2048',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(
                      label: 'Pronto',
                      color: AppColors.positive,
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: 'Quiosque Maré Boa',
                ),
                const SizedBox(height: 8),
                const _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Posto 5 · Praia do Gonzaga',
                ),
                const SizedBox(height: 8),
                const _InfoRow(
                  icon: Icons.route_outlined,
                  label: '0,8 km · aproximadamente 12 min',
                ),
                const Divider(height: 26),
                _primaryButton(
                  label: 'Aceitar pedido',
                  icon: Icons.delivery_dining,
                  onPressed: _nextCourierStep,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCourierRoute() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PEDIDO #PA-2048 · EM ROTA'),
          const SizedBox(height: 6),
          Text('Siga até o destino', style: _headlineStyle),
          const SizedBox(height: 14),
          const _DemoMapCard(
            label: 'Destino · Posto 5',
            detail: 'Praia do Gonzaga · 0,8 km',
            showCourier: true,
            showDestination: true,
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: const Column(
              children: [
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: 'Retirada concluída · Quiosque Maré Boa',
                ),
                SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Cliente · ponto próximo ao Posto 5',
                ),
                SizedBox(height: 12),
                _StatusPill(
                  label: 'Destino marcado no mapa',
                  color: Color(0xFFB88100),
                  icon: Icons.flag_outlined,
                  background: Color(0xFFFFF5D8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: 'Cheguei ao local',
            icon: Icons.place_outlined,
            onPressed: _nextCourierStep,
          ),
        ],
      );

  Widget _buildDeliveryConfirmation() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PEDIDO #PA-2048 · ENTREGA'),
          const SizedBox(height: 6),
          Text('Confirme a entrega', style: _headlineStyle),
          const SizedBox(height: 14),
          const _DemoMapCard(
            label: 'Você está no ponto de encontro',
            detail: 'Posto 5 · Praia do Gonzaga',
            showCourier: true,
            showDestination: true,
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: const Column(
              children: [
                _StatusPill(
                  label: 'Dentro do raio permitido',
                  color: AppColors.positive,
                  icon: Icons.gps_fixed,
                  background: Color(0xFFE9F8F0),
                ),
                SizedBox(height: 10),
                Text(
                  'Localização verificada para confirmar o pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: 'Confirmar entrega',
            icon: Icons.check_circle_outline,
            onPressed: _nextCourierStep,
            positive: true,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openCourierStep(3),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Conversar com o cliente'),
          ),
        ],
      );

  Widget _buildCourierChat() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PEDIDO #PA-2048'),
          const SizedBox(height: 6),
          Text('Conversa com o cliente', style: _headlineStyle),
          const SizedBox(height: 14),
          _sectionCard(
            child: Column(
              children: [
                for (var index = 0; index < _chatMessages.length; index++)
                  Align(
                    alignment: index.isEven
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? AppColors.background
                            : AppColors.brandRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_chatMessages[index]),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Escreva uma mensagem',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar mensagem',
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: 'Voltar aos pedidos',
            icon: Icons.arrow_back,
            onPressed: () => _openCourierStep(0),
          ),
        ],
      );

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFECECEC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: child,
      );

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool positive = false,
  }) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: positive ? AppColors.positive : AppColors.brandRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          icon: Icon(icon),
          label: Text(label, textAlign: TextAlign.center),
        ),
      );

  String _formatPrice(double price) =>
      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

  TextStyle get _headlineStyle => const TextStyle(
        color: AppColors.ocean900,
        fontSize: 23,
        fontWeight: FontWeight.w800,
      );

  TextStyle get _sectionStyle => const TextStyle(
        color: AppColors.ocean900,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      );
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.index,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final int index;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Toque para abrir',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, color: color, size: 18),
              ],
            ),
          ),
        ),
      );
}

class _DemoMapCard extends StatelessWidget {
  const _DemoMapCard({
    required this.label,
    required this.detail,
    this.showCourier = false,
    this.showDestination = false,
  });

  final String label;
  final String detail;
  final bool showCourier;
  final bool showDestination;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _BeachMapPainter()),
              Positioned(
                left: 14,
                top: 14,
                child: _MapMarker(
                  icon: Icons.place,
                  color: AppColors.brandRed,
                  label: 'Posto 5',
                ),
              ),
              if (showCourier)
                const Positioned(
                  left: 98,
                  top: 104,
                  child: _MapMarker(
                    icon: Icons.delivery_dining,
                    color: AppColors.ocean700,
                    label: 'Entregador',
                  ),
                ),
              if (showDestination)
                const Positioned(
                  right: 18,
                  top: 46,
                  child: _MapMarker(
                    icon: Icons.flag_rounded,
                    color: Color(0xFFB88100),
                    label: 'Destino',
                    background: AppColors.destination,
                  ),
                ),
              if (!showDestination)
                const Positioned(
                  right: 42,
                  top: 65,
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: AppColors.brandRed,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BeachMapPainter extends CustomPainter {
  const _BeachMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFE8F4F6));

    final beach = Path()
      ..moveTo(size.width * 0.58, 0)
      ..quadraticBezierTo(
        size.width * 0.39,
        size.height * 0.4,
        size.width * 0.56,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(beach, Paint()..color = const Color(0xFFF7E8C9));

    final sandEdge = Path()
      ..moveTo(size.width * 0.62, 0)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.44,
        size.width * 0.62,
        size.height,
      );
    canvas.drawPath(
      sandEdge,
      Paint()
        ..color = const Color(0xFF80C9D2)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke,
    );

    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12;
    for (var index = 1; index <= 3; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width * 0.62, y),
          streetPaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, 0),
      Offset(size.width * 0.43, size.height),
      streetPaint,
    );

    final destinationDot = Paint()..color = const Color(0xFFFFC928);
    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.28),
      10,
      destinationDot,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
    this.background = Colors.white,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x16000000), blurRadius: 5),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
    this.background,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.brandRed, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
        ],
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.ocean700,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      );
}

class _PrototypeNote extends StatelessWidget {
  const _PrototypeNote();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Color(0xFF9A6B00), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Protótipo visual com dados de exemplo. Entre no app para '
                'acessar os fluxos conectados à API.',
                style: TextStyle(
                  color: Color(0xFF644B11),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _DemoMenuItem {
  const _DemoMenuItem({
    required this.name,
    required this.detail,
    required this.price,
    required this.icon,
  });

  final String name;
  final String detail;
  final double price;
  final IconData icon;
}
