class PlaceCategoryRef {
  const PlaceCategoryRef({required this.id, required this.name});

  final String id;
  final String name;

  factory PlaceCategoryRef.fromJson(Map<String, dynamic> json) {
    return PlaceCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// Mirrors the backend's `PlaceListItem` (`GET /places`).
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.rating,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final PlaceCategoryRef category;
  final double latitude;
  final double longitude;
  final String status;
  final double? distanceMeters;
  final PlaceRating rating;

  String? get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  factory Place.fromListJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PlaceCategoryRef.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      rating: PlaceRating.fromJson(json['rating'] as Map<String, dynamic>),
    );
  }
}

/// Mirrors the backend's raw `Place` row (`GET /places/:id`) — unlike the
/// list item, this has no joined category name, only the fields the detail
/// view actually adds on top of the list item.
class PlaceDetail {
  const PlaceDetail({this.description, this.address, this.phone, this.website});

  final String? description;
  final String? address;
  final String? phone;
  final String? website;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    return PlaceDetail(
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
    );
  }
}

/// Mirrors the backend's raw `Place` row as returned by `GET /places/mine`
/// — the joined category/rating fields `Place` needs for the public list
/// aren't selected there, so this is a lighter, separate shape.
class BusinessPlace {
  const BusinessPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
  });

  final String id;
  final String name;
  final String? address;
  final String status;

  factory BusinessPlace.fromJson(Map<String, dynamic> json) {
    return BusinessPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      status: json['status'] as String,
    );
  }
}

/// Mirrors the backend's rating summary (`GET /places/:id/rating`).
class PlaceRating {
  const PlaceRating({required this.averageRating, required this.reviewCount});

  final double averageRating;
  final int reviewCount;

  factory PlaceRating.fromJson(Map<String, dynamic> json) {
    return PlaceRating(
      averageRating: (json['averageRating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
    );
  }
}
