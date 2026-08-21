import 'package:dio/dio.dart';

/// A backend error translated into a message safe to show in the UI.
///
/// Nest's default exception filter responds with `{statusCode, message,
/// error}`, where `message` is either a string or (for validation errors) a
/// list of strings — both are handled here.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        final detail = firstError is Map ? firstError['message'] : null;
        if (detail != null) {
          return ApiException(detail.toString(), statusCode: error.response?.statusCode);
        }
      }
      if (data['message'] != null) {
        final message = data['message'];
        final text = message is List && message.isNotEmpty
            ? message.first.toString()
            : message.toString();
        return ApiException(text, statusCode: error.response?.statusCode);
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Server javob bermayapti. Qayta urinib ko\'ring.');
      case DioExceptionType.connectionError:
        return const ApiException('Serverga ulanib bo\'lmadi. Internetni tekshiring.');
      default:
        return const ApiException('Nimadir xato ketdi. Qayta urinib ko\'ring.');
    }
  }

  @override
  String toString() => message;
}
