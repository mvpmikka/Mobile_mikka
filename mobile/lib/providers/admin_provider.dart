import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_user.dart';
import '../models/place.dart';
import '../services/admin_service.dart';
import 'auth_provider.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(apiClient: ref.watch(apiClientProvider));
});

final adminPlacesProvider =
    FutureProvider.autoDispose<List<Place>>((ref) async {
  return ref.watch(adminServiceProvider).listPlaces();
});

final adminCategoriesProvider =
    FutureProvider.autoDispose<List<PlaceCategoryRef>>((ref) async {
  return ref.watch(adminServiceProvider).listCategories();
});

final adminUsersProvider =
    FutureProvider.autoDispose<AdminUserPage>((ref) async {
  return ref.watch(adminServiceProvider).listUsers();
});
