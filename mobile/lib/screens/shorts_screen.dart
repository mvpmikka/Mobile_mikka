import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'conversations_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

// Placeholder tab reserved for a future short-video feature — the bottom
// nav's five slots (Map/Friends/Shorts/Chat/Profile) match the Figma
// mockup, but Shorts itself has no backend or content model yet.
class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  static const _selectedNavIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 56,
                  color: AppColors.mutedText(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shorts tez orada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qisqa videolar xususiyati ustida ishlanmoqda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
        );
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
        );
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConversationsScreen()),
        );
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
    }
  }
}
