import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_circle/core/constants/app_colors.dart';
import 'package:vibe_circle/core/constants/app_text_styles.dart';
import 'package:vibe_circle/core/widgets/app_button.dart';
import 'package:vibe_circle/core/widgets/app_field.dart';
import 'package:vibe_circle/core/widgets/app_header.dart';
import 'package:vibe_circle/core/widgets/app_pill.dart';
import 'package:vibe_circle/core/widgets/app_screen.dart';
import '../controllers/go_live_controller.dart';

class GoLiveView extends GetView<GoLiveController> {
  const GoLiveView({super.key});

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final GoLiveController c = Get.isRegistered<GoLiveController>()
        ? Get.find<GoLiveController>()
        : Get.put(GoLiveController());

    return Obx(() {
      return PopScope(
        canPop: !c.isLive.value,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && c.isLive.value) c.endStream();
        },
        child: c.isLive.value ? _buildLiveScreen(c) : _buildSetupScreen(c),
      );
    });
  }

  Widget _buildSetupScreen(GoLiveController c) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Go Live',
            subtitle: 'Start broadcasting to your followers',
          ),
          const SizedBox(height: 20.0),
          AppField(
            controller: c.titleCtrl,
            label: 'Stream title',
            placeholder: 'What are you streaming today?',
          ),
          const SizedBox(height: 16.0),
          const Text('Category', style: AppTextStyles.label),
          const SizedBox(height: 8.0),
          Obx(
            () => Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: c.categories.map((cat) {
                return AppPill(
                  label: cat,
                  selected: c.category.value == cat,
                  onPressed: () => c.category.value = cat,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32.0),
          Obx(
            () => AppButton(
              title: c.starting.value ? 'Starting...' : '🔴 Go Live',
              onPressed: c.starting.value ? () {} : c.startStream,
              loading: c.starting.value,
              disabled: c.starting.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScreen(GoLiveController c) {
    final engine = c.engine;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Local camera preview (full screen)
          Positioned.fill(
            child: engine != null && c.agoraReady.value && c.cameraEnabled.value
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
          ),

          // Top stats bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _liveChip(),
                      const SizedBox(width: 10.0),
                      _statChip(Icons.remove_red_eye, '${c.viewers.value}'),
                      const Spacer(),
                      _statChip(
                        Icons.card_giftcard,
                        '${c.totalGifts.value}🪙',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8.0),
                      _statChip(Icons.timer, _formatDuration(c.duration.value)),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: c.endStream,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Text(
                            'End',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Chat messages overlay (bottom-left)
          Positioned(
            left: 12.0,
            bottom: 80.0,
            right: 80.0,
            height: 160.0,
            child: ListView.builder(
              controller: c.chatScroll,
              itemCount: c.chatMessages.length,
              itemBuilder: (context, idx) {
                final msg = c.chatMessages[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${msg['sender']}: ',
                            style: TextStyle(
                              color: msg['isGift'] == true ? Colors.amber : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                          TextSpan(
                            text: msg['text'],
                            style: const TextStyle(color: Colors.white, fontSize: 12.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Stream controls (right side vertical floating buttons)
          Positioned(
            right: 12.0,
            bottom: 80.0,
            child: Column(
              children: [
                _actionButton(
                  icon: c.cameraEnabled.value ? Icons.videocam : Icons.videocam_off,
                  onTap: c.toggleCamera,
                ),
                const SizedBox(height: 10.0),
                _actionButton(
                  icon: c.muted.value ? Icons.mic_off : Icons.mic,
                  onTap: c.toggleMute,
                ),
                const SizedBox(height: 10.0),
                _actionButton(
                  icon: Icons.flip_camera_ios,
                  onTap: c.switchCamera,
                ),
              ],
            ),
          ),

          // Chat composer at bottom
          Positioned(
            left: 12.0,
            right: 12.0,
            bottom: 16.0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TextField(
                      controller: c.chatCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14.0),
                      decoration: const InputDecoration(
                        hintText: 'Say something as host...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => c.sendChatMessage(val),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18.0),
                    onPressed: () => c.sendChatMessage(c.chatCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.0, color: color ?? Colors.white70),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.0,
        height: 42.0,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20.0),
      ),
    );
  }
}
