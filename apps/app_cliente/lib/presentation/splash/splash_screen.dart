import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:core_shared/core_shared.dart';

/// Tela de Apresentação / Splash do Pé na Areia inspirada na estrutura de
/// onboarding moderno (emblema superior, manchete imersiva, cartões do ecossistema
/// sustentável da orla e botão CTA em pílula larga).
///
/// Tema visual: "Entrega Sustentável na Areia da Praia de Santos".
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.onGetStarted,
    this.onLoginTap,
  });

  final VoidCallback? onGetStarted;
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF092C32), // Ocean Deep 950
              Color(0xFF0C383F), // Ocean Deep oficial
              Color(0xFF0D525A), // Ocean 800
              Color(0xFF146973), // Ocean 700
              Color(0xFF4A8B7B), // Sage Atlântico
            ],
            stops: [0.0, 0.25, 0.55, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TOPO: Emblema circular branco com o novo logotipo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: PeNaAreiaLogo(
                                    size: 34,
                                    showText: false,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.eco_rounded,
                                      color: Color(0xFF86EFAC),
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '100% Sustentável',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // 2. MANCHETE HERO (Layout com peso visual e legibilidade)
                          const Text(
                            'Entrega\nSustentável na\nAreia de Santos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Peça de quiosques e restaurantes parceiros com embalagem 100% '
                            'sustentável direto no seu guarda-sol ou canga na orla santista.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. VISUAL HERO / CARTÕES DO ECOSSISTEMA SANTISTA
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA500).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.wb_sunny_rounded,
                                    color: Color(0xFFFFA500),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'ORLA DE SANTOS',
                                    style: TextStyle(
                                      color: Color(0xFFE8D5B5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureRow(
                              icon: Icons.replay_circle_filled_rounded,
                              iconColor: const Color(0xFF86EFAC),
                              title: 'Embalagem Sustentável',
                              description:
                                  'Zero plástico na areia. Embalagens biodegradáveis e ecológicas.',
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            _buildFeatureRow(
                              icon: Icons.beach_access_rounded,
                              iconColor: const Color(0xFFFFB300),
                              title: 'Direto na sua Canga',
                              description:
                                  'Localização por posto, canal e cor do guarda-sol com sinal de alerta.',
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            _buildFeatureRow(
                              icon: Icons.pedal_bike_rounded,
                              iconColor: const Color(0xFF7DD3FC),
                              title: 'Entrega na Orla Santista',
                              description:
                                  'Entregadores a pé na areia e pela ciclovia da orla com rapidez.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 4. AÇÃO CTA INFERIOR EM PÍLULA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: () {
                              if (onGetStarted != null) {
                                onGetStarted!();
                              } else {
                                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0C383F),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Começar Agora',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                if (onLoginTap != null) {
                                  onLoginTap!();
                                } else {
                                  Navigator.of(context).pushNamed(AppRoutes.login);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withValues(alpha: 0.9),
                                textStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Já possui conta? Entrar ou Cadastrar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
