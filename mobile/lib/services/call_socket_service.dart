import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../core/api_config.dart';

enum CallKind { audio, video }

CallKind _callKindFromString(String value) =>
    value == 'VIDEO' ? CallKind.video : CallKind.audio;

String _callKindToString(CallKind kind) =>
    kind == CallKind.video ? 'VIDEO' : 'AUDIO';

class IncomingCallEvent {
  const IncomingCallEvent({
    required this.callId,
    required this.callerId,
    required this.kind,
    this.conversationId,
  });

  final String callId;
  final String callerId;
  final CallKind kind;
  final String? conversationId;
}

class CallIdEvent {
  const CallIdEvent(this.callId);

  final String callId;
}

class CallSignalEvent {
  const CallSignalEvent({required this.callId, this.sdp, this.candidate});

  final String callId;
  final Map<String, dynamic>? sdp;
  final Map<String, dynamic>? candidate;
}

class CallBusyException implements Exception {
  const CallBusyException();
}

class CallFailedException implements Exception {
  const CallFailedException(this.message);

  final String message;
}

/// Wraps the socket.io connection to the backend's `/call` namespace (see
/// `CallGateway`). Unlike `ChatSocketService`, this IS the transport for
/// every part of a call's lifecycle (invite/accept/reject/hangup and the
/// WebRTC offer/answer/ICE-candidate exchange) — there's no REST
/// equivalent for any of it, so writes go out over this socket too, not
/// just pushed notifications.
class CallSocketService {
  socket_io.Socket? _socket;

  final _incomingCallController =
      StreamController<IncomingCallEvent>.broadcast();
  final _acceptedController = StreamController<CallIdEvent>.broadcast();
  final _rejectedController = StreamController<CallIdEvent>.broadcast();
  final _endedController = StreamController<CallIdEvent>.broadcast();
  final _missedController = StreamController<CallIdEvent>.broadcast();
  final _offerController = StreamController<CallSignalEvent>.broadcast();
  final _answerController = StreamController<CallSignalEvent>.broadcast();
  final _iceCandidateController =
      StreamController<CallSignalEvent>.broadcast();

  Stream<IncomingCallEvent> get onIncomingCall =>
      _incomingCallController.stream;
  Stream<CallIdEvent> get onAccepted => _acceptedController.stream;
  Stream<CallIdEvent> get onRejected => _rejectedController.stream;
  Stream<CallIdEvent> get onEnded => _endedController.stream;
  Stream<CallIdEvent> get onMissed => _missedController.stream;
  Stream<CallSignalEvent> get onOffer => _offerController.stream;
  Stream<CallSignalEvent> get onAnswer => _answerController.stream;
  Stream<CallSignalEvent> get onIceCandidate => _iceCandidateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    disconnect();

    final socket = socket_io.io(
      '${ApiConfig.baseUrl}/call',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    socket.onConnectError((_) {});
    socket.onError((_) {});

    socket.on('call:incoming', (data) {
      final map = data as Map<String, dynamic>;
      _incomingCallController.add(
        IncomingCallEvent(
          callId: map['callId'] as String,
          callerId: map['callerId'] as String,
          kind: _callKindFromString(map['type'] as String),
          conversationId: map['conversationId'] as String?,
        ),
      );
    });
    socket.on(
      'call:accepted',
      (data) => _acceptedController.add(_toCallIdEvent(data)),
    );
    socket.on(
      'call:rejected',
      (data) => _rejectedController.add(_toCallIdEvent(data)),
    );
    socket.on(
      'call:ended',
      (data) => _endedController.add(_toCallIdEvent(data)),
    );
    socket.on(
      'call:missed',
      (data) => _missedController.add(_toCallIdEvent(data)),
    );
    socket.on('call:offer', (data) => _offerController.add(_toSignalEvent(data)));
    socket.on(
      'call:answer',
      (data) => _answerController.add(_toSignalEvent(data)),
    );
    socket.on(
      'call:ice-candidate',
      (data) => _iceCandidateController.add(_toSignalEvent(data)),
    );

    socket.connect();
    _socket = socket;
  }

  CallIdEvent _toCallIdEvent(dynamic data) {
    final map = data as Map<String, dynamic>;
    return CallIdEvent(map['callId'] as String);
  }

  CallSignalEvent _toSignalEvent(dynamic data) {
    final map = data as Map<String, dynamic>;
    return CallSignalEvent(
      callId: map['callId'] as String,
      sdp: (map['sdp'] as Map?)?.cast<String, dynamic>(),
      candidate: (map['candidate'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Starts a call and waits for the gateway's ack — throws
  /// [CallBusyException] if the callee is already on another call, or
  /// [CallFailedException] for anything else (e.g. not friends).
  Future<String> invite({
    required String calleeId,
    required CallKind kind,
    String? conversationId,
  }) async {
    final socket = _socket;
    if (socket == null) throw const CallFailedException('Not connected');
    final result = await socket.emitWithAckAsync('call:invite', {
      'calleeId': calleeId,
      'type': _callKindToString(kind),
      if (conversationId != null) 'conversationId': conversationId,
    });
    final map = result as Map<String, dynamic>;
    if (map['error'] == 'busy') throw const CallBusyException();
    if (map['error'] != null) {
      throw CallFailedException(map['message'] as String? ?? 'Call failed');
    }
    return map['callId'] as String;
  }

  void accept(String callId) => _socket?.emit('call:accept', {'callId': callId});

  void reject(String callId) => _socket?.emit('call:reject', {'callId': callId});

  void hangup(String callId) => _socket?.emit('call:hangup', {'callId': callId});

  void sendOffer(String callId, Map<String, dynamic> sdp) =>
      _socket?.emit('call:offer', {'callId': callId, 'sdp': sdp});

  void sendAnswer(String callId, Map<String, dynamic> sdp) =>
      _socket?.emit('call:answer', {'callId': callId, 'sdp': sdp});

  void sendIceCandidate(String callId, Map<String, dynamic> candidate) => _socket
      ?.emit('call:ice-candidate', {'callId': callId, 'candidate': candidate});

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _incomingCallController.close();
    _acceptedController.close();
    _rejectedController.close();
    _endedController.close();
    _missedController.close();
    _offerController.close();
    _answerController.close();
    _iceCandidateController.close();
  }
}
