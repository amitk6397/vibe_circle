import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SessionFeedbackView extends StatelessWidget {
  const SessionFeedbackView({super.key});

  static const List<String> _positiveTags = [
    'Helpful',
    'Respectful',
    'Easy to talk to',
    'Good listener',
    'Shared interests',
  ];

  @override
  Widget build(BuildContext context) {
    final RxInt rating = 0.obs;
    final RxList<String> tags = <String>[].obs;
    final RxBool submitting = false.obs;

    void toggleTag(String tag) {
      if (tags.contains(tag)) {
        tags.remove(tag);
      } else {
        tags.add(tag);
      }
    }

    void showSuccess() {
      Get.dialog(
        AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Thank you', style: AppTextStyles.title),
          content: Text('Your private feedback was saved.', style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed('/main');
              },
              child: const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    void submit() async {
      if (rating.value == 0) return;
      submitting.value = true;
      await Future.delayed(const Duration(seconds: 1));
      submitting.value = false;
      showSuccess();
    }

    void showSafetyActions() {
      Get.dialog(
        AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Safety actions', style: AppTextStyles.title),
          content: Text('Choose what you need.', style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.snackbar('User Blocked', 'This user has been blocked.');
              },
              child: const Text('Block user', style: TextStyle(color: AppColors.danger)),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.snackbar('Report Submitted', 'Our safety team will review this report.');
              },
              child: const Text('Report session', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
    }

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
            Text('How was your conversation?', style: AppTextStyles.h2),
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
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => rating.value = star,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        star <= rating.value ? Icons.star : Icons.star_border,
                        size: 36,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  );
                }),
              )),
            ),

            Text('What went well?', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positiveTags.map((tag) {
                final selected = tags.contains(tag);
                return GestureDetector(
                  onTap: () => toggleTag(tag),
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
            )),
            const SizedBox(height: 32),

            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: rating.value == 0 || submitting.value ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: submitting.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: showSafetyActions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Block or report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
