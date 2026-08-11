class CheckInPlace {
  const CheckInPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  factory CheckInPlace.fromJson(Map<String, dynamic> json) {
    return CheckInPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Mirrors the backend's `PublicCheckInItem` (GET /users/:username/check-ins).
/// Only exposes the place's public location, never the user's own raw GPS.
class PublicCheckIn {
  const PublicCheckIn({
    required this.id,
    required this.place,
    required this.createdAt,
  });

  final String id;
  final CheckInPlace place;
  final DateTime createdAt;

  factory PublicCheckIn.fromJson(Map<String, dynamic> json) {
    return PublicCheckIn(
      id: json['id'] as String,
      place: CheckInPlace.fromJson(json['place'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
