import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CreateChoice { photo, video }

/// Bottom sheet asking whether the user wants to create a photo post or a
/// Shorts video — shown when the bottom nav's "Create" slot is tapped, since
/// the camera screen itself only knows how to record video (hold-to-record)
/// and gave no way to tell which mode was active.
Future<CreateChoice?> showCreateChoiceSheet(BuildContext context) {
  return showModalBottomSheet<CreateChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateChoiceSheet(),
  );
}

class _CreateChoiceSheet extends StatelessWidget {
  const _CreateChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.mutedText(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ChoiceTile(
              icon: Icons.image_outlined,
              title: 'Rasm',
              subtitle: 'Galereyadan rasm tanlab, post qiling',
              onTap: () => Navigator.of(context).pop(CreateChoice.photo),
            ),
            Divider(height: 1, color: AppColors.fieldBorder(context)),
            _ChoiceTile(
              icon: Icons.videocam_outlined,
              title: 'Video',
              subtitle: 'Qisqa video yozib oling (Shorts)',
              onTap: () => Navigator.of(context).pop(CreateChoice.video),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.orange, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.darkText(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
      ),
    );
  }
}
