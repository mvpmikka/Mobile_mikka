import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Primary gradient CTA button for admin panel forms/sheets, styled per the
/// Figma admin branding gradient. Only used inside screens/admin — the rest
/// of the app keeps its existing ElevatedButton/FilledButton styling.
class AdminGradientButton extends StatelessWidget {
  const AdminGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.adminBrandGradient : null,
          color: enabled ? null : AppColors.fieldBorder(context),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
