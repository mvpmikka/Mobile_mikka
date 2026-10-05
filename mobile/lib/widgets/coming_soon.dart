import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared stub for v1 features that have UI but no backend yet (Add Music,
/// Effects, comment, bookmark, share on Shorts).
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tez kunda'),
      backgroundColor: AppColors.orange,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
