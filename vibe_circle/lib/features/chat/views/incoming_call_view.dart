import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';

class IncomingCallView extends StatefulWidget {
  const IncomingCallView({super.key});

  @override
  State<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<IncomingCallView> {
  final ChatController _chatController = Get.find<ChatController>();

  String _callId = '';
  String _name = '';
  String _personId = '';
  String _callType = 'audio'; // 'audio' | 'video'
  bool _answering = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _callId = args?['callId'] ?? '';
    _name = args?['name'] ?? 'User';
    _personId = args?['personId'] ?? '';
    _callType = args?['callType'] ?? 'audio';
  }

  void _decline() async {
    if (_answering) return;
    setState(() => _answering = true);
    try {
      await _chatController.rejectCall(_callId);
    } catch (_) {}
    Get.back();
  }

  void _accept() async {
    if (_answering) return;
    setState(() => _answering = true);
    try {
      await _chatController.acceptCall(_callId);
      final args = {
        'callId': _callId,
        'name': _name,
        'personId': _personId,
      };
      Get.offNamed(
        _callType == 'video' ? AppRoutes.VIDEO_CALL : AppRoutes.AUDIO_CALL,
        arguments: args,
      );
    } catch (e) {
      setState(() => _answering = false);
      Get.snackbar('Call unavailable', e.toString(),
          backgroundColor: AppColors.danger, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101326),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contact details
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'INCOMING ${_callType.toUpperCase()} CALL',
                      style: const TextStyle(
                        color: Color(0xFFAEB3CA),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    AppAvatar(
                      name: _name,
                      size: 116.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Text(
                      'VibeCircle secure call',
                      style: TextStyle(color: Color(0xFFAEB3CA), fontSize: 14.0),
                    ),
                  ],
                ),
              ),

              // Action buttons Accept/Decline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionBtn(Icons.close, 'Decline', true, _decline),
                  _buildActionBtn(Icons.call, 'Accept', false, _accept),
                ],
              ),
              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, bool danger, VoidCallback onPressed) {
    final Color bgColor = danger ? const Color(0xFFF04464) : const Color(0xFF35B779);
    return GestureDetector(
      onTap: _answering ? null : onPressed,
      child: Column(
        children: [
          Container(
            width: 68.0,
            height: 68.0,
            decoration: BoxDecoration(
              color: _answering ? bgColor.withValues(alpha: 0.55) : bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 28.0),
          ),
          const SizedBox(height: 9.0),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

