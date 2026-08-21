class FriendLastCheckIn {
  const FriendLastCheckIn({required this.placeName, required this.createdAt});

  final String placeName;
  final DateTime createdAt;

  factory FriendLastCheckIn.fromJson(Map<String, dynamic> json) {
    return FriendLastCheckIn(
      placeName: json['placeName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Mirrors the backend's `FriendActivityItem`
/// (`GET /users/me/friends/activity`) — no live GPS, both `lastCheckIn`
/// and `distanceMeters` come from CheckIn history, `online` from presence
/// (an open chat socket), not a current position.
class FriendActivity {
  const FriendActivity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.lastCheckIn,
    required this.distanceMeters,
    required this.online,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final FriendLastCheckIn? lastCheckIn;
  final double? distanceMeters;
  final bool online;

  String get displayName => fullName ?? username ?? 'Foydalanuvchi';

  String? get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastCheckIn: json['lastCheckIn'] == null
          ? null
          : FriendLastCheckIn.fromJson(
              json['lastCheckIn'] as Map<String, dynamic>,
            ),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      online: json['online'] as bool,
    );
  }
}
