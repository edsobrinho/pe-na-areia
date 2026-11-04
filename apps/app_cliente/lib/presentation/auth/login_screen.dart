import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:core_shared/core_shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _courierMode = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = _registerMode
          ? await widget.authRepository.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim().toLowerCase(),
              phone: AppValidators.stripNonDigits(_phoneController.text),
              password: _passwordController.text,
              role: _courierMode ? 'COURIER' : 'CLIENT',
              vehicle: _courierMode ? 'PE' : null,
            )
          : await widget.authRepository.login(
              email: _emailController.text.trim().toLowerCase(),
              password: _passwordController.text,
            );
      if (!mounted) return;
      if (session.isCourier) {
        setState(() => _error = 'Esta conta é de entregador. Use o aplicativo Pé na Areia Entregador.');
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.customerHome,
        arguments: session,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Não foi possível autenticar: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(_registerMode ? 'Criar Conta' : 'Acesso'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: PeNaAreiaLogo(
                            size: 68,
                            showText: false,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ORLA DE SANTOS · ENTREGA NA AREIA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.sage700,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pé na Areia',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 22),
                        if (_registerMode) ...[
                          AppTextField(
                            controller: _nameController,
                            label: 'Nome completo',
                            hint: 'Ex: Carlos da Silva',
                            textCapitalization: TextCapitalization.words,
                            validator: AppValidators.validateFullName,
                          ),
                          AppTextField(
                            controller: _phoneController,
                            label: 'Telefone / Celular',
                            hint: '(13) 99999-9999',
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            formatters: [PhoneInputFormatter()],
                            validator: AppValidators.validatePhone,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk_rounded,
                                  color: AppColors.sage700,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sou entregador',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.ink800,
                                        ),
                                      ),
                                      Text(
                                        'Veículo: a pé na orla',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.ink500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _courierMode,
                                  activeTrackColor: AppColors.sage500,
                                  onChanged: (value) =>
                                      setState(() => _courierMode = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        AppTextField(
                          controller: _emailController,
                          label: 'E-mail',
                          hint: 'nome@dominio.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: AppValidators.validateEmail,
                        ),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          obscureText: true,
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'A senha deve ter ao menos 6 caracteres'
                                  : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.danger500),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_registerMode ? 'Criar conta' : 'Entrar'),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _registerMode = !_registerMode;
                                    _error = null;
                                  }),
                          child: Text(
                            _registerMode ? 'Já tenho conta' : 'Criar conta',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
