import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto acessível padronizado com suporte a máscaras, semântica e área de toque mínima de 48dp.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.formatters,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.focusNode,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Semantics(
        label: label,
        hint: hint,
        textField: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            inputFormatters: formatters,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            textCapitalization: textCapitalization,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

