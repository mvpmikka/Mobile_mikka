import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'nearby_places_screen.dart';
import 'profile_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _selectedNavIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Hozircha faoliyat yo\'q',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
        onAddTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NearbyPlacesScreen()),
          );
        },
      ),
    );
  }

  void _onNavTap(int index) {
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
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
    }
  }
}
