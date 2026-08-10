import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../core/api_config.dart';
import '../models/chat_message.dart';

class MessageDeletedEvent {
  const MessageDeletedEvent({required this.conversationId, required this.messageId});

  final String conversationId;
  final String messageId;
}

class ReactionUpdatedEvent {
  const ReactionUpdatedEvent({
    required this.conversationId,
    required this.messageId,
    required this.reactions,
  });

  final String conversationId;
  final String messageId;
  final List<Map<String, dynamic>> reactions;
}

/// Wraps the socket.io connection to the backend's `/chat` namespace
/// (see `ChatGateway`). Push-only: this never sends writes, it only
/// notifies already-connected clients that something changed via REST
/// (`ChatService`) — matching the backend's own "REST is the source of
/// truth" design.
class ChatSocketService {
  socket_io.Socket? _socket;

  final _newMessageController = StreamController<ChatMessage>.broadcast();
  final _messageDeletedController = StreamController<MessageDeletedEvent>.broadcast();
  final _reactionUpdatedController = StreamController<ReactionUpdatedEvent>.broadcast();

  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;
  Stream<MessageDeletedEvent> get onMessageDeleted => _messageDeletedController.stream;
  Stream<ReactionUpdatedEvent> get onReactionUpdated => _reactionUpdatedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    disconnect();

    final socket = socket_io.io(
      '${ApiConfig.baseUrl}/chat',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    socket.onConnectError((_) {});
    socket.onError((_) {});

    socket.on('new_message', (data) {
      _newMessageController.add(ChatMessage.fromJson(data as Map<String, dynamic>));
    });
    socket.on('message_deleted', (data) {
      final map = data as Map<String, dynamic>;
      _messageDeletedController.add(
        MessageDeletedEvent(
          conversationId: map['conversationId'] as String,
          messageId: map['messageId'] as String,
        ),
      );
    });
    socket.on('reaction_updated', (data) {
      final map = data as Map<String, dynamic>;
      _reactionUpdatedController.add(
        ReactionUpdatedEvent(
          conversationId: map['conversationId'] as String,
          messageId: map['messageId'] as String,
          reactions: (map['reactions'] as List<dynamic>).cast<Map<String, dynamic>>(),
        ),
      );
    });

    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _messageDeletedController.close();
    _reactionUpdatedController.close();
  }
}
