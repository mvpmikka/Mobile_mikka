import 'place.dart';

/// Mirrors the backend's `SavedPlaceItem` (GET /users/me/saved-places).
class SavedPlaceItem {
  const SavedPlaceItem({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.category,
    required this.savedAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final PlaceCategoryRef category;
  final DateTime savedAt;

  factory SavedPlaceItem.fromJson(Map<String, dynamic> json) {
    return SavedPlaceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      category: PlaceCategoryRef.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  // PlaceDetailScreen only needs list-level fields to render — it fetches
  // rating separately via placeRatingProvider, so this placeholder is never
  // actually displayed.
  Place toPlace() {
    return Place(
      id: id,
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      status: status,
      rating: const PlaceRating(averageRating: 0, reviewCount: 0),
    );
  }
}
