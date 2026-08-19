import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/place_category_icon.dart';

/// Same icon-box card style as ExploreScreen's nearby-places panel — places
/// have no photo data in the backend, so a category icon stands in for one.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

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
