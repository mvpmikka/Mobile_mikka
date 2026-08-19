import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'message_thread_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(authControllerProvider).value?.user?.id ?? '';
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
      ),
      body: SafeArea(
        child: conversationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
          error: (error, _) => Center(
            child: Text(
              'Suhbatlarni yuklab bo\'lmadi',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return Center(
                child: Text(
                  'Hozircha suhbatlar yo\'q.\nDo\'stlar ekranidan xabar yozishni boshlang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 14),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: conversations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _ConversationTile(
                    conversation: conversation,
                    myUserId: myUserId,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.myUserId});

  final ConversationListItem conversation;
  final String myUserId;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = conversation.isPrivate
        ? conversation.otherParticipant(myUserId)?.avatarUrl
        : null;
    final name = conversation.displayName(myUserId);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MessageThreadScreen(
              conversationId: conversation.id,
              title: name,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person, color: Colors.white, size: 26),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conversation.lastMessage?.summary ?? 'Hali xabar yo\'q',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
