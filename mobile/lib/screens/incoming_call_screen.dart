import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../services/call_socket_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.kind,
  });

  final String callId;
  final String callerId;
  final CallKind kind;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _responded = false;
  late final StreamSubscription<CallIdEvent> _endedSub;
  late final StreamSubscription<CallIdEvent> _missedSub;

  @override
  void initState() {
    super.initState();
    final socket = ref.read(callSocketServiceProvider);
    _endedSub = socket.onEnded
        .where((event) => event.callId == widget.callId)
        .listen((_) => _dismiss());
    _missedSub = socket.onMissed
        .where((event) => event.callId == widget.callId)
        .listen((_) => _dismiss());
  }

  @override
  void dispose() {
    _endedSub.cancel();
    _missedSub.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_responded) return;
    _responded = true;
    if (mounted) Navigator.of(context).pop();
  }

  void _accept() {
    if (_responded) return;
    setState(() => _responded = true);
    ref.read(callSocketServiceProvider).accept(widget.callId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: widget.callId,
          otherUserId: widget.callerId,
          isVideo: widget.kind == CallKind.video,
          isCaller: false,
        ),
      ),
    );
  }

  void _reject() {
    if (_responded) return;
    setState(() => _responded = true);
    ref.read(callSocketServiceProvider).reject(widget.callId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final profile = friendsAsync.maybeWhen(
      data: (friends) {
        for (final friend in friends) {
          if (friend.profile.id == widget.callerId) return friend.profile;
        }
        return null;
      },
      orElse: () => null,
    );
    final displayName = profile?.displayName ?? 'Foydalanuvchi';
    final avatarUrl = profile?.avatarUrl;
    final kindLabel = widget.kind == CallKind.video
        ? "Kiruvchi video qo'ng'iroq"
        : "Kiruvchi audio qo'ng'iroq";

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 56,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 24),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kindLabel,
                  style: const TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.call_end,
                      background: Colors.red,
                      label: 'Rad etish',
                      onTap: _reject,
                    ),
                    _ActionButton(
                      icon: widget.kind == CallKind.video
                          ? Icons.videocam
                          : Icons.call,
                      background: Colors.green,
                      label: 'Qabul qilish',
                      onTap: _accept,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.background,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: background,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
