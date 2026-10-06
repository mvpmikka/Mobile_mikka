import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/short_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'conversations_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'shorts_capture_screen.dart';
import 'shorts_screen.dart';

const _shortsTabIndex = 2;

// Persistent shell for the 5 bottom-nav tabs. Each tab body lives in an
// IndexedStack under one shared Scaffold/AppBottomNav, so switching tabs
// only changes which child is visible — the other 4 stay mounted with their
// state (map camera, scroll position, search text, etc.) intact instead of
// being destroyed and rebuilt on every tap.
//
// The Figma design has no separate camera entry point on the Shorts feed
// itself — the bottom nav's middle "Create" button doubles as that entry:
// tapping it while already on the Shorts tab opens the capture screen.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _selectedIndex = widget.initialIndex;

  static const _tabs = [
    ExploreScreen(),
    FriendsScreen(),
    ShortsScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  void _onTabTap(int index) {
    if (index == _shortsTabIndex && _selectedIndex == _shortsTabIndex) {
      _openShortsCapture();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _openShortsCapture() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ShortsCaptureScreen()),
    );
    if (created == true) {
      ref.invalidate(shortFeedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
