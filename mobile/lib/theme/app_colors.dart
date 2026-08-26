import 'package:flutter/material.dart';

/// Brand orange stays fixed across light/dark; every other color is
/// resolved from [Theme.of(context).brightness] via the methods below so
/// the whole app follows the device's system light/dark setting.
class AppColors {
  AppColors._();

  static const orange = Color(0xFFE97A3C);

  /// Admin panel-only brand gradient (Figma). Kept separate from [orange]
  /// so the rest of the app (login, register, user-facing screens) is
  /// untouched — only widgets under screens/admin/widgets reference these.
  static const adminGradientStart = Color(0xFFFD4404);
  static const adminGradientMid = Color(0xFFFE5B01);
  static const adminGradientAccent = Color(0xFFFD8204);
  static const adminGradientEnd = Color(0xFFFD9A04);

  static const adminBrandGradient = LinearGradient(
    colors: [adminGradientStart, adminGradientMid, adminGradientAccent, adminGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _creamLight = Color(0xFFF8F1E6);
  static const _darkTextLight = Color(0xFF231A14);
  static const _mutedTextLight = Color(0xFF8A7E72);
  static const _fieldBorderLight = Color(0xFFE5DCCB);
  static const _surfaceLight = Colors.white;

  static const _creamDark = Color(0xFF1C1712);
  static const _darkTextDark = Color(0xFFF3ECE3);
  static const _mutedTextDark = Color(0xFFB2A493);
  static const _fieldBorderDark = Color(0xFF3A332B);
  static const _surfaceDark = Color(0xFF272019);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Screen background.
  static Color cream(BuildContext context) =>
      _isDark(context) ? _creamDark : _creamLight;

  /// Primary text color.
  static Color darkText(BuildContext context) =>
      _isDark(context) ? _darkTextDark : _darkTextLight;

  /// Secondary/hint text color.
  static Color mutedText(BuildContext context) =>
      _isDark(context) ? _mutedTextDark : _mutedTextLight;

  /// Input/divider border color.
  static Color fieldBorder(BuildContext context) =>
      _isDark(context) ? _fieldBorderDark : _fieldBorderLight;

  /// Card/panel background — plain white in light mode.
  static Color surface(BuildContext context) =>
      _isDark(context) ? _surfaceDark : _surfaceLight;
}
