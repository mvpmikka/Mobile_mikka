import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Shared rounded text field for admin panel forms/sheets, styled per the
/// Figma admin branding. Only used inside screens/admin.
class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.label,
    this.controller,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.fieldBorder(context)),
    );
    return TextFormField(
      controller: controller,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.darkText(context)),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface(context),
        border: border,
        enabledBorder: border,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.adminGradientMid, width: 1.5),
        ),
      ),
      validator: validator ??
          (required
              ? (value) =>
                  (value == null || value.trim().isEmpty) ? 'Majburiy maydon' : null
              : null),
    );
  }
}
