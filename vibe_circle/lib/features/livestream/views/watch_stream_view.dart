import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_circle/core/constants/app_colors.dart';
import '../controllers/watch_stream_controller.dart';

const _giftOptions = [
  {'name': 'Heart', 'emoji': '❤️', 'coins': 5},
  {'name': 'Star', 'emoji': '⭐', 'coins': 10},
  {'name': 'Fire', 'emoji': '🔥', 'coins': 20},
  {'name': 'Diamond', 'emoji': '💎', 'coins': 50},
  {'name': 'Crown', 'emoji': '👑', 'coins': 100},
  {'name': 'Rocket', 'emoji': '🚀', 'coins': 200},
];

class WatchStreamView extends GetView<WatchStreamController> {
  const WatchStreamView({super.key});

  @override
  Widget build(BuildContext context) {
    final WatchStreamController c = Get.isRegistered<WatchStreamController>()
        ? Get.find<WatchStreamController>()
        : Get.put(WatchStreamController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1020),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    _liveChip(),
                    const SizedBox(width: 10.0),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye, color: Colors.white, size: 14.0),
                        const SizedBox(width: 4.0),
                        Text(
                          '${c.viewers.value}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.white, size: 14.0),
                          const SizedBox(width: 4.0),
                          Text(
                            '${c.giftsReceived.value}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Remote Video (host's stream)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2540),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: c.engine != null && c.remoteUid.value != null
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: c.engine!,
                            canvas: VideoCanvas(uid: c.remoteUid.value!),
                            connection: RtcConnection(channelId: c.channelName.value),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white54),
                              const SizedBox(height: 14.0),
                              Text(
                                c.title.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              const Text(
                                'Waiting for host…',
                                style: TextStyle(color: Colors.white54, fontSize: 13.0),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Gift options row
              Container(
                height: 60.0,
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _giftOptions.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: c.sendingGift.value ? null : () => c.sendGift(g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          child: Row(
                            children: [
                              Text(g['emoji'] as String, style: const TextStyle(fontSize: 16.0)),
                              const SizedBox(width: 6.0),
                              Text(
                                '${g['coins']}🪙',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Chat messages
              Container(
                height: 130.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ListView.builder(
                  controller: c.chatScroll,
                  itemCount: c.chatMessages.length,
                  itemBuilder: (context, idx) {
                    final msg = c.chatMessages[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
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
                    );
                  },
                ),
              ),

              // Chat composer
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: TextField(
                          controller: c.chatCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14.0),
                          decoration: const InputDecoration(
                            hintText: 'Say something...',
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
      }),
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
}
