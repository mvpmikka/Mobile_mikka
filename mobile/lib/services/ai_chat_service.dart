import 'package:dio/dio.dart';

import '../core/ai_config.dart';
import '../core/api_exception.dart';
import '../models/ai_chat.dart';

/// Talks to the AI_Id restaurant-recommendation chatbot — a separate Flask
/// service, not the main NestJS backend, so it gets its own [Dio] instance
/// (no auth token, no refresh-on-401 wiring).
class AiChatService {
  AiChatService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  final Dio _dio;

  Future<AiChatResult> sendMessage(String message) async {
    try {
      final response = await _dio.post('/api/chat', data: {'message': message});
      return AiChatResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
