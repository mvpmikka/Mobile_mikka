import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/privacy_settings.dart';
import '../services/privacy_service.dart';
import 'auth_provider.dart';

final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService(apiClient: ref.watch(apiClientProvider));
});

final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  return ref.watch(privacyServiceProvider).get();
});
