import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Shared gradient wordmark + help/profile icon top bar for the MIKKA
/// Business auth/onboarding screens (login, register, verify, dashboard...).
/// Pure UI — callbacks are optional, no navigation/backend logic baked in.
class AdminBrandTopBar extends StatelessWidget {
  const AdminBrandTopBar({
    super.key,
    required this.title,
    this.onHelp,
    this.onProfile,
    this.showIcons = true,
  });

  final String title;
  final VoidCallback? onHelp;
  final VoidCallback? onProfile;
  final bool showIcons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.adminBrandGradient.createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        if (showIcons) ...[
          _RoundIconButton(icon: Icons.help_outline, onTap: onHelp),
          const SizedBox(width: 10),
          _RoundIconButton(icon: Icons.person_outline, onTap: onProfile),
        ],
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Icon(icon, size: 20, color: AppColors.darkText(context)),
      ),
    );
  }
}
