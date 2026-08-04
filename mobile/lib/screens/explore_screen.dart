import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_summary.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'activity_screen.dart';
import 'filters_screen.dart';
import 'friends_screen.dart';
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

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedCategory = 0;
  final _selectedNavIndex = 0;
  bool _nearbyPanelVisible = true;

  static final _markers = <Marker>{
    const Marker(
      markerId: MarkerId('me'),
      position: _tashkentCenter,
      icon: BitmapDescriptor.defaultMarker,
    ),
    Marker(
      markerId: const MarkerId('friend-1'),
      position: const LatLng(41.3135, 69.2420),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    ),
    Marker(
      markerId: const MarkerId('friend-2'),
      position: const LatLng(41.3090, 69.2445),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    ),
    Marker(
      markerId: const MarkerId('place-1'),
      position: const LatLng(41.3120, 69.2385),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ),
    ),
    Marker(
      markerId: const MarkerId('place-2'),
      position: const LatLng(41.3105, 69.2470),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ),
    ),
    Marker(
      markerId: const MarkerId('place-3'),
      position: const LatLng(41.3155, 69.2455),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ),
    ),
  };

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
        onAddTap: () {},
      ),
    );
  }

  Widget _buildHeader() {
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
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.darkText,
              size: 20,
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
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.mutedText, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search places, people...',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                    ),
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
          markers: _markers,
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
                  child: const Text(
                    'Nearby places',
                    style: TextStyle(
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
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kNearbyPlaces.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final place = kNearbyPlaces[index];
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

  final PlaceSummary place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 84,
            width: double.infinity,
            decoration: BoxDecoration(
              color: place.color,
              borderRadius: BorderRadius.circular(12),
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
            place.category,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.orange, size: 12),
              const SizedBox(width: 2),
              Text(
                '${place.distance} · ${place.rating}',
                style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
