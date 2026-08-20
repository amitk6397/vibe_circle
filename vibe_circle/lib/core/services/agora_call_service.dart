import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibe_circle/features/chat/repositories/call_repository.dart';

/// Connection states mirroring the React useAgoraCall hook states.
enum AgoraCallStatus {
  initializing,
  connecting,
  connected,
  reconnecting,
  ended,
}

/// Reusable Agora RTC wrapper for 1-to-1 audio/video calls.
/// Mirrors React Native's `useAgoraCall.ts` hook behaviour.
class AgoraCallService extends ChangeNotifier {
  final CallRepository _callRepo;

  AgoraCallService({CallRepository? callRepo})
    : _callRepo = callRepo ?? CallRepository();

  RtcEngine? _engine;
  String _channelId = '';
  bool _active = false;
  Timer? _pollTimer;
  Timer? _secondsTimer;

  // ── Observable state ──────────────────────────────────────────────────────
  AgoraCallStatus status = AgoraCallStatus.initializing;
  int? remoteUid;
  bool muted = false;
  bool speakerOn = false;
  bool cameraEnabled = false;
  int seconds = 0;
  String? error;

  RtcEngine? get engine => _engine;
  String get channelId => _channelId;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Initialize the Agora engine and join the call channel.
  /// [callId]   — backend call ID (used to fetch token).
  /// [isVideo]  — true for video call, false for audio.
  Future<void> initializeForCall(String callId, {required bool isVideo}) async {
    _active = true;
    cameraEnabled = isVideo;
    speakerOn = isVideo;

    try {
      await _requestPermissions(isVideo);

      // Fetch token from backend  (same as React callApi.token())
      final rtc = await _callRepo.getToken(callId);
      if (!_active) return;

      final String appId = rtc['appId'] as String? ?? '';
      final String token = rtc['token'] as String? ?? '';
      final String channel = rtc['channel'] as String? ?? '';
      final String userAccount = rtc['userAccount'] as String? ?? '';
      _channelId = channel;

      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(RtcEngineContext(appId: appId));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!_active) return;
            status = AgoraCallStatus.connecting;
            notifyListeners();
            // Notify backend that we joined
            _callRepo.joinCall(callId).catchError((_) => <String, dynamic>{});
          },
          onUserJoined: (connection, uid, elapsed) {
            if (!_active) return;
            remoteUid = uid;
            status = AgoraCallStatus.connected;
            _startSecondsTimer();
            notifyListeners();
          },
          onUserOffline: (connection, uid, reason) {
            if (!_active) return;
            remoteUid = null;
            status = AgoraCallStatus.ended;
            notifyListeners();
          },
          onConnectionStateChanged: (connection, state, reason) {
            if (!_active) return;
            if (state == ConnectionStateType.connectionStateReconnecting) {
              status = AgoraCallStatus.reconnecting;
              notifyListeners();
            } else if (state == ConnectionStateType.connectionStateFailed) {
              error = 'The call connection failed. Please try again.';
              status = AgoraCallStatus.ended;
              notifyListeners();
            }
          },
          onTokenPrivilegeWillExpire: (connection, token) {
            _renewToken(engine, callId);
          },
          onRequestToken: (connection) {
            _renewToken(engine, callId);
          },
          onError: (err, msg) {
            if (!_active) return;
            error = msg.isNotEmpty ? msg : 'Agora error ${err.index}';
            notifyListeners();
          },
        ),
      );

      await engine.enableAudio();
      await engine.setEnableSpeakerphone(speakerOn);

      if (isVideo) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.disableVideo();
      }

      status = AgoraCallStatus.connecting;
      notifyListeners();

      await engine.joinChannelWithUserAccount(
        token: token,
        channelId: channel,
        userAccount: userAccount,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideo,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideo,
        ),
      );

      // Poll call status every 3s to detect remote end/reject (same as React hook)
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final data = await _callRepo.getCall(callId);
          final s = data['status'] as String? ?? '';
          if (_active && ['rejected', 'ended', 'missed'].contains(s)) {
            error = s == 'rejected'
                ? 'The call was declined.'
                : 'The call ended.';
            status = AgoraCallStatus.ended;
            notifyListeners();
            _pollTimer?.cancel();
          }
        } catch (_) {}
      });
    } catch (e) {
      if (!_active) return;
      error = e is Exception ? e.toString() : 'Could not start the call.';
      status = AgoraCallStatus.ended;
      notifyListeners();
    }
  }

  // ── Controls (mirror React toggleMute / toggleSpeaker etc.) ───────────────

  Future<void> toggleMute() async {
    muted = !muted;
    await _engine?.muteLocalAudioStream(muted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await _engine?.setEnableSpeakerphone(speakerOn);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    cameraEnabled = !cameraEnabled;
    await _engine?.muteLocalVideoStream(!cameraEnabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _active = false;
    _pollTimer?.cancel();
    _secondsTimer?.cancel();
    final engine = _engine;
    if (engine != null) {
      await engine.stopPreview();
      await engine.leaveChannel();
      await engine.release();
      _engine = null;
    }
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _startSecondsTimer() {
    _secondsTimer?.cancel();
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (status == AgoraCallStatus.connected) {
        seconds++;
        notifyListeners();
      }
    });
  }

  Future<void> _renewToken(RtcEngine engine, String callId) async {
    try {
      final rtc = await _callRepo.getToken(callId);
      await engine.renewToken(rtc['token'] as String? ?? '');
    } catch (_) {
      error = 'Could not renew the secure call token.';
      notifyListeners();
    }
  }

  static Future<void> _requestPermissions(bool isVideo) async {
    final List<Permission> perms = [Permission.microphone];
    if (isVideo) perms.add(Permission.camera);
    final statuses = await perms.request();
    if (statuses.values.any((s) => !s.isGranted)) {
      throw Exception(
        'Microphone and camera permissions are required for calls.',
      );
    }
  }
}
