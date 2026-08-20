import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_service.dart';
import 'call_socket_service.dart';

/// Owns the `RTCPeerConnection` lifecycle for a single call: local/remote
/// media capture, the offer/answer/ICE-candidate exchange (relayed
/// through [CallSocketService]), and mute/camera controls. One instance
/// per call — [CallScreen]/[IncomingCallScreen] create it, use it, and
/// dispose it when the call ends.
class WebRTCCallController {
  WebRTCCallController({
    required this.callId,
    required this.isVideo,
    required CallSocketService callSocketService,
  }) : _callSocketService = callSocketService {
    _offerSub = _callSocketService.onOffer
        .where((event) => event.callId == callId)
        .listen((event) => _handleRemoteOffer(event.sdp!));
    _answerSub = _callSocketService.onAnswer
        .where((event) => event.callId == callId)
        .listen((event) => _handleRemoteAnswer(event.sdp!));
    _iceSub = _callSocketService.onIceCandidate
        .where((event) => event.callId == callId)
        .listen((event) => _handleRemoteIceCandidate(event.candidate!));
  }

  final String callId;
  final bool isVideo;
  final CallSocketService _callSocketService;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  late final StreamSubscription<CallSignalEvent> _offerSub;
  late final StreamSubscription<CallSignalEvent> _answerSub;
  late final StreamSubscription<CallSignalEvent> _iceSub;

  // Offer/answer/ICE candidates can arrive over the socket before
  // initialize() finishes standing up the peer connection (getUserMedia +
  // createPeerConnection both await) — signaling handlers wait on this
  // instead of assuming _peerConnection is already set.
  final _ready = Completer<void>();
  bool _remoteDescriptionSet = false;
  final _pendingCandidates = <RTCIceCandidate>[];

  bool _muted = false;
  bool _videoEnabled = true;

  bool get isMuted => _muted;
  bool get isVideoEnabled => _videoEnabled;

  Future<void> initialize(List<IceServer> iceServers) async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });
    localRenderer.srcObject = _localStream;

    final config = {
      'iceServers': iceServers
          .map(
            (server) => {
              'urls': server.urls,
              if (server.username != null) 'username': server.username,
              if (server.credential != null) 'credential': server.credential,
            },
          )
          .toList(),
    };
    final pc = await createPeerConnection(config);
    _peerConnection = pc;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _callSocketService.sendIceCandidate(callId, candidate.toMap());
    };

    _ready.complete();
  }

  /// Caller side: builds and sends the SDP offer.
  Future<void> createAndSendOffer() async {
    final pc = _peerConnection!;
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    _callSocketService.sendOffer(callId, {
      'type': offer.type,
      'sdp': offer.sdp,
    });
  }

  Future<void> _handleRemoteOffer(Map<String, dynamic> sdp) async {
    await _ready.future;
    final pc = _peerConnection!;
    await pc.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
    );
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    _callSocketService.sendAnswer(callId, {
      'type': answer.type,
      'sdp': answer.sdp,
    });
  }

  Future<void> _handleRemoteAnswer(Map<String, dynamic> sdp) async {
    await _ready.future;
    final pc = _peerConnection!;
    await pc.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
    );
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
  }

  Future<void> _handleRemoteIceCandidate(Map<String, dynamic> candidate) async {
    await _ready.future;
    final iceCandidate = RTCIceCandidate(
      candidate['candidate'] as String?,
      candidate['sdpMid'] as String?,
      candidate['sdpMLineIndex'] as int?,
    );
    // Candidates routinely arrive before the offer/answer round-trip sets
    // the remote description — WebRTC requires that to happen first, so
    // early candidates queue here instead of being added immediately.
    if (!_remoteDescriptionSet) {
      _pendingCandidates.add(iceCandidate);
      return;
    }
    await _peerConnection!.addCandidate(iceCandidate);
  }

  Future<void> _flushPendingCandidates() async {
    final pc = _peerConnection!;
    for (final candidate in _pendingCandidates) {
      await pc.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  void toggleMute() {
    _muted = !_muted;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = !_muted;
    }
  }

  void toggleVideo() {
    if (!isVideo) return;
    _videoEnabled = !_videoEnabled;
    for (final track in _localStream?.getVideoTracks() ?? const []) {
      track.enabled = _videoEnabled;
    }
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isNotEmpty) await Helper.switchCamera(videoTracks.first);
  }

  Future<void> dispose() async {
    await _offerSub.cancel();
    await _answerSub.cancel();
    await _iceSub.cancel();
    await _localStream?.dispose();
    await _peerConnection?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
