import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

const _badges = [
  (icon: Icons.emoji_events_outlined, label: 'Explorer'),
  (icon: Icons.local_fire_department_outlined, label: 'Streaks'),
  (icon: Icons.star_outline, label: 'Top Rated'),
  (icon: Icons.military_tech_outlined, label: 'Legend'),
];

const _perks = [
  'Check in at new places',
  'Complete weekly challenges',
  'Unlock exclusive badges',
];

/// Onboarding page 3 — purely decorative, no real data needed.
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Earn Rewards & Badges',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore more, earn badges, and climb the leaderboard.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 16,
            children: [
              for (final badge in _badges)
                SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(badge.icon, color: AppColors.orange, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          for (final perk in _perks) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.orange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    perk,
                    style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
