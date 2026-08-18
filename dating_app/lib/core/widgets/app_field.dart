import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final bool secureTextEntry;
  final TextInputType? keyboardType;
  final bool multiline;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;

  const AppField({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.placeholder,
    this.secureTextEntry = false,
    this.keyboardType,
    this.multiline = false,
    this.controller,
    this.validator,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 7.0),
        TextFormField(
          initialValue: controller == null ? value : null,
          controller: controller,
          onChanged: onChanged,
          obscureText: secureTextEntry,
          keyboardType: keyboardType,
          maxLines: secureTextEntry ? 1 : (multiline ? 4 : 1),
          minLines: secureTextEntry ? 1 : (multiline ? 4 : 1),
          validator: validator,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15.0,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            errorText: errorText,
            hintStyle: const TextStyle(
              color: AppColors.muted,
              fontSize: 15.0,
            ),
            fillColor: AppColors.surface,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 13.0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
