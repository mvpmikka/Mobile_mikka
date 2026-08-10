import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/api_exception.dart';
import '../models/friend.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import '../widgets/app_bottom_nav.dart';
import 'activity_screen.dart';
import 'filters_screen.dart';
import 'friends_screen.dart';
import 'message_thread_screen.dart';
import 'nearby_places_screen.dart';
import 'place_detail_screen.dart';
import 'profile_screen.dart';

const _tashkentCenter = LatLng(41.311081, 69.240562);

const _categories = [
  (label: 'All', icon: Icons.explore_outlined),
  (label: 'Food', icon: Icons.restaurant_outlined),
  (label: 'Cafe', icon: Icons.local_cafe_outlined),
  (label: 'Fun', icon: Icons.celebration_outlined),
  (label: 'Nature', icon: Icons.park_outlined),
  (label: 'More', icon: Icons.more_horiz),
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  int _selectedCategory = 0;
  final _selectedNavIndex = 0;
  bool _nearbyPanelVisible = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Backend has no live-location tracking for users, so a real friend's
  // actual GPS position doesn't exist anywhere — these positions are a
  // deterministic scatter around the city center, purely to place a real
  // person's marker somewhere on the map. Only the identity is real.
  Set<Marker> _markersFor(List<Friend> friends) {
    return {
      const Marker(
        markerId: MarkerId('me'),
        position: _tashkentCenter,
        icon: BitmapDescriptor.defaultMarker,
      ),
      for (var i = 0; i < friends.length; i++)
        Marker(
          markerId: MarkerId(friends[i].profile.id),
          position: LatLng(
            _tashkentCenter.latitude + (i - friends.length / 2) * 0.003,
            _tashkentCenter.longitude + (i - friends.length / 2) * 0.003,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: friends[i].profile.displayName,
            snippet: 'Chat ochish uchun bosing',
            onTap: () => _openChat(friends[i]),
          ),
          onTap: () => _openChat(friends[i]),
        ),
    };
  }

  Future<void> _openChat(Friend friend) async {
    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .openPrivateConversation(friend.profile.id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessageThreadScreen(
            conversationId: conversation.id,
            title: friend.profile.displayName,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildCategories(),
            const SizedBox(height: 12),
            Expanded(child: _buildMap()),
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

  Widget _buildHeader() {
    final avatarUrl = ref.watch(authControllerProvider).value?.user?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.orange, size: 20),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Tashkent, Uzbekistan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.darkText),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_outline,
                        color: AppColors.darkText,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: AppColors.darkText,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.mutedText, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                          _nearbyPanelVisible = true;
                        });
                      },
                      style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search places, people...',
                        hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 14),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(Icons.close, color: AppColors.mutedText, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FiltersScreen()),
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(Icons.tune, color: AppColors.darkText, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.orange : Colors.white,
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Icon(
                    category.icon,
                    color: selected ? Colors.white : AppColors.darkText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.orange : AppColors.mutedText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _tashkentCenter,
            zoom: 14.5,
          ),
          markers: _markersFor(ref.watch(friendsProvider).value ?? const []),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _RoundIconButton(
            icon: Icons.my_location,
            onTap: () {},
          ),
        ),
        if (_nearbyPanelVisible)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildNearbyPanel(),
          ),
      ],
    );
  }

  Widget _buildNearbyPanel() {
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final allPlaces = placesAsync.value ?? const <Place>[];
    final places = _searchQuery.isEmpty
        ? allPlaces
        : allPlaces
              .where(
                (place) =>
                    place.name.toLowerCase().contains(_searchQuery) ||
                    place.category.name.toLowerCase().contains(_searchQuery),
              )
              .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NearbyPlacesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    _searchQuery.isEmpty ? 'Nearby places' : 'Search results',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _nearbyPanelVisible = false),
                child: const Icon(Icons.close, color: AppColors.mutedText, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (placesAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            )
          else if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Hech narsa topilmadi',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailScreen(place: place),
                        ),
                      );
                    },
                    child: _NearbyPlaceCard(place: place),
                  );
                },
              ),
            ),
        ],
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
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ActivityScreen()),
        );
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
    }
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.darkText, size: 20),
      ),
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = place.distanceLabel;

    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 84,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              placeCategoryIcon(place.category.name),
              color: AppColors.orange,
              size: 30,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          Text(
            place.category.name,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
          if (distanceLabel != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.mutedText,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  distanceLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
