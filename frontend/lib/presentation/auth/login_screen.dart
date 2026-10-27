import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/forms/formatters.dart';
import '../../core/forms/validators.dart';
import '../../data/http/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';

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
        Navigator.of(context).pushReplacementNamed(AppRoutes.courierHome);
      } else {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.customerHome,
          arguments: session,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Não foi possível autenticar: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.beach_access,
                        size: 64, color: AppColors.brandRed),
                    const SizedBox(height: 8),
                    Text(
                      'Pé na Areia',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.brandRed,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 24),
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
                        autofillHints: const [AutofillHints.telephoneNumber],
                        formatters: [PhoneInputFormatter()],
                        validator: AppValidators.validatePhone,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sou entregador'),
                        subtitle: const Text('Veículo: a pé'),
                        value: _courierMode,
                        onChanged: (value) =>
                            setState(() => _courierMode = value),
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
                      validator: (value) => value == null || value.length < 6
                          ? 'A senha deve ter ao menos 6 caracteres'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registerMode ? 'Criar conta' : 'Entrar'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _registerMode = !_registerMode;
                                _error = null;
                              }),
                      child: Text(_registerMode
                          ? 'Já tenho conta'
                          : 'Criar conta'),
                    ),
                  ],
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
