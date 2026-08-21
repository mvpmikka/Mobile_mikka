import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/chat_message.dart';
import '../models/friend_activity.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_activity_provider.dart';
import '../services/call_socket_service.dart';
import '../theme/app_colors.dart';
import 'call_screen.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.otherUserId,
    this.otherAvatarUrl,
  });

  final String conversationId;
  final String title;
  final String? otherUserId;
  final String? otherAvatarUrl;

  @override
  ConsumerState<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Best-effort — a failure here just means the unread badge on the
    // conversations list stays stale, nothing the user needs to see.
    ref.read(chatServiceProvider).markRead(widget.conversationId).catchError((_) {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();
    try {
      await ref
          .read(messageThreadProvider(widget.conversationId).notifier)
          .send(text);
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _startCall(CallKind kind) async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null) return;

    final socket = ref.read(callSocketServiceProvider);
    try {
      final callId = await socket.invite(
        calleeId: otherUserId,
        kind: kind,
        conversationId: widget.conversationId,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callId: callId,
            otherUserId: otherUserId,
            isVideo: kind == CallKind.video,
            isCaller: true,
          ),
        ),
      );
    } on CallBusyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foydalanuvchi band')),
      );
    } on CallFailedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(authControllerProvider).value?.user?.id ?? '';
    final messagesAsync = ref.watch(messageThreadProvider(widget.conversationId));

    ref.listen(messageThreadProvider(widget.conversationId), (previous, next) {
      final grew = (next.value?.length ?? 0) > (previous?.value?.length ?? 0);
      if (grew) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        titleSpacing: 0,
        title: widget.otherUserId == null
            ? Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.darkText(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              )
            : _ThreadHeader(
                title: widget.title,
                avatarUrl: widget.otherAvatarUrl,
                otherUserId: widget.otherUserId!,
              ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
        actions: widget.otherUserId == null
            ? null
            : [
                IconButton(
                  icon: Icon(Icons.call, color: AppColors.darkText(context)),
                  onPressed: () => _startCall(CallKind.audio),
                ),
                IconButton(
                  icon: Icon(
                    Icons.videocam,
                    color: AppColors.darkText(context),
                  ),
                  onPressed: () => _startCall(CallKind.video),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Xabarlarni yuklab bo\'lmadi',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Birinchi xabarni yozing',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients &&
                        _scrollController.offset >=
                            _scrollController.position.maxScrollExtent - 40) {
                      _scrollToBottom();
                    }
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message,
                        isMine: message.sender.id == myUserId,
                      );
                    },
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  // "+" stays a no-op for now (attachments are out of scope — see the
  // redesign plan), same convention as ProfileScreen's not-yet-built menu
  // tiles (empty onTap rather than a half-built handler).
  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _textController,
        builder: (context, value, _) {
          final hasText = value.text.trim().isNotEmpty;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ComposerIconButton(icon: Icons.add, onTap: () {}),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.fieldBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            color: AppColors.darkText(context),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Xabar yozing...',
                            hintStyle: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 14,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      if (!hasText) ...[
                        Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppColors.mutedText(context),
                          size: 21,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.mic_none,
                          color: AppColors.mutedText(context),
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasText) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ThreadHeader extends ConsumerWidget {
  const _ThreadHeader({
    required this.title,
    required this.avatarUrl,
    required this.otherUserId,
  });

  final String title;
  final String? avatarUrl;
  final String otherUserId;

  FriendActivity? _activityFor(List<FriendActivity> items) {
    for (final item in items) {
      if (item.id == otherUserId) return item;
    }
    return null;
  }

  String? _statusLabel(FriendActivity? activity) {
    if (activity == null) return null;
    if (activity.online) return 'Onlayn';
    final place = activity.lastCheckIn?.placeName;
    final distance = activity.distanceLabel;
    if (place != null && distance != null) return '$place • $distance';
    return place;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(friendActivityProvider);
    final activity = activityAsync.maybeWhen(
      data: _activityFor,
      orElse: () => null,
    );
    final status = _statusLabel(activity);

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.person, color: Colors.white, size: 18),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            if (activity?.online == true)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cream(context), width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.darkText(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (status != null)
                Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: activity?.online == true
                        ? const Color(0xFF4CAF50)
                        : AppColors.mutedText(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Icon(icon, color: AppColors.mutedText(context), size: 22),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.orange : AppColors.surface(context);
    final textColor = isMine ? Colors.white : AppColors.darkText(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}
