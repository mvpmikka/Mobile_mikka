import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../services/directions_service.dart';

final directionsServiceProvider = Provider<DirectionsService>(
  (ref) => DirectionsService(apiClient: ref.watch(apiClientProvider)),
);
