import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'conversations_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'shorts_screen.dart';

// Persistent shell for the 5 bottom-nav tabs. Each tab body lives in an
// IndexedStack under one shared Scaffold/AppBottomNav, so switching tabs
// only changes which child is visible — the other 4 stay mounted with their
// state (map camera, scroll position, search text, etc.) intact instead of
// being destroyed and rebuilt on every tap.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _selectedIndex = widget.initialIndex;

  static const _tabs = [
    ExploreScreen(),
    FriendsScreen(),
    ShortsScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
