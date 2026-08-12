import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/api_exception.dart';
import '../models/check_in.dart';
import '../models/friend.dart';
import '../models/user_search_result.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_location_provider.dart';
import '../providers/user_search_provider.dart';
import '../theme/app_colors.dart';
import '../utils/avatar_marker.dart';
import '../widgets/app_bottom_nav.dart';
import 'activity_screen.dart';
import 'conversations_screen.dart';
import 'explore_screen.dart';
import 'message_thread_screen.dart';
import 'nearby_places_screen.dart';
import 'profile_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _mapView = false;
  final _selectedNavIndex = 1;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _debouncedQuery = '';
  Timer? _debounce;
  final _sentRequestIds = <String>{};
  String? _markersKey;
  Future<Set<Marker>>? _markersFuture;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<Friend> _filtered(List<Friend> friends) {
    if (_searchQuery.isEmpty) return friends;
    return friends
        .where(
          (friend) => friend.profile.displayName.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  Future<void> _sendFriendRequest(UserSearchResult user) async {
    try {
      await ref.read(friendshipServiceProvider).sendFriendRequest(user.id);
      if (!mounted) return;
      setState(() => _sentRequestIds.add(user.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
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
    final friendsAsync = ref.watch(friendsProvider);

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
            Expanded(
              child: _debouncedQuery.isNotEmpty
                  ? _buildSearchResults(friendsAsync.value ?? const [])
                  : friendsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.orange),
                      ),
                      error: (error, _) => const Center(
                        child: Text(
                          'Do\'stlar ro\'yxatini yuklab bo\'lmadi',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      ),
                      data: (friends) {
                        final filtered = _filtered(friends);
                        if (friends.isEmpty) {
                          return const Center(
                            child: Text(
                              'Hali do\'stlaringiz yo\'q',
                              style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                            ),
                          );
                        }
                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text(
                              'Hech kim topilmadi',
                              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                            ),
                          );
                        }
                        return _mapView ? _buildMap(filtered) : _buildList(filtered);
                      },
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConversationsScreen()),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: AppColors.fieldBorder)),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.darkText, size: 18),
            ),
          ),
          const SizedBox(width: 8),
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
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () {
                    if (!mounted) return;
                    setState(() => _debouncedQuery = _searchQuery);
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
                  _debounce?.cancel();
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _debouncedQuery = '';
                  });
                },
                child: const Icon(Icons.close, color: AppColors.mutedText, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<Friend> friends) {
    final locationsAsync = ref.watch(friendLocationsProvider);

    if (locationsAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    final locations = locationsAsync.value ?? const {};
    final relevantFriends = friends
        .where((friend) => locations[friend.profile.id] != null)
        .toList();

    if (relevantFriends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Do\'stlaringizning hozircha check-in qilingan joyi yo\'q',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
        ),
      );
    }

    final key = relevantFriends
        .map(
          (f) =>
              '${f.profile.id}:${f.profile.avatarUrl}:${locations[f.profile.id]!.place.id}',
        )
        .join(',');
    if (_markersKey != key) {
      _markersKey = key;
      _markersFuture = _buildFriendMarkers(relevantFriends, locations);
    }

    return FutureBuilder<Set<Marker>>(
      future: _markersFuture,
      builder: (context, snapshot) {
        final markers = snapshot.data;
        if (markers == null || markers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          );
        }
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: markers.first.position,
            zoom: 12,
          ),
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        );
      },
    );
  }

  // Markers use each friend's real profile photo (via AvatarMarker) instead
  // of a generic pin, matching the same approach as ExploreScreen's map.
  Future<Set<Marker>> _buildFriendMarkers(
    List<Friend> friends,
    Map<String, PublicCheckIn> locations,
  ) async {
    final markers = await Future.wait(
      friends.map((friend) async {
        final location = locations[friend.profile.id]!;
        final icon = await AvatarMarker.build(
          avatarUrl: friend.profile.avatarUrl,
          fallbackLabel: friend.profile.displayName.isNotEmpty
              ? friend.profile.displayName[0].toUpperCase()
              : '?',
          fallbackColor: const Color(0xFF3B82C4),
        );
        return Marker(
          markerId: MarkerId(friend.profile.id),
          position: LatLng(location.place.latitude, location.place.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: friend.profile.displayName,
            snippet: location.place.name,
          ),
        );
      }),
    );
    return markers.toSet();
  }

  Widget _buildSearchResults(List<Friend> friends) {
    final resultsAsync = ref.watch(userSearchProvider(_debouncedQuery));
    final friendIds = friends.map((f) => f.profile.id).toSet();

    return resultsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is ApiException
                    ? error.message
                    : 'Qidiruvni bajarib bo\'lmadi',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(userSearchProvider(_debouncedQuery)),
                child: const Text(
                  'Qayta urinish',
                  style: TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Hech kim topilmadi',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final user = results[index];
            return _SearchResultItem(
              user: user,
              isFriend: friendIds.contains(user.id),
              requestSent: _sentRequestIds.contains(user.id),
              onSendRequest: () => _sendFriendRequest(user),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<Friend> friends) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _FriendListItem(
        friend: friends[index],
        onTap: () => _openChat(friends[index]),
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

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.user,
    required this.isFriend,
    required this.requestSent,
    required this.onSendRequest,
  });

  final UserSearchResult user;
  final bool isFriend;
  final bool requestSent;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.person, color: Colors.white, size: 26),
                )
              : const Icon(Icons.person, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        if (isFriend)
          const Text(
            'Do\'stingiz',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          )
        else if (requestSent)
          const Text(
            'Yuborildi',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          )
        else
          GestureDetector(
            onTap: onSendRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Qo\'shish',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendListItem extends StatelessWidget {
  const _FriendListItem({required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = friend.profile;
    final avatarUrl = profile.avatarUrl;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person, color: Colors.white, size: 26),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                if (profile.username != null)
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chat_bubble_outline, color: AppColors.orange, size: 20),
        ],
      ),
    );
  }
}
