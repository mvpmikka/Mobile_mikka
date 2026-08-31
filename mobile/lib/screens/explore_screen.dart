import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/api_exception.dart';
import '../models/check_in.dart';
import '../models/friend.dart';
import '../models/place.dart';
import '../models/place_filters.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_location_provider.dart';
import '../providers/place_provider.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import '../utils/avatar_marker.dart';
import '../utils/place_marker.dart';
import 'activity_screen.dart';
import 'filters_screen.dart';
import 'message_thread_screen.dart';
import 'nearby_places_screen.dart';
import 'place_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

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
  bool _nearbyPanelVisible = true;
  PlaceFilters _filters = const PlaceFilters();

  String? _markersKey;
  Future<Set<Marker>>? _markersFuture;

  // Friends without a visible check-in are simply left off the map, rather
  // than given a fake position — same rule as FriendsScreen's map. Friend
  // markers use each person's actual profile photo (AvatarMarker); place
  // markers use a category icon (PlaceMarker, e.g. fork/knife for
  // restaurants) instead of the default red Google pin. Both are async
  // (image work / canvas drawing), so they're cached together per
  // (friends, locations, myPosition, avatar, places) combination below so
  // rebuilds triggered by unrelated state don't redo the drawing work.
  Future<Set<Marker>> _markersFor(
    List<Friend> friends,
    Map<String, PublicCheckIn> locations,
    Position? myPosition,
    String? myAvatarUrl,
    List<Place> places,
  ) async {
    final relevantFriends = friends
        .where((friend) => locations[friend.profile.id] != null)
        .toList();

    final results = await Future.wait([
      if (myPosition != null)
        AvatarMarker.build(
              avatarUrl: myAvatarUrl,
              fallbackLabel: 'Men',
              fallbackColor: AppColors.orange,
            )
            .then(
              (icon) => Marker(
                markerId: const MarkerId('me'),
                position: LatLng(myPosition.latitude, myPosition.longitude),
                icon: icon,
              ),
            ),
      for (final friend in relevantFriends)
        AvatarMarker.build(
              avatarUrl: friend.profile.avatarUrl,
              fallbackLabel: friend.profile.displayName.isNotEmpty
                  ? friend.profile.displayName[0].toUpperCase()
                  : '?',
              fallbackColor: const Color(0xFF3B82C4),
            )
            .then(
              (icon) => Marker(
                markerId: MarkerId(friend.profile.id),
                position: LatLng(
                  locations[friend.profile.id]!.place.latitude,
                  locations[friend.profile.id]!.place.longitude,
                ),
                icon: icon,
                infoWindow: InfoWindow(
                  title: friend.profile.displayName,
                  snippet: locations[friend.profile.id]!.place.name,
                  onTap: () => _openChat(friend),
                ),
                onTap: () => _openChat(friend),
              ),
            ),
      for (final place in places)
        PlaceMarker.build(icon: placeCategoryIcon(place.category.name))
            .then(
              (icon) => Marker(
                markerId: MarkerId('place-${place.id}'),
                position: LatLng(place.latitude, place.longitude),
                icon: icon,
                anchor: const Offset(0.5, 1),
                infoWindow: InfoWindow(
                  title: place.name,
                  snippet: place.category.name,
                  onTap: () => _openPlace(place),
                ),
                onTap: () => _openPlace(place),
              ),
            ),
    ]);

    return results.toSet();
  }

  void _openPlace(Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
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
            otherUserId: friend.profile.id,
            otherAvatarUrl: friend.profile.avatarUrl,
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

  Future<void> _openFilters() async {
    final result = await FiltersScreen.show(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
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
          Expanded(
            child: Text(
              'Tashkent, Uzbekistan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText(context),
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppColors.darkText(context)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
              );
            },
            child: Icon(
              Icons.notifications_none,
              color: AppColors.darkText(context),
              size: 22,
            ),
          ),
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
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_outline,
                        color: AppColors.darkText(context),
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: AppColors.darkText(context),
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
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fieldBorder(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.mutedText(context), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search places, people...',
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFilters,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Icon(Icons.tune, color: AppColors.darkText(context), size: 20),
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
                    color: selected ? AppColors.orange : AppColors.surface(context),
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.fieldBorder(context)),
                  ),
                  child: Icon(
                    category.icon,
                    color: selected ? Colors.white : AppColors.darkText(context),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.orange : AppColors.mutedText(context),
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
    final friends = ref.watch(friendsProvider).value ?? const [];
    final locations = ref.watch(friendLocationsProvider).value ?? const {};
    final myPosition = ref.watch(currentPositionProvider).value;
    final myAvatarUrl = ref.watch(authControllerProvider).value?.user?.avatarUrl;
    final allPlaces = ref.watch(nearbyPlacesProvider).value ?? const <Place>[];
    final filteredPlaces = _filters.apply(allPlaces);

    final key =
        '${myPosition?.latitude},${myPosition?.longitude}|$myAvatarUrl|'
        '${friends.map((f) => '${f.profile.id}:${f.profile.avatarUrl}:${locations[f.profile.id]?.place.id}').join(',')}|'
        '${filteredPlaces.map((p) => '${p.id}:${p.category.name}').join(',')}';
    if (_markersKey != key) {
      _markersKey = key;
      _markersFuture = _markersFor(
        friends,
        locations,
        myPosition,
        myAvatarUrl,
        filteredPlaces,
      );
    }

    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _markersFuture,
          builder: (context, snapshot) {
            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _tashkentCenter,
                zoom: 14.5,
              ),
              markers: snapshot.data ?? const <Marker>{},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            );
          },
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
            child: _buildNearbyPanel(filteredPlaces),
          ),
      ],
    );
  }

  Widget _buildNearbyPanel(List<Place> places) {
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final locationError = placesAsync.error;

    // Bottom margin + shadow make this read as a card floating over the
    // map, distinct from AppBottomNav below — without them, both use the
    // same surface color and sit flush against each other, blending into
    // one block.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                    'Nearby places',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText(context),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _nearbyPanelVisible = false),
                child: Icon(Icons.close, color: AppColors.mutedText(context), size: 20),
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
          else if (locationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locationError is LocationUnavailableException
                        ? 'Joylashuvingiz aniqlanmadi. GPS yoqilganini va ilovaga joylashuv ruxsati berilganini tekshiring.'
                        : 'Joylarni yuklab bo\'lmadi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(currentPositionProvider),
                    child: const Text('Qayta urinish', style: TextStyle(color: AppColors.orange)),
                  ),
                ],
              ),
            )
          else if (places.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Hech narsa topilmadi',
                style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return GestureDetector(
                    onTap: () => _openPlace(place),
                    child: _NearbyPlaceCard(place: place),
                  );
                },
              ),
            ),
        ],
      ),
    );
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
          color: AppColors.surface(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.darkText(context), size: 20),
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
    final rating = place.rating;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              placeCategoryIcon(place.category.name),
              color: AppColors.orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  distanceLabel != null
                      ? '${place.category.name} · $distanceLabel'
                      : place.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.orange, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.reviewCount > 0
                          ? rating.averageRating.toStringAsFixed(1)
                          : 'Yangi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
