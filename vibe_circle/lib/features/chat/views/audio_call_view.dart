import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../controllers/chat_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class AudioCallView extends StatefulWidget {
  const AudioCallView({super.key});

  @override
  State<AudioCallView> createState() => _AudioCallViewState();
}

class _AudioCallViewState extends State<AudioCallView> {
  final ChatController _chatController = Get.find<ChatController>();
  final ProfileController _profileController = Get.find<ProfileController>();

  String _callId = '';
  String _name = '';
  String _personId = '';

  bool _muted = false;
  bool _speaker = false;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const Text(
                    'AUDIO CALL',
                    style: TextStyle(color: Color(0xFFAEB3CA), fontSize: 11.0, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Main User details
              Column(
                children: [
                  AppAvatar(name: _name, size: 112.0),
                  const SizedBox(height: 16.0),
                  Text(_name, style: const TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.w900)),
                ],
              ),

              // Call actions grid controls
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControl(
                        _muted ? Icons.mic_off : Icons.mic,
                        _muted ? 'Unmute' : 'Mute',
                        _muted,
                        () => setState(() => _muted = !_muted),
                      ),
                      _buildControl(
                        _speaker ? Icons.volume_up : Icons.volume_down,
                        'Speaker',
                        _speaker,
                        () => setState(() => _speaker = !_speaker),
                      ),
                      _buildControl(
                        Icons.timer_outlined,
                        'Extend',
                        false,
                        _extendSession,
                      ),
                      _buildControl(
                        Icons.flag_outlined,
                        'Report',
                        false,
                        _reportCall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40.0),

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
    );
  }

  Widget _buildControl(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54.0,
            height: 54.0,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: active ? const Color(0xFF101326) : Colors.white, size: 22.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFAEB3CA), fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

