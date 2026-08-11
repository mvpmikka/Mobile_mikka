import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/notification_item.dart';

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<NotificationItem> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

class NotificationService {
  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<NotificationPage> list({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationPage(
        items: items,
        total: data['total'] as int,
        page: data['page'] as int,
        limit: data['limit'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
