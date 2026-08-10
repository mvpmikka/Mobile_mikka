import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'activity_screen.dart';
import 'explore_screen.dart';
import 'nearby_places_screen.dart';
import 'profile_screen.dart';

const _tashkentCenter = LatLng(41.311081, 69.240562);

class _Friend {
  const _Friend({
    required this.name,
    required this.status,
    required this.distance,
    required this.color,
    this.online = false,
  });

  final String name;
  final String status;
  final String distance;
  final Color color;
  final bool online;
}

const _friends = [
  _Friend(
    name: 'Aziza Karimova',
    status: 'At Coffee 21',
    distance: '300 m',
    color: Color(0xFFCB4B4B),
    online: true,
  ),
  _Friend(
    name: 'Bekzod Yusupov',
    status: 'Last seen 2h ago',
    distance: '1.2 km',
    color: Color(0xFF4A5A8A),
  ),
  _Friend(
    name: 'Dilnoza Rashidova',
    status: 'At Central Park',
    distance: '900 m',
    color: Color(0xFF3E6B5C),
    online: true,
  ),
  _Friend(
    name: 'Farrux Toshev',
    status: 'Last seen yesterday',
    distance: '4.5 km',
    color: Color(0xFF4F8A5C),
  ),
];

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _mapView = true;
  final _selectedNavIndex = 1;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends
        .where((friend) => friend.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  static final _markers = <Marker>{
    for (var i = 0; i < _friends.length; i++)
      Marker(
        markerId: MarkerId('friend-$i'),
        position: LatLng(
          _tashkentCenter.latitude + (i - 1.5) * 0.003,
          _tashkentCenter.longitude + (i - 1.5) * 0.003,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
            const SizedBox(height: 12),
            Expanded(child: _mapView ? _buildMap() : _buildList()),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Friends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
          _ToggleIconButton(
            icon: Icons.map_outlined,
            selected: _mapView,
            onTap: () => setState(() => _mapView = true),
          ),
          const SizedBox(width: 8),
          _ToggleIconButton(
            icon: Icons.list,
            selected: !_mapView,
            onTap: () => setState(() => _mapView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    _mapView = false;
                  });
                },
                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search friends...',
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
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _tashkentCenter,
        zoom: 14.5,
      ),
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildList() {
    final friends = _filteredFriends;
    if (friends.isEmpty) {
      return const Center(
        child: Text(
          'Hech kim topilmadi',
          style: TextStyle(color: AppColors.mutedText, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _FriendListItem(friend: friends[index]),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
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

class _ToggleIconButton extends StatelessWidget {
  const _ToggleIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.white,
          shape: BoxShape.circle,
          border: selected ? null : Border.all(color: AppColors.fieldBorder),
        ),
        child: Icon(
          icon,
          color: selected ? Colors.white : AppColors.darkText,
          size: 18,
        ),
      ),
    );
  }
}

class _FriendListItem extends StatelessWidget {
  const _FriendListItem({required this.friend});

  final _Friend friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: friend.color, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 26),
            ),
            if (friend.online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8A5C),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cream, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                friend.status,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        Text(
          friend.distance,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
      ],
    );
  }
}
