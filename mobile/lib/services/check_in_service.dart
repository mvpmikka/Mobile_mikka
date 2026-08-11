import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/check_in.dart';

class CheckInService {
  CheckInService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The user's most recent check-in, or null if they have none, or their
  /// privacy settings hide check-ins from the current viewer.
  Future<PublicCheckIn?> getLatestForUser(String username) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/$username/check-ins',
        queryParameters: {'page': 1, 'limit': 1},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      if (items.isEmpty) return null;
      return PublicCheckIn.fromJson(items.first as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return null;
      throw ApiException.fromDio(e);
    }
  }
}
