import 'package:flutter/cupertino.dart';

class CustomCupertinoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final EdgeInsetsGeometry padding;
  
  const CustomCupertinoTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(12),
  });
  
  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: padding,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      style: const TextStyle(color: CupertinoColors.label),
      placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
    );
  }
} 