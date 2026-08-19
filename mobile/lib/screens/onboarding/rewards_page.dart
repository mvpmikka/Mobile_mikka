import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

const _badges = [
  (icon: Icons.restaurant_outlined, label: 'Food Explorer'),
  (icon: Icons.navigation_outlined, label: 'City Navigator'),
  (icon: Icons.local_cafe_outlined, label: 'Cafe Critic'),
];

const _perks = [
  (
    icon: Icons.workspace_premium_outlined,
    title: 'Rare Badges',
    description: 'Discover new places to collect exclusive badges.',
  ),
  (
    icon: Icons.trending_up,
    title: 'Rating System',
    description: 'Increase your activity throughout the city and level up.',
  ),
  (
    icon: Icons.local_offer_outlined,
    title: 'Exclusive Offers',
    description: 'Special discounts for the most active users.',
  ),
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
          Text(
            'Earn Rewards & Badges',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore more, earn badges, and climb the leaderboard.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 24),
          Center(
            child: Image.asset('assets/icon/logo_wordmark.png', height: 32),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final badge in _badges) _BadgeAvatar(badge: badge),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/icon/app_icon.png', height: 32),
                ),
                const SizedBox(height: 16),
                for (final perk in _perks) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(perk.icon, color: AppColors.orange, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              perk.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              perk.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (perk != _perks.last) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeAvatar extends StatelessWidget {
  const _BadgeAvatar({required this.badge});

  final ({IconData icon, String label}) badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 3),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(badge.icon, color: AppColors.orange, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText(context),
            ),
          ),
        ],
      ),
    );
  }
}
