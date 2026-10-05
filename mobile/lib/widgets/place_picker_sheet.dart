import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';

/// Opens a draggable bottom sheet for picking a [Place] to tag — reuses the
/// nearby-places + search-filter pattern from SearchScreen, but pops with
/// the selected place instead of navigating to PlaceDetailScreen.
Future<Place?> showPlacePicker(BuildContext context) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PlacePickerSheet(),
  );
}

class _PlacePickerSheet extends ConsumerStatefulWidget {
  const _PlacePickerSheet();

  @override
  ConsumerState<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<_PlacePickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final allPlaces = placesAsync.value ?? const <Place>[];
    final places = _query.isEmpty
        ? allPlaces
        : allPlaces
              .where(
                (place) =>
                    place.name.toLowerCase().contains(_query) ||
                    place.category.name.toLowerCase().contains(_query),
              )
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cream(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedText(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Joyni tanlang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppColors.darkText(context)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (value) =>
                              setState(() => _query = value.trim().toLowerCase()),
                          style: TextStyle(color: AppColors.darkText(context), fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Joy qidirish...',
                            hintStyle: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: placesAsync.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.orange),
                      )
                    : places.isEmpty
                    ? Center(
                        child: Text(
                          'Hech narsa topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: places.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).pop(place),
                            child: _PlacePickerCard(place: place),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlacePickerCard extends StatelessWidget {
  const _PlacePickerCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = place.distanceLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              placeCategoryIcon(place.category.name),
              color: AppColors.orange,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 6),
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
        Text(
          place.category.name,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        if (distanceLabel != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.mutedText(context), size: 12),
              const SizedBox(width: 2),
              Text(
                distanceLabel,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
