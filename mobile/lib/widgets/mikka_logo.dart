import 'package:flutter/material.dart';

/// The Mikka wordmark logo, as a self-contained card image. The card has
/// its own background, so the variant shown is swapped by theme brightness
/// to stay visible: the white-card image in dark mode, the dark-card image
/// in light mode.
class MikkaLogo extends StatelessWidget {
  const MikkaLogo({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/icon/logo_wordmark_on_white.jpg'
        : 'assets/icon/logo_wordmark_on_dark.jpg';
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.2),
      child: Image.asset(asset, height: height),
    );
  }
}
