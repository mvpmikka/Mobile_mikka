import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/place.dart';

class PlaceService {
  PlaceService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Place>> listNearby({
    required double lat,
    required double lng,
    int radiusMeters = 3000,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusMeters': radiusMeters,
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Place.fromListJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<BusinessPlace>> listMine() async {
    try {
      final response = await _apiClient.dio.get('/places/mine');
      return (response.data as List<dynamic>)
          .map((e) => BusinessPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PlaceDetail> getDetail(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId');
      return PlaceDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PlaceRating> getRating(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/rating');
      return PlaceRating.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> checkIn(
    String placeId, {
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiClient.dio.post(
        '/places/$placeId/check-ins',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
