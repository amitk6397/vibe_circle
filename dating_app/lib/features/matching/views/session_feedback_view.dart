import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SessionFeedbackView extends StatefulWidget {
  const SessionFeedbackView({super.key});

  @override
  State<SessionFeedbackView> createState() => _SessionFeedbackViewState();
}

class _SessionFeedbackViewState extends State<SessionFeedbackView> {
  int _rating = 0;
  List<String> _tags = [];
  bool _submitting = false;

  static const List<String> _positiveTags = [
    'Helpful',
    'Respectful',
    'Easy to talk to',
    'Good listener',
    'Shared interests',
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags = _tags.where((t) => t != tag).toList();
      } else {
        _tags = [..._tags, tag];
      }
    });
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _submitting = false);
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Thank you', style: AppTextStyles.title),
        content: const Text('Your private feedback was saved.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.offAllNamed('/main');
            },
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSafetyActions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Safety actions', style: AppTextStyles.title),
        content: const Text('Choose what you need.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Block user', style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Report session', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('How was your conversation?', style: AppTextStyles.title),
            Text(
              'Feedback is private and improves suggestions.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        size: 36,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Text('What went well?', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positiveTags.map((tag) {
                final selected = _tags.contains(tag);
                return GestureDetector(
                  onTap: () => _toggleTag(tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.body.copyWith(
                        color: selected ? Colors.white : AppColors.muted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating == 0 || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit feedback', style: AppTextStyles.buttonText),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSafetyActions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Block or report', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
