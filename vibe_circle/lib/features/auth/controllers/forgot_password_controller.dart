import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import '../../../core/constants/app_colors.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final emailController = TextEditingController();
  final RxBool sending = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    sending.value = true;
    
    try {
      await _authRepo.forgotPassword(email.toLowerCase());
      Get.defaultDialog(
        title: 'Check your inbox',
        middleText: 'If this email is registered, a reset link has been sent.',
        backgroundColor: AppColors.surface,
        titleStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        middleTextStyle: const TextStyle(color: AppColors.text),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back(); // close dialog
          Get.back(); // navigate back to login
        },
      );
    } catch (e) {
      Get.defaultDialog(
        title: 'Could not send link',
        middleText: e.toString(),
        backgroundColor: AppColors.surface,
        titleStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        middleTextStyle: const TextStyle(color: AppColors.text),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } finally {
      sending.value = false;
    }
  }
}
