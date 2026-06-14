import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.onFieldSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.onChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onChanged: onChanged,
      style: style ?? const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppColors.grey500),
        hintStyle: const TextStyle(color: AppColors.grey400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
