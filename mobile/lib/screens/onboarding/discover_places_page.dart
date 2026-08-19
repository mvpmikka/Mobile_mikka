import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/place_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/place_card.dart';

const _tashkentCenter = LatLng(41.311081, 69.240562);

/// Onboarding page 1 — shows a real map and, once location is available,
/// real nearby places (no fake/sample data, matching PlaceCard's no-photo
/// category-icon style used elsewhere in the app).
class DiscoverPlacesPage extends ConsumerWidget {
  const DiscoverPlacesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final places = placesAsync.value ?? const [];
    final markers = places
        .map(
          (place) => Marker(
            markerId: MarkerId(place.id),
            position: LatLng(place.latitude, place.longitude),
          ),
        )
        .toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Discover Places',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find great spots to eat, hang out, and explore nearby.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 200,
              child: IgnorePointer(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _tashkentCenter,
                    zoom: 14.5,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildPlacesSection(context, placesAsync, places),
        ],
      ),
    );
  }

  Widget _buildPlacesSection(
    BuildContext context,
    AsyncValue<List<dynamic>> placesAsync,
    List places,
  ) {
    if (placesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    final error = placesAsync.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          error is LocationUnavailableException
              ? 'Enable location to discover places near you.'
              : "Couldn't load nearby places.",
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
        ),
      );
    }

    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No places found nearby yet.',
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => PlaceCard(place: places[index]),
      ),
    );
  }
}
