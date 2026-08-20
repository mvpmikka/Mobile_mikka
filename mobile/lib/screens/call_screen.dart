import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/call_provider.dart';
import '../services/call_socket_service.dart';
import '../services/webrtc_call_controller.dart';

enum _CallPhase { connecting, ringing, connected, ended }

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    required this.callId,
    required this.otherUserId,
    required this.isVideo,
    required this.isCaller,
  });

  final String callId;
  final String otherUserId;
  final bool isVideo;
  final bool isCaller;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  WebRTCCallController? _controller;
  _CallPhase _phase = _CallPhase.connecting;
  String? _statusOverride;

  StreamSubscription<CallIdEvent>? _acceptedSub;
  StreamSubscription<CallIdEvent>? _rejectedSub;
  StreamSubscription<CallIdEvent>? _endedSub;
  StreamSubscription<CallIdEvent>? _missedSub;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final micStatus = await Permission.microphone.request();
    final cameraStatus = widget.isVideo
        ? await Permission.camera.request()
        : PermissionStatus.granted;
    if (!micStatus.isGranted || (widget.isVideo && !cameraStatus.isGranted)) {
      _endCall(reason: 'Ruxsat berilmadi');
      return;
    }
    if (!mounted) return;

    final socket = ref.read(callSocketServiceProvider);
    final controller = WebRTCCallController(
      callId: widget.callId,
      isVideo: widget.isVideo,
      callSocketService: socket,
    );
    _controller = controller;

    _acceptedSub = socket.onAccepted
        .where((event) => event.callId == widget.callId)
        .listen((_) async {
          if (!mounted) return;
          setState(() => _phase = _CallPhase.connected);
          await controller.createAndSendOffer();
        });
    _rejectedSub = socket.onRejected
        .where((event) => event.callId == widget.callId)
        .listen((_) => _endCall(reason: 'Rad etildi'));
    _endedSub = socket.onEnded
        .where((event) => event.callId == widget.callId)
        .listen((_) => _endCall());
    _missedSub = socket.onMissed
        .where((event) => event.callId == widget.callId)
        .listen((_) => _endCall(reason: 'Javob berilmadi'));

    try {
      final iceServers = await ref.read(callServiceProvider).getIceServers();
      await controller.initialize(iceServers);
    } catch (_) {
      _endCall(reason: 'Ulanishda xatolik');
      return;
    }

    if (!mounted) return;
    setState(() {
      _phase = widget.isCaller ? _CallPhase.ringing : _CallPhase.connected;
    });
  }

  void _endCall({String? reason}) {
    if (_phase == _CallPhase.ended) return;
    setState(() {
      _phase = _CallPhase.ended;
      _statusOverride = reason;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _hangup() {
    if (_phase == _CallPhase.ended) return;
    ref.read(callSocketServiceProvider).hangup(widget.callId);
    _endCall();
  }

  @override
  void dispose() {
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _missedSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_statusOverride != null) return _statusOverride!;
    switch (_phase) {
      case _CallPhase.connecting:
        return 'Ulanmoqda...';
      case _CallPhase.ringing:
        return 'Chaqirilmoqda...';
      case _CallPhase.connected:
        return "Qo'ng'iroqda";
      case _CallPhase.ended:
        return "Qo'ng'iroq tugadi";
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hangup();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: (widget.isVideo && controller != null)
                    ? RTCVideoView(
                        controller.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const ColoredBox(
                        color: Color(0xFF1A1A1A),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white24,
                            size: 96,
                          ),
                        ),
                      ),
              ),
              if (widget.isVideo && controller != null)
                Positioned(
                  right: 16,
                  top: 16,
                  width: 100,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RTCVideoView(
                      controller.localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _Controls(controller: controller, onHangup: _hangup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.controller, required this.onHangup});

  final WebRTCCallController? controller;
  final VoidCallback onHangup;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleButton(
          icon: controller?.isMuted == true ? Icons.mic_off : Icons.mic,
          background: Colors.white24,
          onTap: controller == null
              ? null
              : () => setState(() => controller.toggleMute()),
        ),
        _CircleButton(
          icon: Icons.call_end,
          background: Colors.red,
          onTap: widget.onHangup,
        ),
        if (controller != null && controller.isVideo)
          _CircleButton(
            icon: Icons.cameraswitch,
            background: Colors.white24,
            onTap: () => controller.switchCamera(),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: background,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
