import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../controllers/chat_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final ChatController _chatController = Get.find<ChatController>();
  final ProfileController _profileController = Get.find<ProfileController>();

  String _callId = '';
  String _name = '';
  String _personId = '';

  bool _muted = false;
  bool _speaker = true;
  bool _videoEnabled = true;
  bool _frontCamera = true;
  int _seconds = 0;
  Timer? _timer;
  bool _ended = false;
  int _reservedMinutes = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _callId = args?['callId'] ?? '';
    _name = args?['name'] ?? 'User';
    _personId = args?['personId'] ?? '';

    _loadCallConfig();
    _startTimer();
  }

  void _loadCallConfig() async {
    try {
      final config = await _chatController.loadCallConfig();
      setState(() {
        _reservedMinutes = config['durationOptions']?[0] ?? 10;
      });
    } catch (_) {
      setState(() {
        _reservedMinutes = 10;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_ended) {
      _chatController.endCall(_callId);
    }
    super.dispose();
  }

  void _endCall() async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
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
            child: Text('+$minutes min', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      );
    } catch (e) {
      Get.snackbar('Could not load options', e.toString());
    }
  }

  void _reportCall() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101326),
      body: Stack(
        children: [
          // Remote Participant Video View Mock Canvas
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1B203E),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppAvatar(name: _name, size: 100.0),
                  const SizedBox(height: 14.0),
                  Text(
                    _name,
                    style: const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  const Text('Video stream connected…', style: TextStyle(color: Colors.white70, fontSize: 13.0)),
                ],
              ),
            ),
          ),

          // Local Video Camera Preview Overlay (top right)
          if (_videoEnabled)
            Positioned(
              top: 48.0,
              right: 20.0,
              child: Container(
                width: 110.0,
                height: 160.0,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Colors.white70, size: 28.0),
                    SizedBox(height: 4.0),
                    Text('You (Self)', style: TextStyle(color: Colors.white70, fontSize: 10.0)),
                  ],
                ),
              ),
            ),

          // Safe Area controls and text details overlay
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Details Info
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'VIDEO CALL',
                            style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                          Text(
                            _formatDuration(_seconds),
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Controls Box at bottom
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
                                _muted ? Icons.mic_off : Icons.mic,
                                _muted,
                                () => setState(() => _muted = !_muted),
                              ),
                              _buildControl(
                                _speaker ? Icons.volume_up : Icons.volume_down,
                                _speaker,
                                () => setState(() => _speaker = !_speaker),
                              ),
                              _buildControl(
                                _videoEnabled ? Icons.videocam : Icons.videocam_off,
                                !_videoEnabled,
                                () => setState(() => _videoEnabled = !_videoEnabled),
                              ),
                              _buildControl(
                                Icons.flip_camera_ios,
                                false,
                                () => setState(() => _frontCamera = !_frontCamera),
                              ),
                              _buildControl(
                                Icons.timer_outlined,
                                false,
                                _extendSession,
                              ),
                              _buildControl(
                                Icons.flag_outlined,
                                false,
                                _reportCall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // End call button
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
