import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/friend.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';
import '../services/friendship_service.dart';
import 'auth_provider.dart';

final friendshipServiceProvider = Provider<FriendshipService>((ref) {
  return FriendshipService(apiClient: ref.watch(apiClientProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(apiClient: ref.watch(apiClientProvider));
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  return ref.watch(friendshipServiceProvider).listFriends();
});

final conversationsProvider =
    AsyncNotifierProvider<ConversationsController, List<ConversationListItem>>(
      ConversationsController.new,
    );

class ConversationsController extends AsyncNotifier<List<ConversationListItem>> {
  @override
  Future<List<ConversationListItem>> build() async {
    final socket = ref.watch(chatSocketServiceProvider);
    // A new message anywhere should bump that conversation to the top of
    // the list and refresh its preview/unread count — simplest correct
    // way to do that is to just re-fetch, since the list is small (a
    // user's own conversations, not a global feed).
    final subscription = socket.onNewMessage.listen((_) => refresh());
    ref.onDispose(subscription.cancel);

    return ref.watch(chatServiceProvider).listConversations();
  }

  Future<void> refresh() async {
    final chatService = ref.read(chatServiceProvider);
    state = await AsyncValue.guard(() => chatService.listConversations());
  }
}

final messageThreadProvider =
    AsyncNotifierProvider.family<MessageThreadController, List<ChatMessage>, String>(
      MessageThreadController.new,
    );

class MessageThreadController extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String conversationId) async {
    final socket = ref.watch(chatSocketServiceProvider);

    final newMessageSub = socket.onNewMessage
        .where((message) => message.conversationId == conversationId)
        .listen((message) {
          final current = state.value ?? [];
          if (current.any((m) => m.id == message.id)) return;
          state = AsyncData([...current, message]);
        });
    ref.onDispose(newMessageSub.cancel);

    final deletedSub = socket.onMessageDeleted
        .where((event) => event.conversationId == conversationId)
        .listen((event) {
          final current = state.value ?? [];
          state = AsyncData(current.where((m) => m.id != event.messageId).toList());
        });
    ref.onDispose(deletedSub.cancel);

    final chatService = ref.read(chatServiceProvider);
    final messages = await chatService.listMessages(conversationId);
    // Backend returns newest-first (matches conversation-list pagination
    // convention) — the thread UI wants oldest-first so it can append new
    // messages at the end.
    return messages.reversed.toList();
  }

  Future<void> send(String text) async {
    final chatService = ref.read(chatServiceProvider);
    final message = await chatService.sendMessage(arg, text);
    final current = state.value ?? [];
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([...current, message]);
  }
}
