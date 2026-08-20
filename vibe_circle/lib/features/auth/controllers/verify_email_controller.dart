import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class VerifyEmailController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final codeController = TextEditingController();

  final RxString email = ''.obs;
  final RxString error = ''.obs;
  final RxString snackbar = ''.obs;
  final RxInt cooldown = 0.obs;
  final RxBool sending = false.obs;
  final RxBool verifying = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    email.value = args?['email'] ?? 'your email';
    sendOtp();
  }

  @override
  void onClose() {
    codeController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void _showSnackbar(String msg) {
    snackbar.value = msg;
    Timer(const Duration(seconds: 10), () {
      if (snackbar.value == msg) snackbar.value = '';
    });
  }

  Future<void> sendOtp() async {
    sending.value = true;
    error.value = '';
    try {
      final res = await _authRepo.requestVerification();
      final otp = res['otp'] ?? '';
      _showSnackbar('Your verification OTP is $otp. It expires in 10 minutes.');
      cooldown.value = 30;
      _startCooldownTimer();
    } catch (e) {
      error.value = e.toString();
    } finally {
      sending.value = false;
    }
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (cooldown.value <= 0) {
        t.cancel();
      } else {
        cooldown.value--;
      }
    });
  }

  Future<void> verify() async {
    verifying.value = true;
    error.value = '';
    try {
      await _authRepo.verifyEmail(codeController.text.trim());
      Get.offAllNamed(AppRoutes.BASIC_PROFILE);
    } catch (e) {
      error.value = e.toString();
    } finally {
      verifying.value = false;
    }
  }
}
