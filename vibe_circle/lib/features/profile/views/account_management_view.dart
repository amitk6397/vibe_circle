import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class AccountManagementView extends GetView<ProfileController> {
  const AccountManagementView({super.key});

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
            const Text('Account management', style: AppTextStyles.title),
            Text(
              'Private account email',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MenuRow(
              icon: Icons.download_outlined,
              title: 'Download my data',
              onPress: () async {
                await controller.exportAccountData();
                _showInfoDialog(
                  'Data export ready',
                  'Your account export was generated securely. Sharing/download UI can now use this response.',
                );
              },
            ),
            _MenuRow(
              icon: Icons.phone_android_outlined,
              title: 'Log out all devices',
              onPress: () async {
                await controller.logoutAllDevices();
                _showInfoDialog(
                  'Sessions revoked',
                  'All sessions have been signed out.',
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Get.find<AuthController>().logout();
                  Get.offAllNamed(AppRoutes.LOGIN);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Log out', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showDeleteDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Delete account', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () => Get.back(),
    );
  }

  void _showDeleteDialog() {
    Get.defaultDialog(
      title: 'Delete account?',
      middleText: 'This permanently removes your profile and starts the required retention/deletion process.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        await controller.deleteAccountPermanently();
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPress;
  const _MenuRow({required this.icon, required this.title, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTextStyles.title),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
