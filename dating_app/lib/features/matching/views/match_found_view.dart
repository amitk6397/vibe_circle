import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MatchFoundView extends StatefulWidget {
  const MatchFoundView({super.key});

  @override
  State<MatchFoundView> createState() => _MatchFoundViewState();
}

class _MatchFoundViewState extends State<MatchFoundView> {
  bool _waitingForOther = false;
  bool _accepting = false;
  Timer? _polling;
  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _params = (Get.arguments as Map<String, dynamic>?) ?? {};
    _waitingForOther = _params['alreadyAccepted'] as bool? ?? false;

    // Simulate polling
    if (_waitingForOther) {
      _polling = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        // In real app: poll matchingApi.status() and navigate when accepted
      });
    }
  }

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  String _conversationStarter() {
    final purpose = _params['purpose']?.toString() ?? '';
    if (purpose == 'Learn') return 'What are you learning or curious about right now?';
    if (purpose == 'Advice') return 'What would you like another perspective on?';
    if (purpose == 'Friends') return 'What do you enjoy doing in your free time?';
    return 'How has your day been so far?';
  }

  @override
  Widget build(BuildContext context) {
    final anonymous = _params['anonymous'] as bool? ?? false;
    final personName = _params['personName']?.toString() ?? 'Someone';
    final reasons = (_params['reasons'] as List?)?.cast<String>() ?? [];
    final language = _params['language']?.toString() ?? 'English';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suggested connection', style: AppTextStyles.title),
            Text(
              'You both choose whether to connect',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile hero
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      anonymous ? 'A' : (personName.isNotEmpty ? personName[0].toUpperCase() : '?'),
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    anonymous ? 'Safe listener' : personName,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommended for you · $language · Online now',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Relevance reasons card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHY THIS PERSON IS RELEVANT',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                        ),
                      ),
                  const SizedBox(height: 10),
                  if (reasons.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons.asMap().entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: e.key == 0 ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(e.value, style: AppTextStyles.caption.copyWith(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    anonymous
                        ? 'Profile details stay hidden until you choose otherwise.'
                        : 'This person matches your interests and preferences.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),

            // Conversation starter card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONVERSATION STARTER',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_conversationStarter(), style: AppTextStyles.body),
                ],
              ),
            ),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _waitingForOther || _accepting ? null : () async {
                  setState(() => _accepting = true);
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() { _accepting = false; _waitingForOther = true; });
                },
                icon: _accepting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _waitingForOther ? 'Waiting for the other person...' : 'Accept connection',
                  style: AppTextStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _waitingForOther ? AppColors.muted : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.offAndToNamed('/connect-setup'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Skip safely', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
