import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/admin_user.dart';
import '../models/place.dart';

class AdminService {
  AdminService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Place>> listPlaces({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/places',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Place.fromListJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createPlace({
    required String name,
    required String categoryId,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
  }) async {
    try {
      await _apiClient.dio.post(
        '/places',
        data: {
          'name': name,
          'categoryId': categoryId,
          if (description != null && description.isNotEmpty) 'description': description,
          if (address != null && address.isNotEmpty) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (website != null && website.isNotEmpty) 'website': website,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updatePlaceStatus(String placeId, String status) async {
    try {
      await _apiClient.dio.patch('/places/$placeId', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePlace(String placeId) async {
    try {
      await _apiClient.dio.delete('/places/$placeId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PlaceCategoryRef>> listCategories() async {
    try {
      final response = await _apiClient.dio.get('/place-categories');
      return (response.data as List<dynamic>)
          .map((e) => PlaceCategoryRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createCategory(String name) async {
    try {
      await _apiClient.dio.post('/place-categories', data: {'name': name});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _apiClient.dio.delete('/place-categories/$categoryId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminUserPage> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/admin/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return AdminUserPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _apiClient.dio.post('/admin/users/$userId/ban');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _apiClient.dio.delete('/admin/users/$userId/ban');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
