enum CheckInVisibility { public, friends, private }

CheckInVisibility _checkInVisibilityFromJson(String raw) {
  switch (raw) {
    case 'PUBLIC':
      return CheckInVisibility.public;
    case 'PRIVATE':
      return CheckInVisibility.private;
    default:
      return CheckInVisibility.friends;
  }
}

String checkInVisibilityToJson(CheckInVisibility value) {
  switch (value) {
    case CheckInVisibility.public:
      return 'PUBLIC';
    case CheckInVisibility.friends:
      return 'FRIENDS';
    case CheckInVisibility.private:
      return 'PRIVATE';
  }
}

/// Mirrors the backend's `PrivacySettingsView` (GET /users/me/privacy-settings).
class PrivacySettings {
  const PrivacySettings({required this.checkInVisibility});

  final CheckInVisibility checkInVisibility;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      checkInVisibility: _checkInVisibilityFromJson(
        json['checkInVisibility'] as String,
      ),
    );
  }
}
