import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/friend.dart';
import '../models/friend_activity.dart';

class FriendshipService {
  FriendshipService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Friend>> listFriends({int page = 1, int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/me/friends',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// One backend call for the whole list — each friend's latest check-in,
  /// distance from the current user, and live online status, instead of
  /// fanning out N+1 requests client-side.
  Future<List<FriendActivity>> listActivity({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/me/friends/activity',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => FriendActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendFriendRequest(String addresseeUserId) async {
    try {
      await _apiClient.dio.post(
        '/friend-requests',
        data: {'addresseeUserId': addresseeUserId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
