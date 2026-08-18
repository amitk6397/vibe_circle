import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SupportArticleView extends StatelessWidget {
  const SupportArticleView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final title = args['title']?.toString() ?? 'Support Article';
    final body = args['body']?.toString() ?? '';
    final icon = args['icon']?.toString() ?? 'help_outline';

    final iconData = _resolveIcon(icon);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(title, style: AppTextStyles.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(iconData, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              Text(
                body.isNotEmpty ? body : 'This article provides guidance on the topic above. Contact support for more details.',
                style: AppTextStyles.body.copyWith(height: 1.6, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    const iconMap = <String, IconData>{
      'shield-checkmark-outline': Icons.shield_outlined,
      'lock-closed-outline': Icons.lock_outline,
      'eye-off-outline': Icons.visibility_off_outlined,
      'people-outline': Icons.people_outline,
      'chatbubble-outline': Icons.chat_bubble_outline,
      'flag-outline': Icons.flag_outlined,
      'help-circle-outline': Icons.help_outline,
      'information-circle-outline': Icons.info_outline,
      'alert-circle-outline': Icons.warning_amber_outlined,
      'card-outline': Icons.credit_card_outlined,
    };
    return iconMap[iconName] ?? Icons.help_outline;
  }
}
