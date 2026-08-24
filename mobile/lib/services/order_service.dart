import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/order.dart';

class OrderService {
  OrderService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<OrderPage> listOrders(
    String placeId, {
    int page = 1,
    int limit = 20,
    String? search,
    OrderStatus? status,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places/$placeId/orders',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status.apiValue,
        },
      );
      return OrderPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderStats> getStats(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/orders/stats');
      return OrderStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createOrder(
    String placeId, {
    required String customerName,
    String? customerPhone,
    required List<OrderItem> items,
  }) async {
    try {
      await _apiClient.dio.post(
        '/places/$placeId/orders',
        data: {
          'customerName': customerName,
          if (customerPhone != null && customerPhone.isNotEmpty) 'customerPhone': customerPhone,
          'items': [
            for (final item in items)
              {'name': item.name, 'quantity': item.quantity, 'unitPrice': item.unitPrice},
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateStatus(String placeId, String orderId, OrderStatus status) async {
    try {
      await _apiClient.dio.patch(
        '/places/$placeId/orders/$orderId/status',
        data: {'status': status.apiValue},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteOrder(String placeId, String orderId) async {
    try {
      await _apiClient.dio.delete('/places/$placeId/orders/$orderId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
