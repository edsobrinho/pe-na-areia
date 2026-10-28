import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de sinalizador visual de tela cheia (Farol) para identificação na praia.
///
/// Alterna entre cores de altíssimo contraste sob o sol (Laranja Neon, Amarelo Solar e Branco)
/// em tela cheia imersiva para que o entregador localize o cliente no meio dos guarda-sóis.
class SignalBeaconScreen extends StatefulWidget {
  const SignalBeaconScreen({
    super.key,
    this.orderId,
    this.descricaoLocal,
  });

  final String? orderId;
  final String? descricaoLocal;

  @override
  State<SignalBeaconScreen> createState() => _SignalBeaconScreenState();
}

class _SignalBeaconScreenState extends State<SignalBeaconScreen>
    with SingleTickerProviderStateMixin {
  static const _duracaoSinal = Duration(minutes: 3);
  static const _corLaranjaNeon = Color(0xFFFF7A3D);
  static const _corAmareloSolar = Color(0xFFFFD600);
  static const _corBranco = Colors.white;

  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  Duration _restante = _duracaoSinal;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarAnimacao();
    _iniciarContagem();
    _ativarTelaCheia();
  }

  void _iniciarAnimacao() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: _corLaranjaNeon, end: _corAmareloSolar),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _corAmareloSolar, end: _corBranco),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _iniciarContagem() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _restante -= const Duration(seconds: 1);
      });
      if (_restante <= Duration.zero) {
        timer.cancel();
        _encerrarSinal();
      }
    });
  }

  void _ativarTelaCheia() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _encerrarSinal() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatarRestante() {
    final minutos =
        _restante.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos =
        _restante.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        final cor = _colorAnimation.value ?? _corLaranjaNeon;
        final isDark = cor.computeLuminance() < 0.45;
        final corTexto = isDark ? Colors.white : Colors.black87;
        final corTextoSec = isDark ? Colors.white70 : Colors.black54;

        return Scaffold(
          backgroundColor: cor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.flashlight_on,
                      size: 88,
                      color: corTexto,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SINALIZADOR ATIVO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: corTexto,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Levante o celular acima da cabeça para o entregador ver você na faixa de areia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: corTexto,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.descricaoLocal != null &&
                        widget.descricaoLocal!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.descricaoLocal!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatarRestante(),
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: corTexto,
                      ),
                    ),
                    Text(
                      'O sinal se encerrará automaticamente',
                      style: TextStyle(fontSize: 13, color: corTextoSec),
                    ),
                    if (widget.orderId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pedido #${widget.orderId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: corTexto,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black26,
                        foregroundColor: corTexto,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: _encerrarSinal,
                      icon: const Icon(Icons.close),
                      label: const Text('Encerrar sinalizador'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
