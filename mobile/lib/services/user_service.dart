import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user_search_result.dart';

class UserService {
  UserService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<UserSearchResult>> search(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/search',
        queryParameters: {'q': query},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
