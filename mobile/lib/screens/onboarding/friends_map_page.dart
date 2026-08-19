import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/place_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/avatar_marker.dart';

const _tashkentCenter = LatLng(41.311081, 69.240562);

// Illustrative sample friends — a brand-new user has zero real friends yet,
// so friendLocationsProvider would just be empty here. These are fixed
// offsets around the default map center, not live data.
const _sampleFriends = [
  (label: 'A', offset: LatLng(0.006, 0.01), color: Color(0xFF3B82C4)),
  (label: 'S', offset: LatLng(-0.008, -0.006), color: Color(0xFF6BAE75)),
  (label: 'D', offset: LatLng(0.003, -0.012), color: Color(0xFFD9714E)),
];

/// Onboarding page 2 — a real map with a few illustrative friend markers,
/// plus a real "Enable Location Sharing" action.
class FriendsMapPage extends ConsumerStatefulWidget {
  const FriendsMapPage({super.key});

  @override
  ConsumerState<FriendsMapPage> createState() => _FriendsMapPageState();
}

class _FriendsMapPageState extends ConsumerState<FriendsMapPage> {
  Future<Set<Marker>>? _markersFuture;

  @override
  void initState() {
    super.initState();
    _markersFuture = _buildMarkers();
  }

  Future<Set<Marker>> _buildMarkers() async {
    final icons = await Future.wait([
      for (final friend in _sampleFriends)
        AvatarMarker.build(
          avatarUrl: null,
          fallbackLabel: friend.label,
          fallbackColor: friend.color,
        ),
    ]);

    return {
      for (var i = 0; i < _sampleFriends.length; i++)
        Marker(
          markerId: MarkerId('sample-friend-$i'),
          position: LatLng(
            _tashkentCenter.latitude + _sampleFriends[i].offset.latitude,
            _tashkentCenter.longitude + _sampleFriends[i].offset.longitude,
          ),
          icon: icons[i],
        ),
    };
  }

  Future<void> _enableLocationSharing() async {
    await ref.read(locationServiceProvider).getCurrentPosition();
    ref.invalidate(currentPositionProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Image.asset('assets/icon/logo_wordmark.png', height: 28),
          const SizedBox(height: 18),
          Text(
            'See where your friends are.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your location with friends and see theirs on the map in real time.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: IgnorePointer(
                child: FutureBuilder<Set<Marker>>(
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
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _enableLocationSharing,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface(context),
                foregroundColor: AppColors.darkText(context),
                side: BorderSide(color: AppColors.fieldBorder(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Enable Location Sharing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
