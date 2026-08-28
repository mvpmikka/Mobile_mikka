import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/review.dart';

class ReviewService {
  ReviewService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<UserReview>> getForUser(
    String username, {
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/$username/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => UserReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PlaceReviewPage> listByPlace(
    String placeId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places/$placeId/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PlaceReviewPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> replyToReview(String placeId, String reviewId, String reply) async {
    try {
      await _apiClient.dio.patch(
        '/places/$placeId/reviews/$reviewId/reply',
        data: {'reply': reply},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
