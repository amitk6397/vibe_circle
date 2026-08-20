import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/controllers/app_controller.dart';
import '../../../routes/app_routes.dart';

class SettingsSupportView extends StatefulWidget {
  const SettingsSupportView({super.key});

  @override
  State<SettingsSupportView> createState() => _SettingsSupportViewState();
}

class _SettingsSupportViewState extends State<SettingsSupportView> {
  final AppController _appController = Get.find<AppController>();
  bool _pushNotifications = true;

  final List<Map<String, dynamic>> _articles = [
    {
      'id': 'art_1',
      'title': 'How paid chats and coin sessions work',
      'icon': Icons.help_outline,
      'body': 'Paid chats connect users with creators directly. Coins are deducted per minute.',
    },
    {
      'id': 'art_2',
      'title': 'Safety and community guidelines',
      'icon': Icons.shield_outlined,
      'body': 'VibeCircle is built on mutual respect and privacy. Keep communications safe.',
    },
    {
      'id': 'art_3',
      'title': 'Refunding and cancellation policies',
      'icon': Icons.description_outlined,
      'body': 'In case of technical issues during call sessions, contact support for review.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Settings & support',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dark Theme Toggle
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark theme', style: TextStyle(color: AppColors.text, fontSize: 14.5, fontWeight: FontWeight.bold)),
                  Obx(() => Switch(
                    value: _appController.darkMode.value,
                    onChanged: (val) => _appController.setDarkMode(val),
                    activeThumbColor: AppColors.primary,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 10.0),

            // Push Notifications Toggle
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Push notifications', style: TextStyle(color: AppColors.text, fontSize: 14.5, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            const Text('Help & Support Articles', style: AppTextStyles.h2),
            const SizedBox(height: 10.0),

            ..._articles.map((art) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: AppCard(
                  onPressed: () {
                    Get.toNamed(AppRoutes.SUPPORT_ARTICLE, arguments: art);
                  },
                  child: Row(
                    children: [
                      Icon(art['icon'] as IconData, color: AppColors.primary, size: 22.0),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          art['title'],
                          style: const TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted, size: 20.0),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24.0),

            const Text(
              'VibeCircle 1.0 · Talk. Connect. Learn. Belong.',
              style: TextStyle(color: AppColors.muted, fontSize: 12.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
