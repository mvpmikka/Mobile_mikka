import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/booking.dart';

class BookingService {
  BookingService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<BookingPage> listBookings(
    String placeId, {
    int page = 1,
    int limit = 20,
    String? search,
    BookingStatus? status,
    String? date,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places/$placeId/bookings',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status.apiValue,
          if (date != null && date.isNotEmpty) 'date': date,
        },
      );
      return BookingPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BookingStats> getStats(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/bookings/stats');
      return BookingStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createBooking(
    String placeId, {
    required String customerName,
    String? customerPhone,
    required DateTime bookingTime,
    required int guests,
    String? tableLabel,
    String? note,
  }) async {
    try {
      await _apiClient.dio.post(
        '/places/$placeId/bookings',
        data: {
          'customerName': customerName,
          if (customerPhone != null && customerPhone.isNotEmpty) 'customerPhone': customerPhone,
          'bookingTime': bookingTime.toIso8601String(),
          'guests': guests,
          if (tableLabel != null && tableLabel.isNotEmpty) 'tableLabel': tableLabel,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateStatus(String placeId, String bookingId, BookingStatus status) async {
    try {
      await _apiClient.dio.patch(
        '/places/$placeId/bookings/$bookingId/status',
        data: {'status': status.apiValue},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteBooking(String placeId, String bookingId) async {
    try {
      await _apiClient.dio.delete('/places/$placeId/bookings/$bookingId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
