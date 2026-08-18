import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

class WatchStreamView extends StatefulWidget {
  const WatchStreamView({super.key});

  @override
  State<WatchStreamView> createState() => _WatchStreamViewState();
}

class _WatchStreamViewState extends State<WatchStreamView> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _chatController = TextEditingController();

  String _title = 'Live Broadcast';
  final int _viewers = 12;
  int _giftsReceived = 50;
  final List<String> _chatMessages = ['Host: Welcome everyone! 👋'];

  final List<Map<String, dynamic>> _giftOptions = [
    {'name': 'Heart', 'emoji': '❤️', 'coins': 5},
    {'name': 'Star', 'emoji': '⭐', 'coins': 10},
    {'name': 'Fire', 'emoji': '🔥', 'coins': 20},
    {'name': 'Diamond', 'emoji': '💎', 'coins': 50},
  ];

  @override
  void initState() {
    super.initState();
    final Map args = Get.arguments ?? {};
    if (args['title'] != null) {
      _title = args['title'];
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendGift(Map<String, dynamic> gift) {
    final myName = _authController.profile.value?.name ?? 'Viewer';
    setState(() {
      _giftsReceived += (gift['coins'] as int);
      _chatMessages.add('$myName sent a ${gift['name']}! ${gift['emoji']}');
    });
    Get.snackbar('Gift Sent ${gift['emoji']}', 'You sent a ${gift['name']} for ${gift['coins']} coins.');
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final myName = _authController.profile.value?.name ?? 'You';
    setState(() {
      _chatMessages.add('$myName: $text');
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1020),
      body: SafeArea(
        child: Column(
          children: [
            // Top Live View Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10.0),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white, size: 14.0),
                      const SizedBox(width: 4.0),
                      Text('$_viewers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        Text('$_giftsReceived', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Stream Video Placeholder
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2540),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64.0),
                      const SizedBox(height: 10.0),
                      Text(
                        _title,
                        style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Gift Options Row
            Container(
              height: 70.0,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _giftOptions.map((g) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _sendGift(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Row(
                          children: [
                            Text(g['emoji'], style: const TextStyle(fontSize: 18.0)),
                            const SizedBox(width: 6.0),
                            Text('${g['coins']}🪙', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12.0)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Chat Messages List
            Container(
              height: 140.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: ListView.builder(
                itemCount: _chatMessages.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      _chatMessages[idx],
                      style: const TextStyle(color: Colors.white, fontSize: 13.0),
                    ),
                  );
                },
              ),
            ),

            // Chat Composer
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
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white, fontSize: 14.0),
                        decoration: const InputDecoration(
                          hintText: 'Say something...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18.0),
                      onPressed: _sendChat,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
