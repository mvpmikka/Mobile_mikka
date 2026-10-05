import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/directions_service.dart';

final directionsServiceProvider = Provider<DirectionsService>((ref) => DirectionsService());
