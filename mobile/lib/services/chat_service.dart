import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ChatService {
  ChatService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ConversationListItem>> listConversations({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/conversations',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => ConversationListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Starts (or, if one already exists, resumes) a private conversation
  /// with [friendUserId] — the backend get-or-creates PRIVATE conversations,
  /// so this is safe to call every time the user taps "Message".
  Future<ConversationDetail> openPrivateConversation(String friendUserId) async {
    try {
      final response = await _apiClient.dio.post(
        '/conversations',
        data: {
          'type': 'PRIVATE',
          'participantIds': [friendUserId],
        },
      );
      return ConversationDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/conversations/$conversationId/messages',
        data: {'text': text},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _apiClient.dio.patch('/conversations/$conversationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
