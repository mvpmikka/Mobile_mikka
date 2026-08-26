import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Shared loading spinner for admin panel screens, colored per the Figma
/// admin branding gradient's mid stop. Only used inside screens/admin.
class AdminLoadingIndicator extends StatelessWidget {
  const AdminLoadingIndicator({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    const indicator = CircularProgressIndicator(color: AppColors.adminGradientMid);
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}
