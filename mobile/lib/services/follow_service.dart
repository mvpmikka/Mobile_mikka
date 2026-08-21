import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/friend.dart';

class FollowService {
  FollowService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> follow(String username) async {
    try {
      await _apiClient.dio.post('/users/$username/follow');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> unfollow(String username) async {
    try {
      await _apiClient.dio.delete('/users/$username/follow');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // FollowItem's shape (id/username/fullName/avatarUrl + a since-date) is
  // identical to Friend's, so it's reused here rather than adding a
  // near-duplicate model.
  Future<List<Friend>> listFollowers(
    String username, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/$username/followers',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Friend.fromFollowJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Friend>> listFollowing(
    String username, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/$username/following',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Friend.fromFollowJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
