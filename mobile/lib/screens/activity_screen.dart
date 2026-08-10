import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'nearby_places_screen.dart';
import 'profile_screen.dart';

class _ActivityItem {
  const _ActivityItem({
    required this.name,
    required this.action,
    required this.place,
    required this.timeAgo,
    required this.avatarColor,
    required this.thumbColor,
  });

  final String name;
  final String action;
  final String place;
  final String timeAgo;
  final Color avatarColor;
  final Color thumbColor;
}

const _activities = [
  _ActivityItem(
    name: 'Aziza Karimova',
    action: 'checked in at',
    place: 'Coffee 21',
    timeAgo: '5m ago',
    avatarColor: Color(0xFFCB4B4B),
    thumbColor: Color(0xFF6B4A38),
  ),
  _ActivityItem(
    name: 'Dilnoza Rashidova',
    action: 'checked in at',
    place: 'Central Park',
    timeAgo: '32m ago',
    avatarColor: Color(0xFF3E6B5C),
    thumbColor: Color(0xFF3E6B5C),
  ),
  _ActivityItem(
    name: 'Bekzod Yusupov',
    action: 'saved',
    place: 'Art Gallery',
    timeAgo: '1h ago',
    avatarColor: Color(0xFF4A5A8A),
    thumbColor: Color(0xFF4A5A8A),
  ),
  _ActivityItem(
    name: 'Farrux Toshev',
    action: 'checked in at',
    place: 'Sakura Sushi',
    timeAgo: '3h ago',
    avatarColor: Color(0xFF4F8A5C),
    thumbColor: Color(0xFFCB4B4B),
  ),
];

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
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: _activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _ActivityRow(item: _activities[index]),
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: item.avatarColor, shape: BoxShape.circle),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: AppColors.darkText),
                  children: [
                    TextSpan(
                      text: item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' ${item.action} '),
                    TextSpan(
                      text: item.place,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.timeAgo,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.thumbColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
