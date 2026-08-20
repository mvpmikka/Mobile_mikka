import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../widgets/mikka_logo.dart';
import 'onboarding/connect_chat_page.dart';
import 'onboarding/discover_places_page.dart';
import 'onboarding/friends_map_page.dart';
import 'onboarding/privacy_page.dart';
import 'onboarding/rewards_page.dart';
import 'register_screen.dart';

const _pageCount = 5;

/// A 5-page swipeable carousel shown once between the welcome screen and
/// sign-up: Discover Places, Friends Map, Rewards & Badges, Connect and
/// Chat, and Privacy Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (_currentPage == 0) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next(BuildContext context) {
    if (_currentPage == _pageCount - 1) {
      _continue(context);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: const [
                  DiscoverPlacesPage(),
                  FriendsMapPage(),
                  RewardsPage(),
                  ConnectChatPage(),
                  PrivacyPage(),
                ],
              ),
            ),
            _buildPageIndicator(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _next(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pageCount - 1
                            ? 'Get Started'
                            : 'Next →',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _continue(context),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _goBack(context),
            icon: Icon(Icons.arrow_back, color: AppColors.darkText(context)),
          ),
          Expanded(
            child: Center(
              child: const MikkaLogo(height: 24),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _pageCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _currentPage
                  ? AppColors.orange
                  : AppColors.fieldBorder(context),
            ),
          ),
      ],
    );
  }
}
