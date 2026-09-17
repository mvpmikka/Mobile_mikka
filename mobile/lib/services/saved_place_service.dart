import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/saved_place.dart';

class SavedPlaceService {
  SavedPlaceService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<SavedPlaceItem>> list({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/me/saved-places',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => SavedPlaceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> save(String placeId) async {
    try {
      await _apiClient.dio.post('/places/$placeId/saved-places');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> unsave(String placeId) async {
    try {
      await _apiClient.dio.delete('/places/$placeId/saved-places');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
