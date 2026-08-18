import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../../auth/controllers/auth_controller.dart';

class GoLiveView extends StatefulWidget {
  const GoLiveView({super.key});

  @override
  State<GoLiveView> createState() => _GoLiveViewState();
}

class _GoLiveViewState extends State<GoLiveView> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _titleController = TextEditingController();

  String _category = 'General';
  bool _isLive = false;
  bool _starting = false;
  int _viewers = 0;
  final List<String> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  final List<String> _categories = ['General', 'Gaming', 'Music', 'Fitness', 'Talk', 'Art', 'Education'];

  @override
  void dispose() {
    _titleController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _startStream() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Input Required', 'Please provide a title for your live stream.');
      return;
    }

    setState(() => _starting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _starting = false;
      _isLive = true;
      _viewers = 1;
      _chatMessages.add('System: 🎉 Stream is live!');
    });
  }

  void _endStream() {
    setState(() => _isLive = false);
    Get.back();
    Get.snackbar('Stream Ended', 'Your live broadcast has ended.');
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
    if (_isLive) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1020),
        body: SafeArea(
          child: Column(
            children: [
              // Top Live Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 10.0),
                          SizedBox(width: 4.0),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye, color: Colors.white, size: 16.0),
                        const SizedBox(width: 4.0),
                        Text('$_viewers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    AppButton(
                      title: 'End',
                      compact: true,
                      tone: AppButtonTone.danger,
                      onPressed: _endStream,
                    ),
                  ],
                ),
              ),

              // Camera Placeholder Preview Box
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
                        const Icon(Icons.videocam, color: Colors.white70, size: 64.0),
                        const SizedBox(height: 10.0),
                        Text(
                          _titleController.text,
                          style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chat Messages List
              Container(
                height: 160.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

              // Chat Composer Row
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

    return AppScreen(
      header: AppHeader(
        title: 'Go Live',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Banner
            Container(
              height: 180.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B3F9A), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio, color: Colors.white70, size: 52.0),
                  SizedBox(height: 10.0),
                  Text('Broadcast to Community', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

             AppField(
               label: 'Stream Title *',
               placeholder: 'What are you streaming today?',
               controller: _titleController,
             ),
            const SizedBox(height: 16.0),

            const Text('Category', style: AppTextStyles.h2),
            const SizedBox(height: 8.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AppPill(
                      label: c,
                      selected: _category == c,
                      onPressed: () => setState(() => _category = c),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20.0),

            // Coin Earn info card
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💰 Earn from your stream', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2.0),
                        const Text('Viewers send virtual gifts. You earn coins.', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            AppButton(
              title: 'Start Live Stream',
              loading: _starting,
              onPressed: _startStream,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
