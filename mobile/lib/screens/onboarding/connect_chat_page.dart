import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/feature_row.dart';

/// Onboarding page 4 — reuses the original single-page onboarding's three
/// feature rows, translated to English to match the rest of the carousel.
class ConnectChatPage extends StatelessWidget {
  const ConnectChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const _ChatIllustration(),
          const SizedBox(height: 24),
          const Text(
            'Connect and Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay close to the people who matter, wherever they are.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
          const SizedBox(height: 28),
          const FeatureRow(
            icon: Icons.chat_bubble_outline,
            title: 'Live chats',
            description: 'Make plans with your friends in real time.',
          ),
          const SizedBox(height: 24),
          const FeatureRow(
            icon: Icons.location_on_outlined,
            title: 'Location sharing',
            description: 'Show where you are with a single tap.',
          ),
          const SizedBox(height: 24),
          const FeatureRow(
            icon: Icons.groups_outlined,
            title: 'Group meetups',
            description: 'Organize hangouts with your closest circle.',
          ),
        ],
      ),
    );
  }
}

/// A small decorative chat-bubble-over-map illustration built entirely from
/// existing Material icons/colors — no new image assets needed.
class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 36,
            bottom: 22,
            child: Icon(Icons.location_on, color: AppColors.orange, size: 22),
          ),
          const Positioned(
            right: 44,
            bottom: 30,
            child: Icon(Icons.location_on, color: AppColors.orange, size: 18),
          ),
          const Positioned(
            right: 84,
            top: 22,
            child: Icon(Icons.location_on, color: AppColors.orange, size: 16),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble, color: AppColors.orange, size: 28),
          ),
        ],
      ),
    );
  }
}
