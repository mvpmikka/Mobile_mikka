import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/call_service.dart';
import '../services/call_socket_service.dart';
import 'auth_provider.dart';

final callServiceProvider = Provider<CallService>((ref) {
  return CallService(apiClient: ref.watch(apiClientProvider));
});

final callSocketServiceProvider = Provider<CallSocketService>((ref) {
  final service = CallSocketService();
  ref.onDispose(service.dispose);
  return service;
});
