import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
