import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dating_app/core/constants/app_colors.dart';
import 'package:dating_app/core/services/agora_call_service.dart';
import 'package:dating_app/core/widgets/app_avatar.dart';
import 'package:dating_app/features/chat/controllers/chat_controller.dart';
import 'package:dating_app/features/profile/controllers/profile_controller.dart';
import 'package:dating_app/routes/app_routes.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final ChatController _chatController = Get.find<ChatController>();
  final ProfileController _profileController = Get.find<ProfileController>();

  late final AgoraCallService _agora;

  String _callId = '';
  String _name = '';
  String _personId = '';
  bool _ended = false;
  int _reservedMinutes = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _callId = args?['callId'] ?? '';
    _name = args?['name'] ?? 'User';
    _personId = args?['personId'] ?? '';

    _agora = AgoraCallService();
    _agora.addListener(_onAgoraStateChanged);
    _agora.initializeForCall(_callId, isVideo: true);
    _loadCallConfig();
  }

  void _onAgoraStateChanged() {
    if (!mounted) return;
    setState(() {});
    if (_agora.status == AgoraCallStatus.ended && !_ended) {
      _handleCallEnded();
    }
  }

  void _loadCallConfig() async {
    try {
      final config = await _chatController.loadCallConfig();
      if (mounted) {
        setState(() => _reservedMinutes = config['durationOptions']?[0] ?? 10);
      }
    } catch (_) {
      if (mounted) setState(() => _reservedMinutes = 10);
    }
  }

  @override
  void dispose() {
    _agora.removeListener(_onAgoraStateChanged);
    _agora.dispose();
    if (!_ended) _chatController.endCall(_callId);
    super.dispose();
  }

  void _handleCallEnded() {
    _ended = true;
    _endCall();
  }

  void _endCall() async {
    _ended = true;
    try {
      final res = await _chatController.endCall(_callId);
      final num charged = res['chargedCoins'] ?? 0;
      if (charged > 0) {
        Get.offNamed(
          AppRoutes.SESSION_RATING,
          arguments: {
            'sessionId': _callId,
            'userId': _personId,
            'sessionType': 'call',
          },
        );
      } else {
        Get.back();
      }
    } catch (_) {
      Get.back();
    }
  }

  void _extendSession() async {
    try {
      final config = await _chatController.loadCallConfig();
      final List durationOptions = config['durationOptions'] ?? [5, 10, 15];
      Get.defaultDialog(
        title: 'Extend session',
        middleText: 'Additional coins are locked immediately.',
        textCancel: 'Cancel',
        actions: durationOptions.map((item) {
          final int minutes = int.parse(item.toString());
          return TextButton(
            onPressed: () async {
              Get.back();
              try {
                final session = await _chatController.extendCall(_callId, minutes);
                setState(() {
                  _reservedMinutes = session['reservedMinutes'] ?? (_reservedMinutes + minutes);
                });
                Get.snackbar('Extended', 'Session extended successfully.');
              } catch (e) {
                Get.snackbar('Could not extend', e.toString());
              }
            },
            child: Text(
              '+$minutes min',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      );
    } catch (e) {
      Get.snackbar('Could not load options', e.toString());
    }
  }

  void _reportCall() {
    Get.defaultDialog(
      title: 'Report call',
      middleText: 'Submit report for inappropriate behavior?',
      textCancel: 'Cancel',
      textConfirm: 'Submit',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await _profileController.reportUser('call', _callId, 'Inappropriate behaviour');
          Get.snackbar('Report submitted', 'Our safety moderators will review it.');
        } catch (e) {
          Get.snackbar('Report failed', e.toString());
        }
      },
    );
  }

  String _formatDuration(int totalSecs) {
    final int mins = totalSecs ~/ 60;
    final int secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get _statusText {
    if (_agora.error != null) return _agora.error!;
    switch (_agora.status) {
      case AgoraCallStatus.connected:
        return _formatDuration(_agora.seconds);
      case AgoraCallStatus.reconnecting:
        return 'Reconnecting securely…';
      case AgoraCallStatus.ended:
        return 'Call ended';
      default:
        return 'Connecting securely…';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine = _agora.engine;

    return Scaffold(
      backgroundColor: const Color(0xFF101326),
      body: Stack(
        children: [
          // ── Remote Video (full-screen) ─────────────────────────────────────
          Positioned.fill(
            child: engine != null && _agora.remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: engine,
                      canvas: VideoCanvas(uid: _agora.remoteUid!),
                      connection: RtcConnection(channelId: _agora.channelId),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1B203E),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppAvatar(name: _name, size: 100.0),
                        const SizedBox(height: 14.0),
                        Text(
                          _name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _statusText,
                          style: const TextStyle(color: Colors.white70, fontSize: 13.0),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Local Camera Preview (top-right pip) ────────────────────────────
          if (_agora.cameraEnabled && engine != null)
            Positioned(
              top: 52.0,
              right: 20.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: SizedBox(
                  width: 110.0,
                  height: 160.0,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // ── Remaining minutes badge ──────────────────────────────────────────
          if (_reservedMinutes > 0)
            Positioned(
              top: 130.0,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${(_reservedMinutes - (_agora.seconds ~/ 60)).clamp(0, _reservedMinutes)} min remaining',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),

          // ── Overlay Controls ─────────────────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top info bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'VIDEO CALL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom controls
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControl(
                                _agora.muted ? Icons.mic_off : Icons.mic,
                                _agora.muted,
                                _agora.toggleMute,
                              ),
                              _buildControl(
                                _agora.speakerOn ? Icons.volume_up : Icons.volume_down,
                                _agora.speakerOn,
                                _agora.toggleSpeaker,
                              ),
                              _buildControl(
                                _agora.cameraEnabled ? Icons.videocam : Icons.videocam_off,
                                !_agora.cameraEnabled,
                                _agora.toggleCamera,
                              ),
                              _buildControl(Icons.flip_camera_ios, false, _agora.switchCamera),
                              _buildControl(Icons.timer_outlined, false, _extendSession),
                              _buildControl(Icons.flag_outlined, false, _reportCall),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // End call
                        GestureDetector(
                          onTap: _endCall,
                          child: Container(
                            width: 68.0,
                            height: 68.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF04464),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.call_end, color: Colors.white, size: 28.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControl(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: active ? const Color(0xFF101326) : Colors.white, size: 20.0),
      ),
    );
  }
}
