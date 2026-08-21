import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/badge.dart';

class BadgeService {
  BadgeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Public endpoint, no guard on the backend — badges are a showcase, same
  // reasoning as GET /users/:username/posts' PUBLIC-visibility rows.
  Future<List<UserBadge>> listForUser(String username) async {
    try {
      final response = await _apiClient.dio.get('/users/$username/badges');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
