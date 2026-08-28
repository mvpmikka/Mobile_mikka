import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/customer.dart';

class CustomerService {
  CustomerService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CustomerPage> listCustomers(
    String placeId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places/$placeId/customers',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return CustomerPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CustomerDetail> getDetail(String placeId, String phone) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/customers/$phone');
      return CustomerDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> block(String placeId, String phone) async {
    try {
      await _apiClient.dio.post('/places/$placeId/customers/$phone/block');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> unblock(String placeId, String phone) async {
    try {
      await _apiClient.dio.post('/places/$placeId/customers/$phone/unblock');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
