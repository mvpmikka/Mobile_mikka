import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/privacy_settings.dart';

class PrivacyService {
  PrivacyService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PrivacySettings> get() async {
    try {
      final response = await _apiClient.dio.get('/users/me/privacy-settings');
      return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PrivacySettings> update(CheckInVisibility value) async {
    try {
      final response = await _apiClient.dio.patch(
        '/users/me/privacy-settings',
        data: {'checkInVisibility': checkInVisibilityToJson(value)},
      );
      return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
